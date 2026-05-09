/**
 * Bash output filter - trim noisy content before it reaches the LLM context
 *
 * Inspired by Mario Zechner's "Structured Split Tool Results" concept:
 * the UI still shows full output, but the LLM only sees what matters.
 *
 * Filters: apt progress, download progress bars, verbose warnings,
 * repeated lines, and other noise that wastes tokens.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isBashToolResult } from "@earendil-works/pi-coding-agent";

// Patterns that indicate noise lines
const NOISE_PATTERNS = [
	// apt/apt-get progress and status
	/^Reading package lists/,
	/^Building dependency tree/,
	/^Reading state information/,
	/^Need to get/,
	/^Fetched/,
	/^Get:\d+/,
	/^Ign:\d+/,
	/^Hit:\d+/,
	/^Processing triggers/,
	/^Selecting previously unselected/,
	/^Preparing to unpack/,
	/^Unpacking/,
	/^Setting up/,
	/^dpkg: processing/,
	/^E: /, // apt errors kept, but these are often just warnings
	/^W: /, // apt warnings
	/^N: /, // apt notices

	// Download progress bars (curl, wget, pip, etc.)
	/\d+%.*\|.*\|/, // [===   ] 45% progress bars
	/^\s*\d+\s*\d+[kMG]?B\s*\d+[kMG]?B/, // wget-style progress
	/^Collecting /,
	/^Using cached /,
	/^Downloading /,
	/^Installing collected packages/,
	/^Successfully installed/,
	/^Requirement already satisfied/,
	/^Downloading .*\.whl/,

	// npm/yarn noise
	/^npm warn/,
	/^added \d+ packages/,
	/^removed \d+ packages/,
	/^changed \d+ packages/,

	// make/build verbose noise (keep errors)
	/^make\[\d+\]: Entering directory/,
	/^make\[\d+\]: Leaving directory/,
	/^make\[\d+\]: Nothing to be done/,

	// Docker pull progress
	/^Pulling from/,
	/^Digest:/,
	/^Status:/,
	/^Downloaded newer image/,
	/^Image already exists/,

	// Git verbose noise
	/^remote: Counting objects/,
	/^remote: Compressing objects/,
	/^Receiving objects/,
	/^Resolving deltas/,
	/^Enumerating objects/,
	/^Counting objects/,
	/^Compressing objects/,
	/^Delta compression/,

	// kubectl verbose noise (keep actual output)
	/^I\d{4}\s+\d{2}:\d{2}:\d{2}/, // kubectl info-level logs (keep errors and warnings)
	/^deployment\.apps\/.*scaled/, // kubectl scale confirmations

	// rsync progress
	/^sending incremental file list/,
	/^total size is/,
	/^sent\s+\d+.*received\s+\d+/,

	// General progress indicators
	/^\[=+\s*\]/, // generic progress bars
	/^#=/, // conda-style progress
	/^Progress:/,
	/^Progress made/,
];

// Consecutive identical lines (beyond threshold) → keep first + last + summary
function deduplicateConsecutiveLines(lines: string[]): string[] {
	const result: string[] = [];
	let prev = "";
	let repeatCount = 0;

	for (const line of lines) {
		if (line === prev) {
			repeatCount++;
			if (repeatCount === 2) {
				// Mark that we're skipping duplicates
				result.push(`... (${repeatCount} identical lines omitted) ...`);
			} else if (repeatCount > 2) {
				// Update the count in the last placeholder
				const lastIdx = result.length - 1;
				result[lastIdx] = `... (${repeatCount} identical lines omitted) ...`;
			}
		} else {
			repeatCount = 0;
			prev = line;
			result.push(line);
		}
	}

	return result;
}

function isNoise(line: string): boolean {
	return NOISE_PATTERNS.some((p) => p.test(line));
}

function filterBashOutput(text: string): string {
	const lines = text.split("\n");
	const filtered = lines.filter((line) => !isNoise(line));
	const deduped = deduplicateConsecutiveLines(filtered);

	// If we filtered almost everything, at least keep error lines and last few lines
	if (deduped.length === 0 && lines.length > 0) {
		const errors = lines.filter((l) => /^(error|Error|ERROR|fatal|FAILED|Traceback)/.test(l));
		const tail = lines.slice(-5);
		return [...errors, ...tail.filter((l) => !errors.includes(l))].join("\n");
	}

	// If still very long, keep head + tail
	if (deduped.length > 100) {
		const head = deduped.slice(0, 30);
		const tail = deduped.slice(-20);
		const omitted = deduped.length - head.length - tail.length;
		return [...head, `... (${omitted} lines omitted) ...`, ...tail].join("\n");
	}

	return deduped.join("\n");
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_result", async (event, ctx) => {
		if (!isBashToolResult(event)) return;

		const textBlocks = event.content.filter(
			(c): c is { type: "text"; text: string } => c.type === "text",
		);

		if (textBlocks.length === 0) return;

		// Only filter non-error results (keep full error output for debugging)
		if (event.isError) return;

		const totalText = textBlocks.map((c) => c.text).join("\n");
		const filteredText = filterBashOutput(totalText);

		// Only replace if we actually reduced content significantly (>20% reduction)
		if (filteredText.length >= totalText.length * 0.8) return;

		const newContent = event.content.map((c) =>
			c.type === "text" ? { ...c, text: filteredText } : c,
		);

		return { content: newContent };
	});
}