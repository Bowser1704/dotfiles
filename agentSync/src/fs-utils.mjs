import fs from "node:fs";
import fsp from "node:fs/promises";
import os from "node:os";
import path from "node:path";

export const HOME = os.homedir();

export function expandHome(value) {
  if (typeof value !== "string") return value;
  if (value === "~") return HOME;
  if (value.startsWith("~/")) return path.join(HOME, value.slice(2));
  return value;
}

export function resolvePath(value, baseDir = process.cwd()) {
  const expanded = expandHome(value);
  return path.resolve(path.isAbsolute(expanded) ? expanded : path.join(baseDir, expanded));
}

export function exists(file) {
  try {
    fs.lstatSync(file);
    return true;
  } catch (error) {
    if (error?.code === "ENOENT") return false;
    throw error;
  }
}

export function canReadFile(file) {
  try {
    return fs.statSync(file).isFile();
  } catch {
    return false;
  }
}

export async function readJson(file, fallback = undefined) {
  try {
    return JSON.parse(await fsp.readFile(file, "utf8"));
  } catch (error) {
    if (error?.code === "ENOENT" && fallback !== undefined) return fallback;
    throw new Error(`Failed to read JSON ${file}: ${error.message}`);
  }
}

export async function writeJson(file, data, { dryRun = false, log = () => {} } = {}) {
  if (dryRun) {
    log(`dry-run: write ${file}`);
    return;
  }
  await fsp.mkdir(path.dirname(file), { recursive: true });
  await fsp.writeFile(file, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

export function backupPath(file) {
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  return `${file}.backup.${stamp}`;
}

export async function backupFileIfExists(file, { dryRun = false, log = () => {} } = {}) {
  if (!exists(file)) return undefined;
  const backup = backupPath(file);
  if (dryRun) {
    log(`dry-run: backup ${file} -> ${backup}`);
    return backup;
  }
  await fsp.mkdir(path.dirname(backup), { recursive: true });
  await fsp.copyFile(file, backup);
  return backup;
}

export async function replaceWithSymlink(linkPath, targetPath, { force = false, dryRun = false, log = () => {} } = {}) {
  await fsp.mkdir(path.dirname(linkPath), { recursive: true });

  if (exists(linkPath)) {
    const stat = fs.lstatSync(linkPath);
    if (stat.isSymbolicLink()) {
      const current = fs.readlinkSync(linkPath);
      const currentResolved = path.resolve(path.dirname(linkPath), current);
      if (current === targetPath || currentResolved === targetPath) {
        return { changed: false, adopted: true };
      }
      if (!force) return { changed: false, skipped: true, reason: `existing symlink points to ${current}` };
      if (dryRun) log(`dry-run: remove symlink ${linkPath}`);
      else await fsp.unlink(linkPath);
    } else {
      if (!force) return { changed: false, skipped: true, reason: "existing non-symlink path" };
      const backup = backupPath(linkPath);
      if (dryRun) log(`dry-run: move ${linkPath} -> ${backup}`);
      else await fsp.rename(linkPath, backup);
      log(`backed up ${linkPath} -> ${backup}`);
    }
  }

  if (dryRun) log(`dry-run: symlink ${linkPath} -> ${targetPath}`);
  else await fsp.symlink(targetPath, linkPath);
  return { changed: true };
}

export async function removeManagedLink(linkPath, expectedTarget, { dryRun = false, log = () => {} } = {}) {
  if (!exists(linkPath)) return false;
  const stat = fs.lstatSync(linkPath);
  if (!stat.isSymbolicLink()) return false;
  const current = fs.readlinkSync(linkPath);
  const currentResolved = path.resolve(path.dirname(linkPath), current);
  if (current !== expectedTarget && currentResolved !== expectedTarget) return false;
  if (dryRun) log(`dry-run: remove stale managed link ${linkPath}`);
  else await fsp.unlink(linkPath);
  return true;
}

export async function walk(dir, predicate, options = {}) {
  const results = [];
  const { maxDepth = Infinity, depth = 0, skipDir = () => false } = options;
  if (!exists(dir) || depth > maxDepth) return results;
  const entries = await fsp.readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (skipDir(full, entry.name)) continue;
      results.push(...await walk(full, predicate, { ...options, depth: depth + 1 }));
    } else if (entry.isFile() || entry.isSymbolicLink()) {
      if (predicate(full, entry)) results.push(full);
    }
  }
  return results;
}
