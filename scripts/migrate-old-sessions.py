#!/usr/bin/env python3
"""Migrate old session messages from v1 (message+part) to v2 (session_message) tables.

Safe, idempotent: only inserts for sessions missing user/assistant entries.
"""

import sqlite3
import json
import uuid
import sys

DB = "/home/snow/.local/share/opencode/opencode.db"

def gen_id(prefix="msg"):
    return f"{prefix}_{uuid.uuid4().hex[:24]}"

def migrate():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # Find sessions that have messages in `message` table
    # but no user/assistant entries in `session_message`
    cur.execute("""
        SELECT s.id, s.version, s.title,
               COUNT(DISTINCT m.id) as msg_count,
               COUNT(DISTINCT sm.id) as sm_count
        FROM session s
        JOIN message m ON m.session_id = s.id
        LEFT JOIN session_message sm ON sm.session_id = s.id
            AND sm.type IN ('user', 'assistant')
        GROUP BY s.id
        HAVING sm_count = 0 AND msg_count > 0
        ORDER BY s.time_created
    """)
    sessions = cur.fetchall()
    print(f"Found {len(sessions)} sessions needing migration")

    total_inserted = 0
    total_skipped = 0

    for sess in sessions:
        sid = sess["id"]
        version = sess["version"]
        title = sess["title"]
        n_msgs = sess["msg_count"]
        print(f"\n  [{sid[:20]}...] v{version} \"{title[:40]}\" ({n_msgs} messages)")

        # Check if any session_message rows already exist for this session
        cur.execute("SELECT MAX(seq) as max_seq FROM session_message WHERE session_id = ?", (sid,))
        row = cur.fetchone()
        existing_max_seq = row["max_seq"] if row and row["max_seq"] else 0

        if existing_max_seq > 0:
            print(f"    Has {existing_max_seq} existing session_message entries (control msgs)")

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
        initial_model = {"id": "big-pickle", "providerID": "opencode"}
        for msg in messages:
            try:
                data = json.loads(msg["data"])
                if data.get("agent"):
                    initial_agent = data["agent"]
                if data.get("model"):
                    m = data["model"]
                    initial_model = {
                        "id": m.get("modelID") or m.get("id", "big-pickle"),
                        "providerID": m.get("providerID", "opencode"),
                    }
                if data.get("modelID"):
                    initial_model["id"] = data["modelID"]
                if data.get("providerID"):
                    initial_model["providerID"] = data["providerID"]
                break
            except (json.JSONDecodeError, KeyError):
                continue

        # Insert agent-switched and model-switched if no existing entries
        seq = existing_max_seq
        if existing_max_seq == 0:
            seq = 1
            now = messages[0]["time_created"] if messages else 1780000000000
            cur.execute(
                "INSERT OR IGNORE INTO session_message (id, session_id, type, seq, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (gen_id("msg"), sid, "agent-switched", seq, now, now,
                 json.dumps({"time": {"created": now}, "agent": initial_agent}))
            )
            print(f"    Inserted agent-switched seq={seq}")
            total_inserted += 1

            seq = 2
            now = messages[0]["time_created"] if messages else 1780000000000
            cur.execute(
                "INSERT OR IGNORE INTO session_message (id, session_id, type, seq, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (gen_id("msg"), sid, "model-switched", seq, now, now,
                 json.dumps({"time": {"created": now}, "model": initial_model}))
            )
            print(f"    Inserted model-switched seq={seq}")
            total_inserted += 1
            seq = 3
        else:
            seq = existing_max_seq + 1

        # Process each message
        for msg in messages:
            msg_id = msg["id"]
            msg_time = msg["time_created"]

            try:
                msg_data = json.loads(msg["data"])
            except json.JSONDecodeError:
                print(f"    SKIP message {msg_id}: invalid JSON")
                total_skipped += 1
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
                # Build user message
                text_parts = []
                for p in parts:
                    pdata = json.loads(p["data"])
                    if pdata.get("type") == "text":
                        text_parts.append(pdata.get("text", ""))
                    elif pdata.get("type") == "file":
                        text_parts.append(f"[File: {pdata.get('source',{}).get('text',{}).get('value','file')}]")

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
                # Extract token/cost info from step-finish
                step_finish = None
                for p in parts:
                    pdata = json.loads(p["data"])
                    if pdata.get("type") == "step-finish":
                        step_finish = pdata

                # Build content array
                content = []
                for p in parts:
                    pdata = json.loads(p["data"])
                    ptype = pdata.get("type")

                    if ptype == "text":
                        aid = p["id"].replace("prt_", "txt_")[:36]
                        content.append({
                            "type": "text",
                            "id": aid,
                            "text": pdata.get("text", "")
                        })
                    elif ptype == "reasoning":
                        aid = p["id"].replace("prt_", "rsn_")[:36]
                        entry = {
                            "type": "reasoning",
                            "id": aid,
                            "text": pdata.get("text", "")
                        }
                        if pdata.get("metadata"):
                            entry["providerMetadata"] = pdata["metadata"]
                        content.append(entry)
                    elif ptype == "tool":
                        tid = p["id"].replace("prt_", "tl_")[:36]
                        state = pdata.get("state", {})
                        status = state.get("status", "completed")
                        tool_entry = {
                            "type": "tool",
                            "id": tid,
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

                # Build model from message data
                model = initial_model
                if msg_data.get("modelID") or msg_data.get("providerID"):
                    model = {
                        "id": msg_data.get("modelID") or msg_data.get("modelID", initial_model["id"]),
                        "providerID": msg_data.get("providerID") or msg_data.get("providerID", initial_model["providerID"])
                    }

                # Build token info
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
                    "snapshot": {
                        "start": msg_data.get("path", {}).get("cwd"),
                        "end": msg_data.get("path", {}).get("cwd")
                    } if msg_data.get("path") else None,
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

                if assistant_data["snapshot"] is None:
                    del assistant_data["snapshot"]

                cur.execute(
                    "INSERT OR IGNORE INTO session_message (id, session_id, type, seq, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (msg_id, sid, "assistant", seq, msg_time, msg_time, json.dumps(assistant_data))
                )
                if cur.rowcount > 0:
                    total_inserted += 1

            seq += 1

        conn.commit()
        print(f"    -> seq up to {seq-1}")

    print(f"\nDone. Inserted {total_inserted} rows, skipped {total_skipped}.")
    conn.close()
    return total_inserted > 0

if __name__ == "__main__":
    print("Migrating old session messages to session_message table...")
    ran = migrate()
    if ran:
        print("\nRestart OpenCode TUI to see changes.")
    else:
        print("Nothing to migrate.")
