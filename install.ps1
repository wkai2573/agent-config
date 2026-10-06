# 把本 repo 的 skills 以「連結」方式裝到 Claude Code / Gemini（Antigravity）。
# 之後只要 git pull，兩邊的 skills 就一起更新。可重複執行。
param(
    [string]$ClaudeDir    = (Join-Path $HOME '.claude\skills'),
    [string]$GeminiConfig = (Join-Path $HOME '.gemini\config\skills.json'),
    [string]$BackupDir    = (Join-Path $HOME '.claude\skills-backup')
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $repo 'skills'

New-Item -ItemType Directory -Force $ClaudeDir | Out-Null

foreach ($d in Get-ChildItem $src -Directory) {
    $link = Join-Path $ClaudeDir $d.Name
    $item = Get-Item $link -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LinkType) {
            # 舊連結：只刪連結本身，不會動到來源檔案
            [System.IO.Directory]::Delete($link)
        } else {
            # 真實資料夾：先備份，避免覆蓋你在這台電腦上的修改
            New-Item -ItemType Directory -Force $BackupDir | Out-Null
            $bak = Join-Path $BackupDir ("{0}.{1}" -f $d.Name, (Get-Date -Format 'yyyyMMddHHmmss'))
            Move-Item $link $bak
            Write-Host "  已備份既有的 $($d.Name) -> $bak"
        }
    }
    New-Item -ItemType Junction -Path $link -Target $d.FullName | Out-Null
    Write-Host "  已連結 $($d.Name)"
}

# Gemini（Antigravity）：讓它也讀 ~/.claude/skills
$geminiDir = Split-Path -Parent $GeminiConfig
if (-not (Test-Path $geminiDir)) {
    Write-Host "（找不到 $geminiDir，略過 Gemini 設定；之後安裝 Gemini 再重跑本腳本即可）"
} else {
    $claudePath = $ClaudeDir -replace '\\', '/'
    $json = if (Test-Path $GeminiConfig) { Get-Content $GeminiConfig -Raw | ConvertFrom-Json } else { [pscustomobject]@{ entries = @() } }
    $entries = @($json.entries)
    if (-not ($entries | Where-Object { $_.path -eq $claudePath })) {
        $entries += [pscustomobject]@{ path = $claudePath; exclude = @('synced', 'generate-image') }
        $json.entries = $entries
        $text = $json | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($GeminiConfig, $text, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "  已在 Gemini 設定加入 $claudePath"
    } else {
        Write-Host "  Gemini 設定已包含 $claudePath，不需變更"
    }
}
Write-Host "完成。重開 Claude Code / Gemini 即可看到 skills。"
