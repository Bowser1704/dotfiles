/**
 * Memory Extension for pi coding agent
 *
 * Two-tier persistent memory, modeled after Claude Code:
 *
 *   Global:  ~/.pi/agent/MEMORY.md         — injected in every session
 *   Project: <cwd>/AGENTS.memory.md        — injected only for this project
 *
 * The LLM decides scope automatically:
 *   - General preferences / habits / tool choices → global
 *   - Project-specific decisions / conventions / constraints → project
 *
 * Features:
 *   - Auto-injects both memory files into system prompt every turn
 *   - `remember` tool: LLM saves a fact, picks scope by context
 *   - `/memory [global|project|edit-global|edit-project|clear-global|clear-project]`
 *   - Auto-extracts facts at agent_end (debounced) and at compaction
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { complete } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { convertToLlm, serializeConversation } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

// ─── paths ────────────────────────────────────────────────────────────────────

function globalMemoryPath(): string {
	return path.join(os.homedir(), ".pi", "agent", "MEMORY.md");
}

function projectMemoryPath(cwd: string): string {
	return path.join(cwd, "AGENTS.memory.md");
}

// ─── file helpers ─────────────────────────────────────────────────────────────

function readMemory(filePath: string): string {
	if (!fs.existsSync(filePath)) return "";
	return fs.readFileSync(filePath, "utf-8").trim();
}

function writeMemory(filePath: string, content: string): void {
	const dir = path.dirname(filePath);
	if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
	fs.writeFileSync(filePath, content.trim() + "\n", "utf-8");
}

/** Append one bullet. Returns "added" or "duplicate". */
function appendFact(filePath: string, fact: string): "added" | "duplicate" {
	const existing = readMemory(filePath);
	const normalized = fact.trim().replace(/^[-*]\s*/, "");
	if (existing.toLowerCase().includes(normalized.toLowerCase())) return "duplicate";
	const updated = existing ? `${existing}\n- ${normalized}` : `- ${normalized}`;
	writeMemory(filePath, updated);
	return "added";
}

function openInEditor(filePath: string): void {
	if (!fs.existsSync(filePath)) writeMemory(filePath, "");
	const editor = process.env.EDITOR || process.env.VISUAL || "vi";
	const { execSync } = require("node:child_process");
	execSync(`${editor} "${filePath}"`, { stdio: "inherit" });
}

// ─── extraction prompt ────────────────────────────────────────────────────────

function buildExtractionPrompt(
	conversationText: string,
	projectName: string,
	existingGlobal: string,
	existingProject: string,
): string {
	return `You are a memory extractor for an AI coding assistant.

Analyze the conversation and extract facts worth remembering long-term.
Classify each fact as either "global" or "project".

Rules:
  global  — user preferences, habits, tool choices, communication style (apply to ALL projects)
  project — conventions, architecture decisions, constraints specific to "${projectName}"

Skip:
  - Temporary task details ("fix bug X today")
  - Facts already listed below
  - Anything obvious or trivial

Already in global memory (skip duplicates):
${existingGlobal || "(none)"}

Already in project memory (skip duplicates):
${existingProject || "(none)"}

Conversation:
<conversation>
${conversationText.slice(0, 28000)}
</conversation>

Return ONLY valid JSON in this shape (both arrays may be empty):
{
  "global": ["fact 1", "fact 2"],
  "project": ["fact A", "fact B"]
}
Max 120 chars per fact. No explanations outside the JSON.`;
}

// ─── extension ────────────────────────────────────────────────────────────────

export default function memoryExtension(pi: ExtensionAPI) {
	let cwd = process.cwd();
	let lastExtractionBranchLen = 0;

	pi.on("session_start", (_event, ctx) => {
		cwd = ctx.cwd;
		lastExtractionBranchLen = 0;
	});

	// ── inject both memory files into every turn ──────────────────────────────
	pi.on("before_agent_start", (event) => {
		const globalMem = readMemory(globalMemoryPath());
		const projectMem = readMemory(projectMemoryPath(cwd));

		if (!globalMem && !projectMem) return;

		let addition = "\n";

		if (globalMem) {
			addition += `## 🌐 Global Memory (your preferences across all projects)\n\n${globalMem}\n\n`;
		}
		if (projectMem) {
			const projectName = path.basename(cwd);
			addition += `## 📁 Project Memory [${projectName}]\n\n${projectMem}\n\n`;
		}

		addition += `---\nTo save a new fact, use the \`remember\` tool.`;

		return { systemPrompt: event.systemPrompt + addition };
	});

	// ── remember tool ─────────────────────────────────────────────────────────
	pi.registerTool({
		name: "remember",
		label: "Remember",
		description: `Save a fact to persistent memory (survives across sessions).

Scope rules — pick automatically based on content:
  "global"  → user preferences, habits, tool choices that apply to ALL projects
  "project" → conventions, decisions, constraints specific to the CURRENT project

Call this when the user says "remember…", "note that…", or shares something worth keeping long-term.
One fact per call. Be concise and self-contained.`,
		parameters: Type.Object({
			fact: Type.String({
				description: "Concise, self-contained fact (max ~120 chars). E.g. 'User prefers 2-space indent in TypeScript'.",
			}),
			scope: Type.Union([Type.Literal("global"), Type.Literal("project")], {
				description: "'global' → ~/.pi/agent/MEMORY.md  |  'project' → <cwd>/AGENTS.memory.md",
			}),
		}),
		async execute(_id, params, _signal, _onUpdate, ctx) {
			const targetPath =
				params.scope === "global"
					? globalMemoryPath()
					: projectMemoryPath(ctx.cwd);

			const result = appendFact(targetPath, params.fact);

			if (result === "duplicate") {
				return {
					content: [{ type: "text", text: `ℹ️ Already remembered: "${params.fact}"` }],
					details: { status: "duplicate" },
				};
			}
			return {
				content: [{ type: "text", text: `✅ Remembered (${params.scope}): "${params.fact}"\n→ ${targetPath}` }],
				details: { status: "added", scope: params.scope, path: targetPath },
			};
		},
	});

	// ── /memory command ───────────────────────────────────────────────────────
	pi.registerCommand("memory", {
		description:
			"Manage persistent memory.\n" +
			"  /memory                  — show both global and project memory\n" +
			"  /memory global           — show global memory\n" +
			"  /memory project          — show project memory\n" +
			"  /memory edit-global      — edit global memory in $EDITOR\n" +
			"  /memory edit-project     — edit project memory in $EDITOR\n" +
			"  /memory clear-global     — clear global memory\n" +
			"  /memory clear-project    — clear project memory",
		handler: async (args, ctx) => {
			const sub = args?.trim().toLowerCase() ?? "";
			const gPath = globalMemoryPath();
			const pPath = projectMemoryPath(ctx.cwd);

			if (sub === "edit-global") {
				openInEditor(gPath);
				ctx.ui.notify("Global memory saved", "info");
				return;
			}
			if (sub === "edit-project") {
				openInEditor(pPath);
				ctx.ui.notify("Project memory saved", "info");
				return;
			}
			if (sub === "clear-global") {
				const ok = await ctx.ui.confirm("Clear global memory?", gPath);
				if (ok) { writeMemory(gPath, ""); ctx.ui.notify("Global memory cleared", "info"); }
				return;
			}
			if (sub === "clear-project") {
				const ok = await ctx.ui.confirm("Clear project memory?", pPath);
				if (ok) { writeMemory(pPath, ""); ctx.ui.notify("Project memory cleared", "info"); }
				return;
			}

			// Show global / project / both
			const showGlobal = sub === "" || sub === "global";
			const showProject = sub === "" || sub === "project";
			const lines: string[] = [];

			if (showGlobal) {
				const mem = readMemory(gPath);
				lines.push(`🌐 Global memory — ${gPath}`);
				lines.push(mem || "  (empty)");
			}
			if (showProject) {
				const mem = readMemory(pPath);
				const name = path.basename(ctx.cwd);
				lines.push(`📁 Project memory [${name}] — ${pPath}`);
				lines.push(mem || "  (empty)");
			}

			ctx.ui.notify(lines.join("\n\n"), "info");
		},
	});

	// ── shared extraction ─────────────────────────────────────────────────────
	async function extractMemories(ctx: any, reason: string) {
		const branch = ctx.sessionManager.getBranch();
		if (branch.length - lastExtractionBranchLen < 4) return;

		const model =
			ctx.modelRegistry.find("anthropic", "claude-haiku-4-5") ??
			ctx.modelRegistry.find("anthropic", "claude-3-5-haiku-20241022") ??
			ctx.modelRegistry.find("openai", "gpt-5.4-mini") ??
			ctx.modelRegistry.find("google", "gemini-2.5-flash");

		if (!model) return;

		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
		if (!auth.ok || !auth.apiKey) return;

		const gPath = globalMemoryPath();
		const pPath = projectMemoryPath(cwd);
		const projectName = path.basename(cwd);

		const conversationText = serializeConversation(convertToLlm(branch as any));

		try {
			const response = await complete(
				model,
				{
					messages: [{
						role: "user",
						content: [{
							type: "text",
							text: buildExtractionPrompt(
								conversationText,
								projectName,
								readMemory(gPath),
								readMemory(pPath),
							),
						}],
						timestamp: Date.now(),
					}],
				},
				{ apiKey: auth.apiKey, headers: auth.headers, maxTokens: 1024 },
			);

			const text = response.content
				.filter((c): c is { type: "text"; text: string } => c.type === "text")
				.map((c) => c.text)
				.join("");

			const match = text.match(/\{[\s\S]*\}/);
			if (!match) return;

			const { global: globalFacts = [], project: projectFacts = [] } = JSON.parse(match[0]) as {
				global?: string[];
				project?: string[];
			};

			let added = 0;
			for (const fact of globalFacts) {
				if (typeof fact === "string" && appendFact(gPath, fact) === "added") added++;
			}
			for (const fact of projectFacts) {
				if (typeof fact === "string" && appendFact(pPath, fact) === "added") added++;
			}

			lastExtractionBranchLen = branch.length;

			if (added > 0) {
				const breakdown = [
					globalFacts.length ? `${globalFacts.filter(f => typeof f === "string").length} global` : "",
					projectFacts.length ? `${projectFacts.filter(f => typeof f === "string").length} project` : "",
				].filter(Boolean).join(", ");
				ctx.ui.notify(`Memory (${reason}): +${added} fact${added > 1 ? "s" : ""} (${breakdown})`, "info");
			}
		} catch {
			// Silent — best-effort
		}
	}

	// ── auto-extract at agent_end (debounced) ─────────────────────────────────
	pi.on("agent_end", async (_event, ctx) => {
		extractMemories(ctx, "auto").catch(() => {});
	});

	// ── auto-extract at compaction ────────────────────────────────────────────
	pi.on("session_before_compact", async (_event, ctx) => {
		extractMemories(ctx, "compaction").catch(() => {});
	});
}
