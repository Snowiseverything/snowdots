/**
 * Keybinds Reference Overlay
 *
 * Opens an overlay popup showing all Pi keyboard shortcuts, grouped by category.
 * Reads from the live KeybindingsManager so custom keybindings.json overrides
 * are reflected in real time.
 *
 * Commands:
 *   /keybinds       - Open keybinds reference
 *
 * To assign a keyboard shortcut, add to ~/.pi/agent/keybindings.json:
 *   { "app.keybinds.show": ["ctrl+shift+k"] }
 *
 * Requires TUI mode (interactive terminal).
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";
import type { KeyId } from "@earendil-works/pi-tui";

// ── Raw ANSI helpers (no theme dependency — avoids `this` binding crashes) ──

const ansi = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",

  fg: {
    accent: (s: string) => `\x1b[38;5;75m${s}\x1b[39m`,
    text: (s: string) => `\x1b[38;5;252m${s}\x1b[39m`,
    muted: (s: string) => `\x1b[38;5;245m${s}\x1b[39m`,
    dim: (s: string) => `\x1b[38;5;238m${s}\x1b[39m`,
    warning: (s: string) => `\x1b[38;5;215m${s}\x1b[39m`,
    border: (s: string) => `\x1b[38;5;240m${s}\x1b[39m`,
  },
};

function accent(s: string): string {
  return ansi.fg.accent(ansi.bold + s + ansi.reset);
}
function header(s: string): string {
  return ansi.fg.accent(ansi.bold + s + ansi.reset);
}
function text(s: string): string {
  return ansi.fg.text(s);
}
function muted(s: string): string {
  return ansi.fg.muted(s);
}
function dim(s: string): string {
  return ansi.fg.dim(s);
}
function warning(s: string): string {
  return ansi.fg.warning(s);
}
function border(s: string): string {
  return ansi.fg.border(s);
}

// ── All keybinding definitions ─────────────────────────────────────

interface KbDef {
  defaultKeys: KeyId | KeyId[];
  description: string;
}

const KEYBINDINGS: Record<string, KbDef> = {
  "tui.editor.cursorUp": { defaultKeys: "up", description: "Move cursor up" },
  "tui.editor.cursorDown": {
    defaultKeys: "down",
    description: "Move cursor down",
  },
  "tui.editor.cursorLeft": {
    defaultKeys: ["left", "ctrl+b"],
    description: "Move cursor left",
  },
  "tui.editor.cursorRight": {
    defaultKeys: ["right", "ctrl+f"],
    description: "Move cursor right",
  },
  "tui.editor.cursorWordLeft": {
    defaultKeys: ["alt+left", "ctrl+left", "alt+b"],
    description: "Move cursor word left",
  },
  "tui.editor.cursorWordRight": {
    defaultKeys: ["alt+right", "ctrl+right", "alt+f"],
    description: "Move cursor word right",
  },
  "tui.editor.cursorLineStart": {
    defaultKeys: ["home", "ctrl+a"],
    description: "Move to line start",
  },
  "tui.editor.cursorLineEnd": {
    defaultKeys: ["end", "ctrl+e"],
    description: "Move to line end",
  },
  "tui.editor.jumpForward": {
    defaultKeys: "ctrl+]",
    description: "Jump forward to character",
  },
  "tui.editor.jumpBackward": {
    defaultKeys: "ctrl+alt+]",
    description: "Jump backward to character",
  },
  "tui.editor.pageUp": { defaultKeys: "pageUp", description: "Page up" },
  "tui.editor.pageDown": { defaultKeys: "pageDown", description: "Page down" },
  "tui.editor.deleteCharBackward": {
    defaultKeys: "backspace",
    description: "Delete character backward",
  },
  "tui.editor.deleteCharForward": {
    defaultKeys: ["delete", "ctrl+d"],
    description: "Delete character forward",
  },
  "tui.editor.deleteWordBackward": {
    defaultKeys: ["ctrl+w", "alt+backspace"],
    description: "Delete word backward",
  },
  "tui.editor.deleteWordForward": {
    defaultKeys: ["alt+d", "alt+delete"],
    description: "Delete word forward",
  },
  "tui.editor.deleteToLineStart": {
    defaultKeys: "ctrl+u",
    description: "Delete to line start",
  },
  "tui.editor.deleteToLineEnd": {
    defaultKeys: "ctrl+k",
    description: "Delete to line end",
  },
  "tui.editor.yank": {
    defaultKeys: "ctrl+y",
    description: "Paste most recently deleted text",
  },
  "tui.editor.yankPop": {
    defaultKeys: "alt+y",
    description: "Cycle through deleted text after yank",
  },
  "tui.editor.undo": { defaultKeys: "ctrl+-", description: "Undo last edit" },
  "tui.input.newLine": {
    defaultKeys: ["shift+enter", "ctrl+j"],
    description: "Insert new line",
  },
  "tui.input.submit": { defaultKeys: "enter", description: "Submit input" },
  "tui.input.tab": { defaultKeys: "tab", description: "Tab / autocomplete" },
  "tui.input.copy": {
    defaultKeys: "ctrl+c",
    description: "Copy selection to clipboard",
  },
  "tui.select.up": { defaultKeys: "up", description: "Move selection up" },
  "tui.select.down": {
    defaultKeys: "down",
    description: "Move selection down",
  },
  "tui.select.pageUp": {
    defaultKeys: "pageUp",
    description: "Page up in list",
  },
  "tui.select.pageDown": {
    defaultKeys: "pageDown",
    description: "Page down in list",
  },
  "tui.select.confirm": {
    defaultKeys: "enter",
    description: "Confirm selection",
  },
  "tui.select.cancel": {
    defaultKeys: ["escape", "ctrl+c"],
    description: "Cancel selection",
  },
  "app.interrupt": { defaultKeys: "escape", description: "Cancel or abort" },
  "app.clear": { defaultKeys: "ctrl+c", description: "Clear editor" },
  "app.exit": {
    defaultKeys: "ctrl+d",
    description: "Exit when editor is empty",
  },
  "app.suspend": {
    defaultKeys: "ctrl+z",
    description: "Suspend to background",
  },
  "app.thinking.cycle": {
    defaultKeys: "shift+tab",
    description: "Cycle thinking level",
  },
  "app.model.cycleForward": {
    defaultKeys: "ctrl+p",
    description: "Cycle to next model",
  },
  "app.model.cycleBackward": {
    defaultKeys: "shift+ctrl+p",
    description: "Cycle to previous model",
  },
  "app.model.select": {
    defaultKeys: "ctrl+l",
    description: "Open model selector",
  },
  "app.tools.expand": {
    defaultKeys: "ctrl+o",
    description: "Collapse or expand tool output",
  },
  "app.thinking.toggle": {
    defaultKeys: "ctrl+t",
    description: "Collapse or expand thinking blocks",
  },
  "app.session.toggleNamedFilter": {
    defaultKeys: "ctrl+n",
    description: "Toggle named-only session filter",
  },
  "app.editor.external": {
    defaultKeys: "ctrl+g",
    description: "Open in external editor",
  },
  "app.message.copy": {
    defaultKeys: "ctrl+x",
    description: "Copy last assistant / selected tree message",
  },
  "app.message.followUp": {
    defaultKeys: "alt+enter",
    description: "Queue follow-up message",
  },
  "app.message.dequeue": {
    defaultKeys: "alt+up",
    description: "Restore queued messages to editor",
  },
  "app.clipboard.pasteImage": {
    defaultKeys: ["ctrl+v", "alt+v"],
    description: "Paste image from clipboard",
  },
  "app.session.new": { defaultKeys: [], description: "Start a new session" },
  "app.session.tree": {
    defaultKeys: [],
    description: "Open session tree navigator",
  },
  "app.session.fork": { defaultKeys: [], description: "Fork current session" },
  "app.session.resume": {
    defaultKeys: [],
    description: "Open session resume picker",
  },
  "app.tree.foldOrUp": {
    defaultKeys: ["ctrl+left", "alt+left"],
    description: "Fold branch or jump to previous segment",
  },
  "app.tree.unfoldOrDown": {
    defaultKeys: ["ctrl+right", "alt+right"],
    description: "Unfold branch or jump to next segment",
  },
  "app.tree.editLabel": {
    defaultKeys: "shift+l",
    description: "Edit label on selected tree node",
  },
  "app.tree.toggleLabelTimestamp": {
    defaultKeys: "shift+t",
    description: "Toggle label timestamps in tree",
  },
  "app.session.togglePath": {
    defaultKeys: "ctrl+p",
    description: "Toggle path display in session picker",
  },
  "app.session.toggleSort": {
    defaultKeys: "ctrl+s",
    description: "Toggle sort mode in session picker",
  },
  "app.session.rename": {
    defaultKeys: "ctrl+r",
    description: "Rename session",
  },
  "app.session.delete": {
    defaultKeys: "ctrl+d",
    description: "Delete session",
  },
  "app.session.deleteNoninvasive": {
    defaultKeys: "ctrl+backspace",
    description: "Delete session when query empty",
  },
  "app.models.save": {
    defaultKeys: "ctrl+s",
    description: "Save model selection to settings",
  },
  "app.models.enableAll": {
    defaultKeys: "ctrl+a",
    description: "Enable all models",
  },
  "app.models.clearAll": {
    defaultKeys: "ctrl+x",
    description: "Clear all models",
  },
  "app.models.toggleProvider": {
    defaultKeys: "ctrl+p",
    description: "Toggle all models for current provider",
  },
  "app.models.reorderUp": {
    defaultKeys: "alt+up",
    description: "Move model up in cycle order",
  },
  "app.models.reorderDown": {
    defaultKeys: "alt+down",
    description: "Move model down in cycle order",
  },
  "app.tree.filter.default": {
    defaultKeys: "ctrl+d",
    description: "Tree filter: default view",
  },
  "app.tree.filter.noTools": {
    defaultKeys: "ctrl+t",
    description: "Tree filter: hide tool results",
  },
  "app.tree.filter.userOnly": {
    defaultKeys: "ctrl+u",
    description: "Tree filter: user messages only",
  },
  "app.tree.filter.labeledOnly": {
    defaultKeys: "ctrl+l",
    description: "Tree filter: labeled entries only",
  },
  "app.tree.filter.all": {
    defaultKeys: "ctrl+a",
    description: "Tree filter: show all entries",
  },
  "app.tree.filter.cycleForward": {
    defaultKeys: "ctrl+o",
    description: "Tree filter: cycle forward",
  },
  "app.tree.filter.cycleBackward": {
    defaultKeys: "shift+ctrl+o",
    description: "Tree filter: cycle backward",
  },
};

// ── Category groupings ──────────────────────────────────────────────

interface CategoryDef {
  title: string;
  ids: string[];
}

const CATEGORIES: CategoryDef[] = [
  {
    title: "Editor: Cursor Movement",
    ids: [
      "tui.editor.cursorUp",
      "tui.editor.cursorDown",
      "tui.editor.cursorLeft",
      "tui.editor.cursorRight",
      "tui.editor.cursorWordLeft",
      "tui.editor.cursorWordRight",
      "tui.editor.cursorLineStart",
      "tui.editor.cursorLineEnd",
      "tui.editor.jumpForward",
      "tui.editor.jumpBackward",
      "tui.editor.pageUp",
      "tui.editor.pageDown",
    ],
  },
  {
    title: "Editor: Deletion",
    ids: [
      "tui.editor.deleteCharBackward",
      "tui.editor.deleteCharForward",
      "tui.editor.deleteWordBackward",
      "tui.editor.deleteWordForward",
      "tui.editor.deleteToLineStart",
      "tui.editor.deleteToLineEnd",
    ],
  },
  {
    title: "Editor: Kill Ring & Undo",
    ids: ["tui.editor.yank", "tui.editor.yankPop", "tui.editor.undo"],
  },
  {
    title: "Input",
    ids: [
      "tui.input.newLine",
      "tui.input.submit",
      "tui.input.tab",
      "tui.input.copy",
    ],
  },
  {
    title: "Selection Dialogs",
    ids: [
      "tui.select.up",
      "tui.select.down",
      "tui.select.pageUp",
      "tui.select.pageDown",
      "tui.select.confirm",
      "tui.select.cancel",
    ],
  },
  {
    title: "Application",
    ids: [
      "app.interrupt",
      "app.clear",
      "app.exit",
      "app.suspend",
      "app.editor.external",
      "app.clipboard.pasteImage",
    ],
  },
  {
    title: "Sessions",
    ids: [
      "app.session.new",
      "app.session.tree",
      "app.session.fork",
      "app.session.resume",
      "app.session.togglePath",
      "app.session.toggleSort",
      "app.session.toggleNamedFilter",
      "app.session.rename",
      "app.session.delete",
      "app.session.deleteNoninvasive",
    ],
  },
  {
    title: "Models & Thinking",
    ids: [
      "app.model.select",
      "app.model.cycleForward",
      "app.model.cycleBackward",
      "app.thinking.cycle",
      "app.thinking.toggle",
    ],
  },
  {
    title: "Display & Messages",
    ids: [
      "app.tools.expand",
      "app.message.copy",
      "app.message.followUp",
      "app.message.dequeue",
    ],
  },
  {
    title: "Tree Navigation",
    ids: [
      "app.tree.foldOrUp",
      "app.tree.unfoldOrDown",
      "app.tree.editLabel",
      "app.tree.toggleLabelTimestamp",
    ],
  },
  {
    title: "Tree Filters",
    ids: [
      "app.tree.filter.default",
      "app.tree.filter.noTools",
      "app.tree.filter.userOnly",
      "app.tree.filter.labeledOnly",
      "app.tree.filter.all",
      "app.tree.filter.cycleForward",
      "app.tree.filter.cycleBackward",
    ],
  },
  {
    title: "Scoped Models Selector",
    ids: [
      "app.models.save",
      "app.models.enableAll",
      "app.models.clearAll",
      "app.models.toggleProvider",
      "app.models.reorderUp",
      "app.models.reorderDown",
    ],
  },
];

// ── Row types ──────────────────────────────────────────────────────

type Row =
  | { kind: "header"; title: string }
  | { kind: "sep" }
  | {
      kind: "binding";
      id: string;
      keys: string;
      description: string;
      customized: boolean;
    };

// ── Build rows from categories using live KeybindingsManager ──────

function buildRows(kbm: {
  getKeys: (id: string) => KeyId[];
  getUserBindings: () => Record<string, KeyId | KeyId[] | undefined>;
}): Row[] {
  const userBindings = kbm.getUserBindings();
  const rows: Row[] = [];

  for (const cat of CATEGORIES) {
    const catRows: Row[] = [];
    for (const id of cat.ids) {
      const def = (KEYBINDINGS as Record<string, KbDef>)[id];
      if (!def) continue;

      const resolved = kbm.getKeys(id);
      const keysStr = resolved.map(formatKey).join(", ");
      const customized = id in userBindings;

      catRows.push({
        kind: "binding",
        id,
        keys: keysStr || "(none)",
        description: def.description,
        customized,
      });
    }

    if (catRows.length === 0) continue;
    rows.push({ kind: "header", title: cat.title });
    rows.push(...catRows);
    rows.push({ kind: "sep" });
  }

  // Remove trailing sep
  if (rows.length > 0 && rows.at(-1)?.kind === "sep") {
    rows.pop();
  }

  return rows;
}

// ── Format key IDs for display ─────────────────────────────────────

function formatKey(key: string): string {
  return key
    .split("+")
    .map((part) => {
      switch (part) {
        case "escape":
          return "Esc";
        case "enter":
          return "Enter";
        case "backspace":
          return "Bksp";
        case "delete":
          return "Del";
        case "tab":
          return "Tab";
        case "space":
          return "Space";
        case "pageUp":
          return "PgUp";
        case "pageDown":
          return "PgDn";
        case "home":
          return "Home";
        case "end":
          return "End";
        case "insert":
          return "Ins";
        default:
          return part.length === 1
            ? part.toUpperCase()
            : part.charAt(0).toUpperCase() + part.slice(1);
      }
    })
    .join("+");
}

// ── Scrollable Keybinds Component ──────────────────────────────────

class KeybindsView {
  private rows: Row[] = [];
  private scrollOffset = 0;
  private maxVisible: number;
  private done: (result: null) => void;
  private tui: { requestRender: () => void };
  private cachedWidth = 0;
  private cachedLines: string[] = [];
  private cachedVersion = 0;
  private version = 0;

  constructor(
    tui: { requestRender: () => void },
    rows: Row[],
    maxVisible: number,
    done: (result: null) => void,
  ) {
    this.tui = tui;
    this.rows = rows;
    this.maxVisible = maxVisible;
    this.done = done;
  }

  handleInput(data: string): void {
    if (
      matchesKey(data, Key.escape) ||
      matchesKey(data, Key.ctrl("c")) ||
      data === "q" ||
      data === "Q"
    ) {
      this.done(null);
      return;
    }

    const totalRows = this.rows.length;

    if (matchesKey(data, Key.up)) {
      if (this.scrollOffset > 0) {
        this.scrollOffset--;
        this.bump();
      }
    } else if (matchesKey(data, Key.down)) {
      if (this.scrollOffset < totalRows - this.maxVisible) {
        this.scrollOffset++;
        this.bump();
      }
    } else if (matchesKey(data, Key.pageUp) || data === "b" || data === "B") {
      this.scrollOffset = Math.max(0, this.scrollOffset - this.maxVisible);
      this.bump();
    } else if (matchesKey(data, Key.pageDown) || data === "f" || data === "F") {
      this.scrollOffset = Math.min(
        totalRows - this.maxVisible,
        this.scrollOffset + this.maxVisible,
      );
      this.bump();
    } else if (matchesKey(data, Key.home) || data === "g" || data === "G") {
      this.scrollOffset = 0;
      this.bump();
    } else if (matchesKey(data, Key.end)) {
      this.scrollOffset = Math.max(0, totalRows - this.maxVisible);
      this.bump();
    }
  }

  private bump(): void {
    this.version++;
    this.tui.requestRender();
  }

  invalidate(): void {
    this.cachedWidth = 0;
  }

  render(maxWidth: number): string[] {
    if (this.cachedWidth === maxWidth && this.cachedVersion === this.version) {
      return this.cachedLines;
    }

    const width = Math.max(20, maxWidth);
    const pad = 2;
    const inner = width - pad * 2;

    const lines: string[] = [];

    // Column widths
    const keysCol = Math.max(20, Math.floor(inner * 0.28));
    const actionCol = Math.max(25, Math.floor(inner * 0.32));
    const descCol = Math.max(10, inner - keysCol - actionCol - 2);

    const visible = this.rows.slice(
      this.scrollOffset,
      this.scrollOffset + this.maxVisible,
    );

    for (const row of visible) {
      if (row.kind === "header") {
        lines.push(
          " ".repeat(pad) +
            header(row.title) +
            " ".repeat(Math.max(0, width - pad * 2 - visibleWidth(row.title))),
        );
      } else if (row.kind === "sep") {
        lines.push(
          " ".repeat(pad) + border("─".repeat(inner)) + " ".repeat(pad),
        );
      } else if (row.kind === "binding") {
        let keys: string;
        if (row.customized) {
          keys = warning(truncateToWidth(row.keys, keysCol));
        } else if (row.keys) {
          keys = text(truncateToWidth(row.keys, keysCol));
        } else {
          keys = dim(truncateToWidth(row.keys, keysCol));
        }
        const keysPadded =
          keys + " ".repeat(Math.max(0, keysCol - visibleWidth(row.keys)));

        const action = muted(truncateToWidth(row.id, actionCol));
        const actionPadded =
          action + " ".repeat(Math.max(0, actionCol - visibleWidth(row.id)));

        const desc = text(truncateToWidth(row.description, descCol));
        const mark = row.customized ? warning(" *") : "  ";

        lines.push(
          " ".repeat(pad) + keysPadded + " " + actionPadded + " " + desc + mark,
        );
      }
    }

    // Footer
    const footerParts = [
      dim("↑↓ scroll"),
      dim("PgUp/PgDn page"),
      dim("Esc/q close"),
    ];
    if (
      this.scrollOffset > 0 ||
      this.scrollOffset + this.maxVisible < this.rows.length
    ) {
      const pct = Math.round(
        (this.scrollOffset / Math.max(1, this.rows.length - this.maxVisible)) *
          100,
      );
      footerParts.push(accent(`${pct}%`));
    }

    // Borders
    const title = accent(" Keybindings Reference ");
    const titlePad = Math.max(0, inner - visibleWidth(title));
    lines.unshift(
      " ".repeat(pad) +
        border("╭─") +
        title +
        border("─".repeat(titlePad)) +
        border("╮"),
    );
    lines.push(
      " ".repeat(pad) + border("├─") + border("─".repeat(inner)) + border("┤"),
    );
    lines.push(" ".repeat(pad) + footerParts.join("  ·  "));
    lines.push(
      " ".repeat(pad) + border("╰─") + border("─".repeat(inner)) + border("╯"),
    );

    const fullLines = lines.map((l) => {
      const vw = visibleWidth(l);
      return vw < width ? l + " ".repeat(width - vw) : l;
    });

    this.cachedLines = fullLines;
    this.cachedWidth = maxWidth;
    this.cachedVersion = this.version;
    return fullLines;
  }
}

// ── Extension Entry ─────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // ── Register /keybinds command ──
  pi.registerCommand("keybinds", {
    description: "Show all Pi keyboard shortcuts in an overlay",
    handler: async (_args: string, ctx: ExtensionContext) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/keybinds requires TUI mode", "error");
        return;
      }

      await ctx.ui.custom(
        (tui, _theme, keybindings, done) => {
          const rows = buildRows(keybindings);
          const maxHeight = Math.min(rows.length + 4, 30);
          return new KeybindsView(tui, rows, maxHeight, () => done(null));
        },
        {
          overlay: true,
          overlayOptions: {
            width: "85%",
            maxHeight: "85%",
            anchor: "center",
            margin: 2,
          },
        },
      );
    },
  });

  // ── Reload command (can be triggered from shortcuts or /ext-reload) ──
  pi.registerCommand("ext-reload", {
    description: "Reload extensions and config",
    handler: async (_args: string, ctx) => {
      await ctx.reload();
    },
  });

  // ── Ctrl+Q → /hotkeys ──
  // Ctrl+K is reserved for tui.editor.deleteToLineEnd.
  // Ctrl+Q has no default binding in Pi.
  pi.registerShortcut(Key.ctrl("q"), {
    description: "Show hotkeys list",
    handler: async (ctx: ExtensionContext) => {
      ctx.ui.setEditorText("/hotkeys");
      pi.sendUserMessage("/hotkeys");
    },
  });

  // ── Alt+R → insert "/reload" in editor ──
  // sendUserMessage bypasses the TUI command pipeline so built-in
  // commands like /reload are never intercepted. Setting editor text
  // gives visual feedback — one Enter press to execute.
  pi.registerShortcut(Key.alt("r"), {
    description: "Insert /reload in editor",
    handler: async (ctx: ExtensionContext) => {
      ctx.ui.setEditorText("/reload");
    },
  });
}
