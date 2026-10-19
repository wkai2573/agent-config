# 把這台電腦的全域設定複製回 repo：skills、AGENTS.md / GEMINI.md / CLAUDE.md / settings.json、memory、agents、mods。
# 排除 synced、.trash 與已是連結的項目。用在原始那台電腦：改完後執行，再 git add / commit / push。
param([string]$ClaudeDir = (Join-Path $HOME '.claude\skills'))
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path

# skills
foreach ($d in Get-ChildItem $ClaudeDir -Directory -Force) {
    if ($d.Name -in '.trash', 'synced') { continue }
    if ($d.LinkType) { continue }   # 已經是指向 repo 的連結，不用複製
    robocopy $d.FullName (Join-Path $repo "skills\$($d.Name)") /MIR /NFL /NDL /NJH /NJS | Out-Null
    Write-Host "  已更新 skill $($d.Name)"
}

# 全域設定檔
$configMap = @(
    @{ From = (Join-Path $HOME 'AGENTS.md');            To = 'config\AGENTS.md' },
    @{ From = (Join-Path $HOME 'GEMINI.md');            To = 'config\GEMINI.md' },
    @{ From = (Join-Path $HOME '.claude\CLAUDE.md');    To = 'config\claude\CLAUDE.md' },
    @{ From = (Join-Path $HOME '.claude\settings.json'); To = 'config\claude\settings.json' }
)
foreach ($m in $configMap) {
    if (-not (Test-Path $m.From)) { continue }
    $to = Join-Path $repo $m.To
    New-Item -ItemType Directory -Force (Split-Path $to -Parent) | Out-Null
    Copy-Item $m.From $to -Force
    Write-Host "  已更新 $($m.To)"
}

# memory：家目錄專案的那一個（已是連結就略過）
$homeProject = ($HOME -replace '[^A-Za-z0-9]', '-')
$memDir = Join-Path $HOME ".claude\projects\$homeProject\memory"
$memItem = Get-Item $memDir -Force -ErrorAction SilentlyContinue
if ($memItem -and -not $memItem.LinkType) {
    robocopy $memDir (Join-Path $repo 'memory') /MIR /XF .gitkeep /NFL /NDL /NJH /NJS | Out-Null
    Write-Host "  已更新 memory"
}

# agents：自訂 subagent（已是連結就略過）
$agentsDir = Join-Path $HOME '.claude\agents'
$agentsItem = Get-Item $agentsDir -Force -ErrorAction SilentlyContinue
if ($agentsItem -and -not $agentsItem.LinkType) {
    robocopy $agentsDir (Join-Path $repo 'agents') /MIR /XF .gitkeep /NFL /NDL /NJH /NJS | Out-Null
    Write-Host "  已更新 agents"
}

# mods：dev-mods 底下每個工作階段資料夾裡的 mod（排除連結與引擎產生的 types）
$devMods = Join-Path $HOME '.claude\dev-mods'
foreach ($session in Get-ChildItem $devMods -Directory -Force -ErrorAction SilentlyContinue) {
    if ($session.Name -eq 'synced') { continue }
    foreach ($mod in Get-ChildItem $session.FullName -Directory -Force) {
        if ($mod.LinkType) { continue }
        if (-not (Test-Path (Join-Path $mod.FullName '.claude-plugin\plugin.json'))) { continue }
        robocopy $mod.FullName (Join-Path $repo "mods\$($mod.Name)") /MIR /XD (Join-Path $mod.FullName '.claude-plugin\types') /NFL /NDL /NJH /NJS | Out-Null
        Write-Host "  已更新 mod $($mod.Name)"
    }
}
Write-Host "完成。接著執行：git add -A; git commit -m '更新全域設定'; git push"
