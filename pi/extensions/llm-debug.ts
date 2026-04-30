/**
 * LLM Debug Extension
 *
 * 每个 session 存一个结构化 JSON 文件到 ~/.pi/agent/llm-debug/
 * 配合 llm-debug-viewer.html 查看。
 *
 * 使用方式：
 *   PI_DEBUG_LLM=1 pi
 *   然后用 llm-debug-viewer.html 打开对应的 JSON 文件
 */

import { mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const ENABLED = process.env.PI_DEBUG_LLM === "1";
const LOG_DIR = join(homedir(), ".pi", "agent", "llm-debug");

type DebugEvent =
  | { type: "request";           timestamp: string; turnIndex: number; payload: unknown }
  | { type: "response_headers";  timestamp: string; turnIndex: number; status: number; headers: unknown }
  | { type: "assistant_message"; timestamp: string; turnIndex: number; message: unknown }
  | { type: "tool_result";       timestamp: string; turnIndex: number; toolName: string; toolCallId: string; result: unknown }
  | { type: "turn_end";          timestamp: string; turnIndex: number };

interface SessionLog {
  sessionId: string;
  sessionFile: string | undefined;
  startedAt: string;
  events: DebugEvent[];
}

export default function (pi: ExtensionAPI) {
  if (!ENABLED) return;

  mkdirSync(LOG_DIR, { recursive: true });

  let logFile: string | undefined;
  let sessionLog: SessionLog | undefined;
  let currentTurn = 0;

  function save() {
    if (!logFile || !sessionLog) return;
    writeFileSync(logFile, JSON.stringify(sessionLog, null, 2), "utf8");
  }

  function push(event: DebugEvent) {
    if (!sessionLog) return;
    sessionLog.events.push(event);
    save();
  }

  function initSession(ctx: { sessionManager: { getSessionFile(): string | undefined; getSessionId(): string | undefined } }) {
    const sessionFile = ctx.sessionManager.getSessionFile();
    const sessionId = ctx.sessionManager.getSessionId() ?? `unknown-${Date.now()}`;

    // 如果已经是同一个 session 就不重复初始化
    if (sessionLog?.sessionId === sessionId) return;

    const ts = new Date().toISOString().replace(/[:.]/g, "-");
    const fileName = `${ts}_${sessionId.slice(0, 8)}.json`;
    logFile = join(LOG_DIR, fileName);

    sessionLog = {
      sessionId,
      sessionFile,
      startedAt: new Date().toISOString(),
      events: [],
    };

    save();
  }

  pi.on("session_start", (_event, ctx) => {
    initSession(ctx);
  });

  pi.on("session_switch", (_event, ctx) => {
    initSession(ctx);
  });

  pi.on("turn_start", (event) => {
    currentTurn = event.turnIndex ?? 0;
  });

  pi.on("before_provider_request", (event, ctx) => {
    if (!sessionLog) initSession(ctx);
    push({ type: "request", timestamp: new Date().toISOString(), turnIndex: currentTurn, payload: event.payload });
  });

  pi.on("after_provider_response", (event) => {
    push({ type: "response_headers", timestamp: new Date().toISOString(), turnIndex: currentTurn, status: event.status, headers: event.headers });
  });

  pi.on("message_end", (event) => {
    const msg = event.message as { role?: string };
    if (msg.role !== "assistant") return;
    push({ type: "assistant_message", timestamp: new Date().toISOString(), turnIndex: currentTurn, message: event.message });
  });

  pi.on("tool_execution_end", (event) => {
    push({ type: "tool_result", timestamp: new Date().toISOString(), turnIndex: currentTurn, toolName: event.toolName, toolCallId: event.toolCallId, result: event.result });
  });

  pi.on("turn_end", (event) => {
    push({ type: "turn_end", timestamp: new Date().toISOString(), turnIndex: event.turnIndex ?? currentTurn });
  });
}
