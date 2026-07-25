/**
 * OpenCode-style command palette for Pi
 *
 *   Ctrl+K     — Open command palette (fuzzy-search slash commands)
 *   /palette   — Same as above
 *
 * Selecting a command pre-fills the editor — press Enter to run it.
 *
 * Ctrl+P is handled by keybindings.json → pi's built-in /resume picker.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// ── Fuzzy matcher ──────────────────────────────────────────────────────

function fuzzyScore(query: string, text: string): number {
  if (!query) return text.length;
  const q = query.toLowerCase();
  const t = text.toLowerCase();
  let qi = 0;
  let score = 0;
  for (let ti = 0; ti < t.length && qi < q.length; ti++) {
    if (t[ti] === q[qi]) {
      score += qi === 0 ? 10 : ti > 0 && t[ti - 1] === q[qi - 1] ? 5 : 1;
      qi++;
    }
  }
  if (qi < q.length) return -1;
  score -= (t.length - q.length) * 0.5;
  return score;
}

interface Item {
  id: string;
  label: string;
  description?: string;
}

// ═══════════════════════════════════════════════════════════════════════
//  Searchable list overlay
// ═══════════════════════════════════════════════════════════════════════

function showSearchableList(
  ctx: any,
  title: string,
  items: Item[],
  emptyMsg = "No results",
): Promise<Item | null> {
  let query = "";
  let cursorPos = 0;
  let selectedIdx = 0;

  function filter(): Item[] {
    if (!query) return [...items];
    const scored = items
      .map((item) => ({
        item,
        score: Math.max(
          fuzzyScore(query, item.label),
          fuzzyScore(query, item.description || ""),
        ),
      }))
      .filter((s) => s.score >= 0)
      .sort((a, b) => b.score - a.score);
    return scored.map((s) => s.item);
  }

  let filtered = filter();
  const maxVisible = 14;
  const ESC = "\x1b";

  return ctx.ui.custom<Item | null>(
    (tui: any, theme: any, _kb: any, done: any) => ({
      render: (width: number) => {
        const innerW = width - 2;
        if (innerW < 10) return ["Window too narrow"];

        const fg = (c: string, s: string) => theme.fg(c, s);
        const border = (s: string) => fg("border", s);
        const dim = (s: string) => fg("dim", s);
        const accent = (s: string) => fg("accent", s);

        const padRight = (s: string, len: number) =>
          s + " ".repeat(Math.max(0, len - visibleWidth(s)));
        const row = (s: string) => border("│") + padRight(s, innerW) + border("│");

        const lines: string[] = [];
        lines.push(border("╭") + border("─".repeat(innerW)) + border("╮"));
        lines.push(row(` ${theme.bold(accent(title))}`));
        lines.push(row(` ${dim("─".repeat(innerW))}`));

        const beforeC = query.slice(0, cursorPos);
        const atC = query[cursorPos] || " ";
        const afterC = query.slice(cursorPos + 1);
        lines.push(row(` ${beforeC}\x1b[7m${atC}\x1b[27m${afterC}`));
        lines.push(row(""));

        const maxVis = Math.min(maxVisible, Math.max(1, filtered.length));
        const half = Math.floor(maxVis / 2);
        let startIdx = Math.max(0, Math.min(selectedIdx - half, filtered.length - maxVis));
        const visible = filtered.slice(startIdx, startIdx + maxVis);

        if (filtered.length === 0) {
          lines.push(row(` ${dim(emptyMsg)}`));
        } else {
          for (let vi = 0; vi < maxVis; vi++) {
            const item = visible[vi];
            if (!item) { lines.push(row("")); continue; }
            const realIdx = startIdx + vi;
            const isSel = realIdx === selectedIdx;
            const prefix = isSel ? accent("▸ ") : "  ";
            const label = isSel ? accent(item.label) : item.label;
            const desc = item.description
              ? dim(" " + truncateToWidth(item.description, Math.max(10, innerW - visibleWidth(label) - 6)))
              : "";
            lines.push(row(truncateToWidth(prefix + label + desc, innerW)));
          }
        }

        if (filtered.length > 1) {
          lines.push(row(dim(padRight(`${selectedIdx + 1}/${filtered.length}`, innerW))));
        }
        lines.push(row(dim("↑↓ · type · enter select · esc/q cancel")));
        lines.push(border("╰") + border("─".repeat(innerW)) + border("╯"));
        return lines;
      },

      handleInput: (data: string) => {
        if (data === ESC || data === "\x03" || data === ESC + "[") {
          done(null);
          return;
        }
        if (data === "\r" || data === "\n") {
          const sel = filtered[selectedIdx];
          if (sel) done(sel);
          return;
        }
        if (data === ESC + "[A") { if (selectedIdx > 0) selectedIdx--; tui.requestRender(); return; }
        if (data === ESC + "[B") { if (selectedIdx < filtered.length - 1) selectedIdx++; tui.requestRender(); return; }
        if (data === ESC + "[5~") { selectedIdx = Math.max(0, selectedIdx - maxVisible); tui.requestRender(); return; }
        if (data === ESC + "[6~") { selectedIdx = Math.min(filtered.length - 1, selectedIdx + maxVisible); tui.requestRender(); return; }
        if (data === ESC + "[H" || data === ESC + "[1~") { selectedIdx = 0; cursorPos = 0; tui.requestRender(); return; }
        if (data === ESC + "[F" || data === ESC + "[4~") { selectedIdx = filtered.length - 1; cursorPos = query.length; tui.requestRender(); return; }
        if (data === "\x7f" || data === "\b") {
          if (cursorPos > 0) {
            query = query.slice(0, cursorPos - 1) + query.slice(cursorPos);
            cursorPos--; selectedIdx = 0; filtered = filter(); tui.requestRender();
          }
          return;
        }
        if (data === ESC + "[D") { if (cursorPos > 0) cursorPos--; tui.requestRender(); return; }
        if (data === ESC + "[C") { if (cursorPos < query.length) cursorPos++; tui.requestRender(); return; }
        if (data === ESC + "[3~") {
          if (cursorPos < query.length) {
            query = query.slice(0, cursorPos) + query.slice(cursorPos + 1);
            selectedIdx = 0; filtered = filter(); tui.requestRender();
          }
          return;
        }
        if (data.length === 1 && data.charCodeAt(0) >= 32 && data.charCodeAt(0) !== 127) {
          query = query.slice(0, cursorPos) + data + query.slice(cursorPos);
          cursorPos++; selectedIdx = 0; filtered = filter(); tui.requestRender();
        }
      },

      invalidate: () => {},
    }),
    { overlay: true },
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  EXTENSION ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════

export default function opencodeTuiExtension(pi: ExtensionAPI) {
  async function openPalette(ctx: any) {
    if (ctx.mode !== "tui") return;

    const commands = pi.getCommands();
    const items: Item[] = commands
      .filter((c: any) => c.name)
      .map((c: any) => ({
        id: c.name,
        label: `/${c.name}`,
        description: c.description || `(${c.source})`,
      }));
    items.sort((a: any, b: any) => a.label.localeCompare(b.label));

    if (items.length === 0) { ctx.ui.notify("No commands available", "info"); return; }

    const result = await showSearchableList(ctx, "Command Palette", items);
    if (result) {
      ctx.ui.setEditorText(`/${result.id} `);
    }
  }

  // ── Command ────────────────────────────────────────────────

  pi.registerCommand("palette", {
    description: "Open command palette (fuzzy-search commands)",
    handler: async (_args: string, ctx: any) => { await openPalette(ctx); },
  });

  // ── Shortcut ───────────────────────────────────────────────

  pi.registerShortcut("ctrl+k", {
    description: "Open command palette",
    handler: async (ctx: any) => { await openPalette(ctx); },
  });

  // ── Status ──────────────────────────────────────────────────

  pi.on("session_start", async (_event: any, ctx: any) => {
    ctx.ui.setStatus("opencode-tui", ctx.ui.theme.fg("dim", "⌘K palette"));
  });
}
