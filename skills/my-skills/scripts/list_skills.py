#!/usr/bin/env python3
"""精簡列出「自己放進去的」skills：一行一個，指令加用途。

只掃兩個位置的第一層資料夾：
  1. 個人：~/.claude/skills/<名稱>/SKILL.md
  2. 專案：<目前目錄>/.claude/skills/<名稱>/SKILL.md

不掃外掛、官方同步的 skills（~/.claude/skills/synced 等子資料夾裡的不算）。
清單之後會接著印出 ../guide.md（建議用法）。

用法：
  python list_skills.py            列出清單與建議用法，所有 /指令 都是連結（連到該 skill 的 SKILL.md）
  python list_skills.py --show 名稱  直接印出該 skill 的 SKILL.md 全文
"""
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def parse_frontmatter(text):
    """極簡 frontmatter 解析，只取 name / description。"""
    m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.S)
    if not m:
        return {}
    lines = m.group(1).splitlines()
    data, i = {}, 0
    while i < len(lines):
        km = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", lines[i])
        if not km:
            i += 1
            continue
        key, val = km.group(1), km.group(2).strip()
        if val in (">", "|", ">-", "|-"):
            block = []
            i += 1
            while i < len(lines) and (lines[i].startswith(" ") or not lines[i].strip()):
                block.append(lines[i].strip())
                i += 1
            data[key] = " ".join(b for b in block if b)
            continue
        if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
            val = val[1:-1]
        data[key] = val
        i += 1
    return data


def short(desc, limit=36):
    desc = re.sub(r"\s+", " ", desc).strip()
    m = re.search(r"[。！!]|\.\s", desc)  # 取第一句
    if m:
        desc = desc[: m.start()]
    return desc if len(desc) <= limit else desc[: limit - 1] + "…"


def collect(root):
    out = []
    if not root.is_dir():
        return out
    for path in sorted(root.glob("*/SKILL.md")):  # 只看第一層
        try:
            fm = parse_frontmatter(path.read_text(encoding="utf-8", errors="replace"))
        except OSError:
            continue
        out.append((fm.get("name") or path.parent.name, short(fm.get("description", "")), path))
    return out


def linkify(text, groups):
    """把文字中的 /skill名稱 換成連結（只處理已安裝的 skill，其他如 /clear 不動）。"""
    uris = {name: path.resolve().as_uri() for _, items in groups for name, _, path in items}

    def repl(m):
        name = m.group(1)
        return f"[/{name}]({uris[name]})" if name in uris else m.group(0)

    return re.sub(r"(?<![\w/.\]\[])/([a-z][a-z0-9-]*)", repl, text)


def show(groups, target):
    target = target.lstrip("/")
    for _, items in groups:
        for name, _, path in items:
            if name == target:
                print(path.read_text(encoding="utf-8", errors="replace").rstrip())
                return
    print(f"找不到 /{target}")


def main():
    groups = [
        ("個人", collect(Path.home() / ".claude" / "skills")),
        ("專案", collect(Path.cwd() / ".claude" / "skills")),
    ]
    groups = [(label, items) for label, items in groups if items]
    if len(sys.argv) >= 3 and sys.argv[1] == "--show":
        show(groups, sys.argv[2])
        return
    if not groups:
        print("沒有找到你自己的 skills。")
        return
    out = []
    for label, items in groups:
        out.append(f"{label}（{len(items)}）")
        for name, desc, path in sorted(items, key=lambda x: x[0].lower()):
            out.append(f"[/{name}]({path.resolve().as_uri()})  {desc}")
        out.append("")
    # 建議用法：放在 my-skills/guide.md，想改直接編輯那個檔案
    guide = Path(__file__).resolve().parent.parent / "guide.md"
    if guide.is_file():
        out.extend(linkify(guide.read_text(encoding="utf-8").rstrip(), groups).splitlines())
    # 行尾加兩個空白＝Markdown 強制換行，讓只認段落的 Markdown 渲染器（如 Gemini）也能分行
    print("\n".join(l + "  " if l.strip() else l for l in out))


if __name__ == "__main__":
    main()
