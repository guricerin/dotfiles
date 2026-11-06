#!/usr/bin/env bun
/**
 * Claude Code の会話履歴（~/.claude/projects/*\/*.jsonl）から、ハーネスの改善を考える材料を抜き出し、JSON で標準出力に出す。
 *
 * 使い方:
 *     bun extract_history.ts [--since 2026-10-28T09:00] [--days 7]
 *     bun extract_history.ts --mark-done 2026-11-04T15:00:00+09:00
 *
 * - 期間の始まり（since）は、--since 指定 > 前回の実行時刻（STATE_FILE）> 現在から --days 日前、の順で決める
 * - 全プロジェクトの、メインの会話だけを見る（サブエージェントの会話は除く。本人とのやりとりが入っていないため）
 * - 抜き出すのは、本人の発言・拒否されたツール呼び出し・エラーになったツール呼び出し・中断・呼ばれたスキル
 * - --mark-done は、改善案を本人に返し終えたあとに、抽出時の until を前回の実行時刻として保存する
 * - 外部のパッケージは使わない
 */

import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

const PROJECTS_DIR = join(homedir(), ".claude/projects");
const STATE_FILE = join(homedir(), ".claude/state/harness-review/last-run.json");
const TEXT_LIMIT = 400;
const ERROR_LIMIT = 200;
// 履歴に残るが本人の発言ではないもの
const NOISE_RE = /^<(local-command-caveat|local-command-stdout|system-reminder|task-notification)>/;
const COMMAND_RE = /<command-name>(\/[^<]+)<\/command-name>(?:[\s\S]*?<command-args>([\s\S]*?)<\/command-args>)?/;

type Entry = {
  time: string;
  tool?: string;
  input: string;
  by?: "user" | "classifier";
  reason?: string | null;
  error?: string;
};
type Session = {
  file: string;
  cwd: string | null;
  first: string | null;
  last: string | null;
  prompts: { time: string; text: string }[];
  commands: string[];
  rejected: Entry[];
  errors: Entry[];
  interrupts: number;
  skills: string[];
};

function arg(name: string): string | undefined {
  const i = Bun.argv.indexOf(`--${name}`);
  return i >= 0 ? Bun.argv[i + 1] : undefined;
}

// タイムゾーンなしはローカル時刻として読む（日付だけの文字列は JS だと UTC になるため、時刻を足す）
function parseTime(s: string): Date {
  const t = new Date(/^\d{4}-\d{2}-\d{2}$/.test(s) ? `${s}T00:00` : s);
  if (Number.isNaN(t.getTime())) throw new Error(`日時として読めません: ${s}`);
  return t;
}

// 本人が読みやすいよう、UTC ではなくローカル時刻とオフセットで出す
function localIso(t: Date): string {
  const off = -t.getTimezoneOffset();
  const pad = (n: number) => String(Math.trunc(Math.abs(n))).padStart(2, "0");
  const local = new Date(t.getTime() + off * 60000).toISOString().slice(0, 19);
  return `${local}${off >= 0 ? "+" : "-"}${pad(off / 60)}:${pad(off % 60)}`;
}

function clip(s: string, n: number): string {
  s = s.trim();
  return s.length <= n ? s : `${s.slice(0, n)}…`;
}

function textOf(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) return content.filter((b) => b?.type === "text").map((b) => b.text ?? "").join("\n");
  return "";
}

function summarizeInput(input: Record<string, unknown>): string {
  for (const key of ["command", "file_path", "skill", "url", "pattern", "prompt"]) {
    if (key in input) return clip(String(input[key]), TEXT_LIMIT);
  }
  return clip(JSON.stringify(input), TEXT_LIMIT);
}

function resolveSince(now: Date, days: number): [Date, string] {
  const since = arg("since");
  if (since) return [parseTime(since), "--since"];
  if (existsSync(STATE_FILE)) return [parseTime(JSON.parse(readFileSync(STATE_FILE, "utf-8")).last_run), "前回の実行"];
  return [new Date(now.getTime() - days * 86400000), `前回の実行なし（直近 ${days} 日）`];
}

function readSession(path: string, since: Date, until: Date): Session {
  const session: Session = {
    file: path, cwd: null, first: null, last: null, prompts: [], commands: [],
    rejected: [], errors: [], interrupts: 0, skills: [],
  };
  const toolUses = new Map<string, { name: string; input: Record<string, unknown> }>();
  for (const line of readFileSync(path, "utf-8").split("\n")) {
    let d: any;
    try {
      d = JSON.parse(line);
    } catch {
      continue;
    }
    if ((d.type !== "user" && d.type !== "assistant") || d.isSidechain || !d.timestamp) continue;
    const t = new Date(d.timestamp);
    if (t < since || t > until) continue;
    const ts: string = d.timestamp;
    session.cwd ??= d.cwd ?? null;
    session.first ??= ts;
    session.last = ts;
    const content = d.message?.content;

    if (d.type === "assistant") {
      for (const b of Array.isArray(content) ? content : []) {
        if (b.type !== "tool_use") continue;
        toolUses.set(b.id, b);
        if (b.name === "Skill") session.skills.push(b.input?.skill ?? "");
      }
      continue;
    }

    for (const b of Array.isArray(content) ? content : []) {
      if (b.type !== "tool_result" || !b.is_error) continue;
      const use = toolUses.get(b.tool_use_id);
      const entry: Entry = { time: ts, tool: use?.name, input: summarizeInput(use?.input ?? {}) };
      const result = textOf(b.content);
      if (result.includes("doesn't want to proceed")) {
        // 拒否の理由を本人が書いていれば、結果の後ろに付いてくる
        const m = result.match(/the user said:\s*([\s\S]*)/);
        entry.by = "user";
        entry.reason = m ? clip(m[1], TEXT_LIMIT) : null;
        session.rejected.push(entry);
      } else if (result.includes("auto mode classifier")) {
        // auto mode の拒否はエラーと同じ形で返るが、本人の拒否と同じく「やらせたくない操作」の手がかりになる
        const m = result.match(/Reason:\s*(.*?)(?:\. If you have|$)/m);
        entry.by = "classifier";
        entry.reason = m ? clip(m[1], TEXT_LIMIT) : null;
        session.rejected.push(entry);
      } else {
        entry.error = clip(result, ERROR_LIMIT);
        session.errors.push(entry);
      }
    }

    if (d.isMeta) continue;
    const text = textOf(content).trim();
    if (!text || NOISE_RE.test(text)) continue;
    if (text.startsWith("[Request interrupted")) {
      session.interrupts++;
      continue;
    }
    const m = text.match(COMMAND_RE);
    if (m) {
      session.commands.push(clip(`${m[1]} ${m[2] ?? ""}`, TEXT_LIMIT));
      continue;
    }
    session.prompts.push({ time: ts, text: clip(text, TEXT_LIMIT) });
  }
  return session;
}

function main() {
  const markDone = arg("mark-done");
  if (markDone) {
    mkdirSync(dirname(STATE_FILE), { recursive: true });
    const lastRun = localIso(parseTime(markDone));
    writeFileSync(STATE_FILE, JSON.stringify({ last_run: lastRun }));
    console.log(JSON.stringify({ saved: STATE_FILE, last_run: lastRun }));
    return;
  }

  const now = new Date();
  const [since, sinceSource] = resolveSince(now, Number(arg("days") ?? 7));
  const warnings: string[] = [];
  if (since > now) warnings.push("期間の始まりが現在時刻より未来");

  const sessions: Session[] = [];
  for (const project of readdirSync(PROJECTS_DIR)) {
    const dir = join(PROJECTS_DIR, project);
    if (!statSync(dir).isDirectory()) continue;
    for (const name of readdirSync(dir)) {
      if (!name.endsWith(".jsonl")) continue;
      const path = join(dir, name);
      // 更新が期間より前のファイルは中身を読まない（履歴が多いと遅いため）
      if (statSync(path).mtime < since) continue;
      const s = readSession(path, since, now);
      if (s.first) sessions.push(s);
    }
  }
  sessions.sort((a, b) => a.first!.localeCompare(b.first!));

  const skills: Record<string, number> = {};
  for (const s of sessions) for (const name of s.skills) skills[name] = (skills[name] ?? 0) + 1;
  const sum = (f: (s: Session) => number) => sessions.reduce((n, s) => n + f(s), 0);
  console.log(JSON.stringify({
    since: localIso(since),
    since_source: sinceSource,
    until: localIso(now),
    warnings,
    totals: {
      sessions: sessions.length,
      prompts: sum((s) => s.prompts.length),
      rejected: sum((s) => s.rejected.length),
      errors: sum((s) => s.errors.length),
      interrupts: sum((s) => s.interrupts),
      skills,
    },
    projects: [...new Set(sessions.map((s) => s.cwd).filter(Boolean))].sort(),
    sessions,
  }, null, 1));
}

main();
