# 把這台電腦 ~/.claude/skills 裡「自己的 skills」複製回 repo（排除 synced、.trash 與已是連結的項目）。
# 用在原始那台電腦：改完 skill 後執行，再 git add / commit / push。
param([string]$ClaudeDir = (Join-Path $HOME '.claude\skills'))
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($d in Get-ChildItem $ClaudeDir -Directory -Force) {
    if ($d.Name -in '.trash', 'synced') { continue }
    if ($d.LinkType) { continue }   # 已經是指向 repo 的連結，不用複製
    robocopy $d.FullName (Join-Path $repo "skills\$($d.Name)") /MIR /NFL /NDL /NJH /NJS | Out-Null
    Write-Host "  已更新 $($d.Name)"
}
Write-Host "完成。接著執行：git add -A; git commit -m '更新 skills'; git push"
