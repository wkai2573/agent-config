---
name: gemini-review
description: 用 Gemini 審查目前的 git 變更，只找正確性問題並回報問題清單。想省 Claude 額度、或想換一個模型交叉審查時使用；也可取代 /code-review。審查由使用者的 Gemini 帳號透過 Antigravity CLI (agy) 執行，Claude 這邊只收到最後的問題清單。
---

# 用 Gemini 做 code review

審查交給使用者已登入的 Google Antigravity CLI（`agy`），Claude 只負責執行腳本、讀結果、整理給使用者。審查本身不消耗 Claude 額度。

## 流程

1. **執行腳本**（PowerShell，在要審查的專案資料夾內執行）：

   ```powershell
   pwsh -NoProfile -File "$HOME\.claude\skills\gemini-review\scripts\gemini-review.ps1"
   ```

   - 預設審查「目前工作區相對於 HEAD 的所有變更」，包含已暫存、未暫存與尚未追蹤的新檔，所以應該在 commit 之前執行。
   - `-Base <git ref>`：改成相對於某個分支或 commit 審查，例如整個功能分支相對於主分支。
   - `-Focus "<一句話>"`：使用者有特別在意的面向時帶入。
   - `-Model <模型代號>`：預設 `gemini-3.8-flash-medium`。可用的模型用 `agy models` 查。想省時間改 `-low`，想更仔細改 `-high`。
   - 工具的 timeout 請設 660000 以上，審查通常需要 1～5 分鐘。

2. **看輸出的第一行**：
   - `NO_CHANGES`：沒有任何變更可審，如實告訴使用者。
   - `REVIEW_FAILED`：依後面附的原始輸出排除，不要假裝審查通過。
     - 找不到 `agy`：執行 `winget install --id Google.AntigravityCLI -e --accept-source-agreements --accept-package-agreements`
     - 登入過期或未登入：請使用者在自己的終端機執行 `agy` 完成 Google 帳號登入
     - 輸出含 `jetski: no output produced` 或 `auto-denied`：agy 想執行 shell 指令被拒絕。腳本已自動重試一次仍失敗，直接再執行一次腳本即可，不要加 `--dangerously-skip-permissions`。
     - 逾時：改用 `-Model gemini-3.8-flash-low`，或用 `-Base` 縮小範圍後再跑
   - `[gemini-review ...]` 開頭：後面就是審查結果。

3. **處理結果**：
   - 回報是「沒有發現問題」就直接告知使用者，不要自己再補審一次。
   - 有問題清單時，逐項對照實際程式碼確認是否成立。Gemini 的結果是線索，不是定論，確認不成立的項目要剔除並說明原因。
   - 確認成立的問題，依嚴重程度整理給使用者；要不要修由使用者或呼叫端的流程決定，本 skill 不自行修改檔案。

## 注意事項

- 刻意**不使用** `--dangerously-skip-permissions`。headless 模式下 agy 想執行 shell 指令或寫檔會被自動拒絕，只能讀檔，所以審查者不會改動專案。
- 審查指示與 diff 會寫成暫存檔，由 agy 自己讀取，不走命令列。原因是 agy 的 `-p` 模式不接受 stdin 當提示詞，而 diff 一大就會超過 Windows 命令列長度上限。暫存檔放在 `%TEMP%\agy-review`，跑完即刪。
- diff 會送到 Google 的服務。專案含有不該外送的內容時，請先告知使用者再執行。
- 這個 skill 只找正確性問題，不提風格、命名、重構建議。想要那類建議，請改用 `/simplify`。
