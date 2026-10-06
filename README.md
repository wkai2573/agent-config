# my-global-skills

我的 Claude Code 與 Gemini（Antigravity）全域 skills 備份，附一鍵同步腳本。

## 內容

| 路徑 | 說明 |
| --- | --- |
| `skills/` | 13 個自訂 skills（Claude Code 的 `~/.claude/skills`） |
| `gemini/skills.json` | Gemini 的 skills 設定參考（它讀的就是 `~/.claude/skills`，所以兩邊共用同一份） |
| `install.ps1` / `install.sh` | 新電腦安裝：把 skills 連結到 `~/.claude/skills` 並設定 Gemini |
| `export.ps1` | 原始電腦用：把本機改過的 skills 複製回 repo |

不收錄：`synced/`（Claude 官方雲端同步的 skills，登入帳號會自動出現）、`.trash/`。
`generate-image` 在 Gemini 端被排除（Gemini 自己會生圖，這個 skill 只給 Claude 用）。

## 在新電腦同步（Windows）

```powershell
git clone https://github.com/wkai2573/my-global-skills.git $HOME\my-global-skills
& $HOME\my-global-skills\install.ps1
```

## 在新電腦同步（macOS / Linux / WSL）

```bash
git clone https://github.com/wkai2573/my-global-skills.git ~/my-global-skills
bash ~/my-global-skills/install.sh
```

腳本做的事：

1. 把 `skills/*` 每個資料夾連結（Windows 用 junction，不需管理員權限）到 `~/.claude/skills/`。
2. 若該位置已有同名真實資料夾，先備份到 `~/.claude/skills-backup/`，不會直接覆蓋。
3. 若有安裝 Gemini，在 `~/.gemini/config/skills.json` 補上指向 `~/.claude/skills` 的設定（已有就不動）。

可重複執行；重開 Claude Code / Gemini 後生效。

## 日常更新

**其他電腦取得最新版**（因為是連結，pull 完就生效）：

```bash
git -C ~/my-global-skills pull
```

**在原始電腦改了 skill 要推上去**：

```powershell
cd $HOME\my-global-skills        # 或你 clone 的位置
.\export.ps1                     # 把本機改動複製回 repo
git add -A; git commit -m "更新 skills"; git push
```

如果某台電腦已經用 `install` 裝成連結，直接編輯 `~/.claude/skills/<名稱>` 就是改 repo 裡的檔案，這時不用跑 `export.ps1`，直接 commit / push 即可。

## 注意

- 新增 skill：在 `skills/` 下建資料夾（含 `SKILL.md`），重跑一次 `install` 才會建立連結。
- 這是私有 repo；若要改公開，先確認 skills 內沒有私人資訊。
