/**
 * Auto-name sessions based on the first user prompt.
 *
 * When a new session starts without a name, this extension waits for
 * the first agent response to complete, then extracts the first user
 * message and sets it as the session display name (truncated to ~50 chars).
 *
 * Named sessions (/name "foo") are left untouched.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let pending = false;

  pi.on("session_start", async (_event, ctx: ExtensionContext) => {
    // Only auto-name sessions that don't already have a name
    if (!ctx.sessionManager.getSessionName()) {
      pending = true;
    }
  });

  pi.on("agent_settled", async (_event, ctx: ExtensionContext) => {
    if (!pending) return;
    pending = false;

    // Check again — user might have named it manually by now
    if (ctx.sessionManager.getSessionName()) return;

    const entries = ctx.sessionManager.getBranch();

    // Find the first user message with actual content
    for (const entry of entries) {
      if (entry.type === "message" && (entry as any).message?.role === "user") {
        const msg = (entry as any).message;
        let text = "";

        if (typeof msg.content === "string") {
          text = msg.content;
        } else if (Array.isArray(msg.content)) {
          text = msg.content
            .filter((c: any) => c.type === "text")
            .map((c: any) => c.text)
            .join(" ");
        }

        const name = text.trim().slice(0, 50).replace(/\s+/g, " ").trim();
        if (name && name.length > 3) {
          pi.setSessionName(name);
        }
        break;
      }
    }
  });
}
