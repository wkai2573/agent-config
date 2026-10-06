---
name: generate-image
description: 生圖／畫圖／產生圖片／做插圖、頭像、桌布、海報素材、icon 等任何「要一張圖」的需求。使用使用者的 Gemini Pro 帳號，透過已安裝登入的 Google Antigravity CLI (agy) 的 generate_image 工具生成圖片並存到指定資料夾。Use whenever the user wants an image generated, drawn, illustrated or rendered.
---

# 用 Antigravity 生圖

使用者有 Gemini Pro，已安裝並登入 Google Antigravity CLI（winget 套件 `Google.AntigravityCLI`，指令 `agy`）。生圖一律走下面的腳本，不需要再安裝或詢問工具。

## 流程

1. **整理提示詞**：把使用者的中文需求改寫成一段具體的英文描述，包括主體、風格、構圖、光線、色調。使用者有指定比例或尺寸就寫進描述（例如 "16:9 wide landscape composition"）。圖中需要出現文字時，把原文用引號寫進描述。
2. **執行腳本**（PowerShell，每張圖跑一次；要多張就跑多次，可以平行執行）：

   ```powershell
   pwsh -NoProfile -File "$HOME\.claude\skills\generate-image\scripts\generate-image.ps1" -Prompt "<英文描述>" -OutDir "<輸出資料夾>" -Name "<英文檔名，不含副檔名>"
   ```

   - `-OutDir` 預設為目前工作資料夾；使用者有指定位置就用使用者的。
   - `-Name` 可省略，同名檔案會自動加 `_2`、`_3`，不會覆蓋。
   - PowerShell／Bash 工具的 timeout 請設 360000 以上，生一張圖大約 30～90 秒。
3. **確認結果**：腳本輸出 `SAVED: <路徑>` 就用 Read 工具打開圖片檢查內容是否符合需求，明顯不符就調整提示詞重生。
4. **回覆使用者**：附上檔案連結，用一兩句話描述生成的圖。

## 注意事項

- 刻意**不使用** `--dangerously-skip-permissions`。headless 模式下 agy 想執行 shell 指令會被自動拒絕，所以腳本只叫它呼叫 `generate_image`，搬檔由腳本負責。
- 輸出 `NO_IMAGE_GENERATED` 時，後面會附上 agy 的原始輸出，依內容排除問題：
  - 找不到 `agy`：執行 `winget install --id Google.AntigravityCLI -e --accept-source-agreements --accept-package-agreements`
  - 登入過期或未登入：請使用者在自己的終端機執行 `agy` 完成 Google 帳號登入
  - 內容被安全政策拒絕：告知使用者並建議調整描述
- 原始圖檔位於 `%USERPROFILE%\.gemini\antigravity-cli\brain\<對話id>\`。
- 預設輸出約 1024×1024 JPG。
