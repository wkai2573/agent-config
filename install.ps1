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

# 全域設定檔：以「複製」方式放到家目錄；內容不同時，先把舊檔備份再覆蓋
$cfgBackup = Join-Path $HOME '.claude\config-backup'
$configMap = @(
    @{ From = 'config\AGENTS.md';           To = (Join-Path $HOME 'AGENTS.md') },
    @{ From = 'config\GEMINI.md';           To = (Join-Path $HOME 'GEMINI.md') },
    @{ From = 'config\claude\CLAUDE.md';    To = (Join-Path $HOME '.claude\CLAUDE.md') },
    @{ From = 'config\claude\settings.json'; To = (Join-Path $HOME '.claude\settings.json') }
)
foreach ($m in $configMap) {
    $from = Join-Path $repo $m.From
    if (-not (Test-Path $from)) { continue }
    $to = $m.To
    if (Test-Path $to) {
        if ((Get-FileHash $from).Hash -eq (Get-FileHash $to).Hash) { continue }
        New-Item -ItemType Directory -Force $cfgBackup | Out-Null
        $bak = Join-Path $cfgBackup ("{0}.{1}" -f (Split-Path $to -Leaf), (Get-Date -Format 'yyyyMMddHHmmss'))
        Copy-Item $to $bak
        Write-Host "  已備份既有的 $(Split-Path $to -Leaf) -> $bak"
    }
    New-Item -ItemType Directory -Force (Split-Path $to -Parent) | Out-Null
    Copy-Item $from $to -Force
    Write-Host "  已更新 $(Split-Path $to -Leaf)"
}

# 以「連結」方式同步的資料夾：memory（家目錄專案的）與 mods
function Link-Dir($target, $link, $backupRoot) {
    New-Item -ItemType Directory -Force (Split-Path $link -Parent) | Out-Null
    $item = Get-Item $link -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LinkType) {
            [System.IO.Directory]::Delete($link)
        } elseif (-not (Get-ChildItem $link -Force)) {
            Remove-Item $link        # 空資料夾，直接換成連結
        } else {
            New-Item -ItemType Directory -Force $backupRoot | Out-Null
            $bak = Join-Path $backupRoot ("{0}.{1}" -f (Split-Path $link -Leaf), (Get-Date -Format 'yyyyMMddHHmmss'))
            Move-Item $link $bak
            Write-Host "  已備份既有的 $link -> $bak"
        }
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}

# memory：Claude Code 的 memory 以專案路徑編碼成資料夾名，這裡只處理家目錄那一個
$homeProject = ($HOME -replace '[^A-Za-z0-9]', '-')
$memLink = Join-Path $HOME ".claude\projects\$homeProject\memory"
Link-Dir (Join-Path $repo 'memory') $memLink $cfgBackup
Write-Host "  已連結 memory -> $memLink"

# mods：每個子資料夾連結到 ~/.claude/dev-mods/synced/<名稱>
$modsSrc = Join-Path $repo 'mods'
foreach ($d in Get-ChildItem $modsSrc -Directory -ErrorAction SilentlyContinue) {
    Link-Dir $d.FullName (Join-Path $HOME ".claude\dev-mods\synced\$($d.Name)") $cfgBackup
    Write-Host "  已連結 mod $($d.Name)"
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
