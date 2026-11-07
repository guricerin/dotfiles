#!/usr/bin/env bun
/**
 * news-digest が書き出した Markdown のまとめを、ブラウザで読むためのローカルサーバー。
 *
 * 使い方:
 *     bun serve_news.ts [--dir <まとめのフォルダ>] [--port 8765]
 *
 * - 127.0.0.1 だけで待ち受ける。外のマシンからは接続できない
 * - 左に まとめの一覧（新しい順）、右に選んだまとめの本文を表示する。一覧はリクエストのたびに読み直す
 * - まとめの中身はフィードの文章から来ているので、生の HTML は表示せず文字として出し、
 *   リンクは http・https・mailto だけを有効にする。ページではスクリプトを一切動かさない
 * - Markdown の変換には marked を使う。Bun の自動インストールで読み込むので、node_modules は作らない
 */

import { Marked } from "marked@18.0.14";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const FILENAME_RE = /^(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})(?:-([a-z0-9_-]+))?\.md$/;
const DEFAULT_DIR = join(homedir(), "workspace/github.com/guricerin/pkb/news/output");
const SAFE_PROTOCOLS = new Set(["http:", "https:", "mailto:"]);

function arg(name: string, fallback: string): string {
  const i = Bun.argv.indexOf(`--${name}`);
  return i >= 0 && Bun.argv[i + 1] ? Bun.argv[i + 1] : fallback;
}

const dir = arg("dir", DEFAULT_DIR).replace(/^~(?=\/|$)/, homedir());
const port = Number(arg("port", "8765"));

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);
}

function safeHref(href: string): string | null {
  try {
    return SAFE_PROTOCOLS.has(new URL(href).protocol) ? href : null;
  } catch {
    return null; // 相対パスや壊れた URL はリンクにしない
  }
}

const marked = new Marked({
  gfm: true,
  renderer: {
    // 生の HTML は実行させず、そのまま文字として見せる
    html({ text }) {
      return escapeHtml(text);
    },
    link({ href, title, tokens }) {
      const label = this.parser.parseInline(tokens);
      const safe = safeHref(href);
      if (!safe) return label;
      const t = title ? ` title="${escapeHtml(title)}"` : "";
      return `<a href="${escapeHtml(safe)}"${t} target="_blank" rel="noopener noreferrer">${label}</a>`;
    },
    // 外部の画像を勝手に読み込まないよう、画像はリンクとして出す
    image({ href, text }) {
      const safe = safeHref(href);
      return safe ? `<a href="${escapeHtml(safe)}" target="_blank" rel="noopener noreferrer">[画像] ${escapeHtml(text)}</a>` : escapeHtml(text);
    },
  },
});

type Digest = { name: string; title: string; time: number };

function listDigests(): Digest[] {
  let names: string[];
  try {
    names = readdirSync(dir);
  } catch {
    return [];
  }
  const digests: Digest[] = [];
  for (const name of names) {
    const m = FILENAME_RE.exec(name);
    if (!m || !statSync(join(dir, name)).isFile()) continue;
    const [y, mo, d, h, mi] = m.slice(1, 6).map(Number);
    const firstLine = readFileSync(join(dir, name), "utf-8").split("\n", 1)[0];
    const title = firstLine.startsWith("# ") ? firstLine.slice(2).trim() : name;
    digests.push({ name, title, time: new Date(y, mo - 1, d, h, mi).getTime() });
  }
  return digests.sort((a, b) => b.time - a.time || b.name.localeCompare(a.name));
}

function page(digests: Digest[], current: Digest | undefined): string {
  const items = digests
    .map((d) => {
      const cls = d.name === current?.name ? ' class="current"' : "";
      return `<li${cls}><a href="/?f=${encodeURIComponent(d.name)}">${escapeHtml(d.title)}</a></li>`;
    })
    .join("\n");
  const body = current
    ? marked.parse(readFileSync(join(dir, current.name), "utf-8"))
    : `<p>まとめがありません（${escapeHtml(dir)}）</p>`;
  return `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(current?.title ?? "ニュースまとめ")}</title>
<style>
  :root { --bg: #fff; --fg: #1f2328; --muted: #59636e; --line: #d1d9e0; --side: #f6f8fa; --link: #0969da; --cur: #ddf4ff; }
  @media (prefers-color-scheme: dark) {
    :root { --bg: #0d1117; --fg: #e6edf3; --muted: #9198a1; --line: #3d444d; --side: #151b23; --link: #4493f8; --cur: #1f2d3d; }
  }
  * { box-sizing: border-box; }
  body { margin: 0; display: flex; min-height: 100vh; background: var(--bg); color: var(--fg);
    font: 15px/1.7 -apple-system, BlinkMacSystemFont, "Hiragino Sans", "Noto Sans JP", sans-serif; }
  nav { width: 300px; flex-shrink: 0; background: var(--side); border-right: 1px solid var(--line);
    position: sticky; top: 0; height: 100vh; overflow-y: auto; padding: 16px 0; }
  nav h2 { font-size: 13px; color: var(--muted); margin: 0 16px 8px; }
  nav ul { list-style: none; margin: 0; padding: 0; }
  nav li a { display: block; padding: 6px 16px; font-size: 13px; color: var(--fg); text-decoration: none; }
  nav li a:hover { background: var(--cur); }
  nav li.current a { background: var(--cur); font-weight: 600; }
  main { flex: 1; min-width: 0; max-width: 960px; padding: 24px 40px 80px; }
  a { color: var(--link); }
  h1 { font-size: 26px; border-bottom: 1px solid var(--line); padding-bottom: 8px; }
  h2 { font-size: 20px; border-bottom: 1px solid var(--line); padding-bottom: 4px; margin-top: 36px; }
  h3 { font-size: 16px; margin-top: 24px; }
  li { margin: 4px 0; }
  code { font-size: 90%; background: var(--side); padding: 1px 5px; border-radius: 4px; }
  table { border-collapse: collapse; } th, td { border: 1px solid var(--line); padding: 4px 10px; }
  @media (max-width: 760px) { body { display: block; } nav { width: auto; height: auto; position: static; max-height: 40vh; } main { padding: 16px; } }
</style>
</head>
<body>
<nav><h2>まとめ一覧</h2><ul>
${items}
</ul></nav>
<main>
${body}
</main>
</body>
</html>`;
}

const server = Bun.serve({
  hostname: "127.0.0.1",
  port,
  fetch(req) {
    const url = new URL(req.url);
    if (url.pathname !== "/") return new Response("Not Found", { status: 404 });
    const digests = listDigests();
    const requested = url.searchParams.get("f");
    // 一覧にあるファイル名だけを受け付ける（パスの指定で別のファイルを読ませないため）
    const current = requested ? digests.find((d) => d.name === requested) : digests[0];
    if (requested && !current) return new Response("Not Found", { status: 404 });
    return new Response(page(digests, current), {
      headers: {
        "content-type": "text/html; charset=utf-8",
        "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'",
        "referrer-policy": "no-referrer",
      },
    });
  },
});

console.log(`ニュースまとめ: http://${server.hostname}:${server.port}/ （${dir}）`);
