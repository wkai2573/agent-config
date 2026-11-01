---
name: open-comfyui
description: 使用者說「幫我開 ComfyUI」「開 comfyui」「啟動 ComfyUI」「打開本地生圖介面」時使用。檢查本機 ComfyUI 是否已在執行，沒有就啟動，等伺服器就緒後自動打開瀏覽器到網頁介面。只負責開啟，不負責生圖。
---

# 開啟本機 ComfyUI

使用者的 ComfyUI 是官方 Portable 版，裝在 `D:\ComfyUI\ComfyUI_windows_portable`，網頁介面固定在 `http://127.0.0.1:8188`。流程是：檢查、必要時啟動、等就緒、開瀏覽器。全程用 PowerShell。

## 流程

1. **檢查是否已在執行**：

   ```powershell
   try { (Invoke-WebRequest -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 3 -UseBasicParsing).StatusCode } catch { 'not running' }
   ```

   回傳 200 代表已在執行，直接跳到第 4 步，不要重複啟動。

2. **啟動**：用 Portable 內建的 Python 直接啟動，視窗隱藏，輸出寫進暫存資料夾的記錄檔。加 `--disable-auto-launch`，瀏覽器改由第 4 步統一開，避免開出兩個分頁。不要用 `run_nvidia_gpu.bat` 開可見的終端機視窗：實測行程可能卡住不前進，等了 14 分鐘都沒開始監聽埠，改成隱藏視窗加記錄檔後約 40 秒就起來。

   ```powershell
   Start-Process -FilePath 'D:\ComfyUI\ComfyUI_windows_portable\python_embeded\python.exe' `
     -ArgumentList '-u','-s','ComfyUI\main.py','--windows-standalone-build','--disable-auto-launch' `
     -WorkingDirectory 'D:\ComfyUI\ComfyUI_windows_portable' `
     -RedirectStandardOutput "$env:TEMP\comfyui.out.log" -RedirectStandardError "$env:TEMP\comfyui.err.log" `
     -WindowStyle Hidden
   ```

   找不到上面的路徑時，不要猜別的位置，直接告訴使用者路徑不存在，請他確認安裝位置。

3. **等伺服器就緒**：正常約 1 分鐘內就緒，保守起見每 3 秒檢查一次，最多等 3 分鐘，這個指令的 timeout 要設到 240000。

   ```powershell
   $ok = $false
   for ($i = 0; $i -lt 50; $i++) {
     try { if ((Invoke-WebRequest -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 2 -UseBasicParsing).StatusCode -eq 200) { $ok = $true; break } } catch {}
     Start-Sleep -Seconds 3
   }
   "ready: $ok"
   ```

   超時仍是 `False` 時，不要重複啟動第二份。讀記錄檔最後幾十行找原因，再回報使用者：

   ```powershell
   Get-Content "$env:TEMP\comfyui.err.log" -Tail 40
   Get-Content "$env:TEMP\comfyui.out.log" -Tail 40
   ```

   記錄檔停在 `Starting server` 之前代表還在載入，之後卻連不上才是真的有問題。確定卡死時，先用下面的指令結束這個行程，再重做第 2 步一次：

   ```powershell
   Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'ComfyUI\\main.py' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
   ```

4. **開瀏覽器**：

   ```powershell
   Start-Process 'http://127.0.0.1:8188'
   ```

## 回報

用一兩句話說結果：已經在執行就說已在執行並開了瀏覽器；剛啟動就說已啟動並開了瀏覽器，不要附上整段指令輸出。

## 注意

- 介面預設會載入一個要 `z_image_turbo_bf16.safetensors` 的範本，使用者沒裝那個模型，看到缺檔警告屬於正常。要生圖時請他按 `W` 開工作流程面板，改開 `qwen_image_2_1_t2i_gguf`。使用者沒問就不用主動講。
- ComfyUI 在背景以隱藏視窗執行，沒有視窗可關。使用者要關閉時，用第 3 步最後那條結束行程的指令。
