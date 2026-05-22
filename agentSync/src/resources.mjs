import fsp from "node:fs/promises";
import path from "node:path";
import {
  exists,
  readJson,
  walk,
  writeJson,
} from "./fs-utils.mjs";

function parseFrontmatter(text) {
  if (!text.startsWith("---\n")) return {};
  const end = text.indexOf("\n---", 4);
  if (end === -1) return {};
  const result = {};
  for (const line of text.slice(4, end).split("\n")) {
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) continue;
    let value = match[2].trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1, -1);
    if (value === "true") result[match[1]] = true;
    else if (value === "false") result[match[1]] = false;
    else result[match[1]] = value;
  }
  return result;
}

async function getSkillMeta(skillFile, fallbackName) {
  const text = await fsp.readFile(skillFile, "utf8");
  const fm = parseFrontmatter(text);
  return {
    name: typeof fm.name === "string" && fm.name ? fm.name : fallbackName,
    description: typeof fm.description === "string" ? fm.description : "",
    disableModelInvocation: fm["disable-model-invocation"] === true || fm["disable-model-invocation"] === "true",
  };
}

async function discoverSkillDirs(root) {
  if (!exists(root)) return [];
  const skillFiles = await walk(root, (full) => path.basename(full) === "SKILL.md", {
    skipDir: (_full, name) => [".git", "node_modules", ".disabled"].includes(name),
  });
  const skills = [];
  for (const skillFile of skillFiles) {
    const dir = path.dirname(skillFile);
    const meta = await getSkillMeta(skillFile, path.basename(dir));
    if (!meta.name || meta.disableModelInvocation) continue;
    skills.push({ name: meta.name, dir, skillFile, description: meta.description });
  }
  return skills;
}

async function discoverPromptFiles(root) {
  if (!exists(root)) return [];
  const entries = await fsp.readdir(root, { withFileTypes: true });
  return entries.filter((entry) => entry.isFile() && entry.name.endsWith(".md")).map((entry) => path.join(root, entry.name));
}

export async function discoverResources(cfg) {
  const desiredSkills = new Map();
  const desiredPrompts = new Map();

  const allSkillDirs = [...(cfg.resources.skillDirs || []), ...(cfg.resources.extraSkillDirs || [])];
  for (const skillDir of allSkillDirs) {
    for (const skill of await discoverSkillDirs(skillDir)) {
      desiredSkills.set(skill.name, { ...skill, source: skillDir });
    }
  }

  for (const promptDir of cfg.resources.promptDirs || []) {
    for (const file of await discoverPromptFiles(promptDir)) {
      const name = path.basename(file, ".md");
      desiredPrompts.set(name, { name, file, source: promptDir });
    }
  }

  return { skills: desiredSkills, prompts: desiredPrompts };
}

export async function loadManifest(cfg) {
  return readJson(cfg.manifestPath, { version: 1, managedBy: "agentSync", links: {} });
}

export async function writeManifest(cfg, manifest, opts = {}) {
  await writeJson(cfg.manifestPath, manifest, opts);
}
