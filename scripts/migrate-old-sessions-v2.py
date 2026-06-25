#!/usr/bin/env python3
"""Migrate old session messages to session_message table.
Uses seq = event_sequence + 100000 to avoid conflicts with future events.
Idempotent: safe to run multiple times.
"""

import sqlite3
import json
import uuid
import sys

DB = "/home/snow/.local/share/opencode/opencode.db"

def gen_content_id(prefix="c"):
    return f"{prefix}_{uuid.uuid4().hex[:24]}"

def migrate():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # Find sessions needing user/assistant entries in session_message
    cur.execute("""
        SELECT s.id, s.version, s.title,
               COUNT(DISTINCT m.id) as msg_count,
               COALESCE(es.seq, 0) as event_seq
        FROM session s
        JOIN message m ON m.session_id = s.id
        LEFT JOIN event_sequence es ON s.id = es.aggregate_id
        GROUP BY s.id
        HAVING (
            SELECT COUNT(*) FROM session_message sm 
            WHERE sm.session_id = s.id AND sm.type IN ('user', 'assistant')
        ) = 0
        ORDER BY s.time_created
    """)
    sessions = cur.fetchall()
    print(f"Found {len(sessions)} sessions needing migration")

    # Also handle sessions that have control entries but no user/assistant
    cur.execute("""
        SELECT s.id, s.version, s.title,
               COUNT(DISTINCT m.id) as msg_count,
               COALESCE(es.seq, 0) as event_seq,
               (SELECT MAX(sm.seq) FROM session_message sm WHERE sm.session_id = s.id) as max_sm_seq
        FROM session s
        JOIN message m ON m.session_id = s.id
        JOIN event_sequence es ON s.id = es.aggregate_id
        GROUP BY s.id
        HAVING (
            SELECT COUNT(*) FROM session_message sm 
            WHERE sm.session_id = s.id AND sm.type IN ('user', 'assistant')
        ) = 0
        AND (
            SELECT COUNT(*) FROM session_message sm 
            WHERE sm.session_id = s.id
        ) > 0
        ORDER BY s.time_created
    """)
    partial_sessions = cur.fetchall()
    print(f"Found {len(partial_sessions)} sessions with partial session_message entries")

    total_inserted = 0

    for sess in sessions:
        sid = sess["id"]
        version = sess["version"]
        title = sess["title"]
        n_msgs = sess["msg_count"]
        event_seq = sess["event_seq"]

        # Use seq starting point far above event_sequence
        base_seq = event_seq + 100000 if event_seq > 0 else 10000
        seq = base_seq

        # Read all messages ordered by time_created
        cur.execute("""
            SELECT id, data, time_created
            FROM message
            WHERE session_id = ?
            ORDER BY time_created ASC
        """, (sid,))
        messages = cur.fetchall()

        # Determine initial agent and model from first user message
        initial_agent = "build"
        initial_model = {"id": "deepseek-v4-flash-free", "providerID": "opencode"}
        for msg in messages:
            try:
                data = json.loads(msg["data"])
                if data.get("agent"):
                    initial_agent = data["agent"]
                if data.get("modelID"):
                    initial_model["id"] = data["modelID"]
                if data.get("providerID"):
                    initial_model["providerID"] = data["providerID"]
                if data.get("model") and isinstance(data["model"], dict):
                    m = data["model"]
                    initial_model = {
                        "id": m.get("modelID") or m.get("id", initial_model["id"]),
                        "providerID": m.get("providerID", initial_model["providerID"])
                    }
                break
            except (json.JSONDecodeError, KeyError):
                continue

        # Insert agent-switched at start
        now = messages[0]["time_created"] if messages else 1780000000000
        cur.execute(
            "INSERT OR IGNORE INTO session_message (id, session_id, type, seq, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (gen_content_id("msg"), sid, "agent-switched", seq, now, now,
             json.dumps({"time": {"created": now}, "agent": initial_agent}))
        )
        if cur.rowcount > 0:
            total_inserted += 1
        seq += 1

        # Insert model-switched
        cur.execute(
            "INSERT OR IGNORE INTO session_message (id, session_id, type, seq, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (gen_content_id("msg"), sid, "model-switched", seq, now, now,
             json.dumps({"time": {"created": now}, "model": initial_model}))
        )
        if cur.rowcount > 0:
            total_inserted += 1
        seq += 1

        # Process each message
        for msg in messages:
            msg_id = msg["id"]
            msg_time = msg["time_created"]

            try:
                msg_data = json.loads(msg["data"])
            except json.JSONDecodeError:
                continue

            role = msg_data.get("role", "user")

            # Read parts for this message
            cur.execute("""
                SELECT id, data FROM part
                WHERE message_id = ?
                ORDER BY id ASC
            """, (msg_id,))
            parts = cur.fetchall()

            if role == "user":
                text_parts = []
                for p in parts:
                    pdata = json.loads(p["data"])
                    if pdata.get("type") == "text":
                        text_parts.append(pdata.get("text", ""))
                    elif pdata.get("type") == "file":
                        src = pdata.get("source", {})
                        text_parts.append(f"[File: {src.get('text',{}).get('value','file')}]")

                text = "\n".join(text_parts) if text_parts else "(empty)"

                user_data = {
                    "text": text,
                    "files": [],
                    "agents": [],
                    "time": {"created": msg_time}
                }

                cur.execute(
                    "INSERT OR IGNORE INTO session_message (id, session_id, type, seq, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (msg_id, sid, "user", seq, msg_time, msg_time, json.dumps(user_data))
                )
                if cur.rowcount > 0:
                    total_inserted += 1

            elif role == "assistant":
                step_finish = None
                for p in parts:
                    pdata = json.loads(p["data"])
                    if pdata.get("type") == "step-finish":
                        step_finish = pdata

                content = []
                for p in parts:
                    pdata = json.loads(p["data"])
                    ptype = pdata.get("type")

                    if ptype == "text":
                        content.append({
                            "type": "text",
                            "id": p["id"].replace("prt_", "txt_")[:36],
                            "text": pdata.get("text", "")
                        })
                    elif ptype == "reasoning":
                        entry = {
                            "type": "reasoning",
                            "id": p["id"].replace("prt_", "rsn_")[:36],
                            "text": pdata.get("text", "")
                        }
                        if pdata.get("metadata"):
                            entry["providerMetadata"] = pdata["metadata"]
                        content.append(entry)
                    elif ptype == "tool":
                        state = pdata.get("state", {})
                        status = state.get("status", "completed")
                        tool_entry = {
                            "type": "tool",
                            "id": p["id"].replace("prt_", "tl_")[:36],
                            "name": pdata.get("tool", pdata.get("name", "unknown")),
                            "state": {
                                "status": status,
                                "input": json.dumps(state.get("input", {})),
                                "content": [],
                                "structured": {}
                            },
                            "time": {
                                "created": pdata.get("time", {}).get("start", msg_time),
                                "completed": pdata.get("time", {}).get("end", msg_time)
                            }
                        }
                        if status == "error" and state.get("error"):
                            tool_entry["state"]["error"] = state["error"]
                            tool_entry["state"]["result"] = state.get("raw", "")
                        elif status == "completed":
                            tool_entry["state"]["result"] = state.get("raw", "")
                            if state.get("outputPaths"):
                                tool_entry["state"]["outputPaths"] = state["outputPaths"]
                        content.append(tool_entry)

                model = {
                    "id": msg_data.get("modelID") or initial_model["id"],
                    "providerID": msg_data.get("providerID") or initial_model["providerID"]
                }

                tokens = {"input": 0, "output": 0, "reasoning": 0, "cache": {"read": 0, "write": 0}}
                if step_finish and "tokens" in step_finish:
                    t = step_finish["tokens"]
                    tokens["input"] = t.get("input", 0)
                    tokens["output"] = t.get("output", 0)
                    tokens["reasoning"] = t.get("reasoning", 0)
                    if "cache" in t:
                        tokens["cache"]["read"] = t["cache"].get("read", 0)
                        tokens["cache"]["write"] = t["cache"].get("write", 0)

                cost = msg_data.get("cost", 0)
                if step_finish and "cost" in step_finish:
                    cost = step_finish["cost"]
                if cost == 0 and msg_data.get("cost"):
                    cost = msg_data["cost"]

                finish = msg_data.get("finish")
                if step_finish:
                    finish = step_finish.get("reason", finish)

                assistant_data = {
                    "agent": msg_data.get("agent", initial_agent),
                    "model": model,
                    "content": content,
                    "cost": cost,
                    "tokens": tokens,
                    "time": {
                        "created": msg_data.get("time", {}).get("created", msg_time)
                    }
                }

                if finish:
                    assistant_data["finish"] = finish
                if msg_data.get("time", {}).get("completed"):
                    assistant_data["time"]["completed"] = msg_data["time"]["completed"]
                elif step_finish and step_finish.get("time", {}).get("end"):
                    assistant_data["time"]["completed"] = step_finish["time"]["end"]
                if msg_data.get("path"):
                    assistant_data["snapshot"] = {
                        "start": msg_data["path"].get("cwd"),
                        "end": msg_data["path"].get("cwd")
                    }

                cur.execute(
                    "INSERT OR IGNORE INTO session_message (id, session_id, type, seq, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (msg_id, sid, "assistant", seq, msg_time, msg_time, json.dumps(assistant_data))
                )
                if cur.rowcount > 0:
                    total_inserted += 1

            seq += 1

        conn.commit()
        print(f"  [{sid[:20]}...] v{version} {n_msgs:5d} msgs -> seq {base_seq}-{seq-1}")

    print(f"\nDone. Inserted {total_inserted} rows into session_message.")
    conn.close()
    return total_inserted > 0

if __name__ == "__main__":
    print("Migrating old session messages to session_message table (v2)...")
    ran = migrate()
    if ran:
        print("\nRestart OpenCode TUI to see changes.")
    else:
        print("Nothing to migrate.")
