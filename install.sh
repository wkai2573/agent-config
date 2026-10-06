#!/usr/bin/env bash
# 把本 repo 的 skills 以符號連結裝到 Claude Code / Gemini（Antigravity）。
# 之後只要 git pull，兩邊的 skills 就一起更新。可重複執行。
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="${CLAUDE_DIR:-$HOME/.claude/skills}"
gemini_cfg="${GEMINI_CONFIG:-$HOME/.gemini/config/skills.json}"
backup_dir="${BACKUP_DIR:-$HOME/.claude/skills-backup}"

mkdir -p "$claude_dir"

for d in "$repo"/skills/*/; do
  name="$(basename "$d")"
  link="$claude_dir/$name"
  if [ -L "$link" ]; then
    rm "$link"
  elif [ -e "$link" ]; then
    mkdir -p "$backup_dir"
    bak="$backup_dir/$name.$(date +%Y%m%d%H%M%S)"
    mv "$link" "$bak"
    echo "  已備份既有的 $name -> $bak"
  fi
  ln -s "${d%/}" "$link"
  echo "  已連結 $name"
done

# Gemini（Antigravity）：讓它也讀 ~/.claude/skills
if [ ! -d "$(dirname "$gemini_cfg")" ]; then
  echo "（找不到 $(dirname "$gemini_cfg")，略過 Gemini 設定；之後安裝 Gemini 再重跑本腳本即可）"
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$gemini_cfg" "$claude_dir" <<'PY'
import json, os, sys
cfg, claude = sys.argv[1], sys.argv[2]
data = json.load(open(cfg, encoding="utf-8")) if os.path.exists(cfg) else {"entries": []}
if any(e.get("path") == claude for e in data.get("entries", [])):
    print(f"  Gemini 設定已包含 {claude}，不需變更")
else:
    data.setdefault("entries", []).append({"path": claude, "exclude": ["synced", "generate-image"]})
    with open(cfg, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"  已在 Gemini 設定加入 {claude}")
PY
else
  echo "（找不到 python3，請手動在 $gemini_cfg 的 entries 加入 {\"path\": \"$claude_dir\", \"exclude\": [\"synced\", \"generate-image\"]}）"
fi
echo "完成。重開 Claude Code / Gemini 即可看到 skills。"
