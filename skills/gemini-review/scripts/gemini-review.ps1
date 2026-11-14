# Review the current git diff with Gemini through Google Antigravity CLI (agy).
# Usage: pwsh -File gemini-review.ps1 [-Base <git ref>] [-Model <model id>] [-Focus <extra instruction>] [-TotalTimeoutSec <n>]
param(
    [string]$Base = 'HEAD',
    [string]$Model = 'gemini-4-hydrogen-low',
    [string]$Focus,
    [int]$TotalTimeoutSec = 300,
    [int]$MaxDiffKB = 150,
    [int]$MaxUntrackedKB = 50,
    [int]$MaxUntrackedTotalKB = 100,
    [int]$MaxReadFiles = 5
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$startedAt = [Diagnostics.Stopwatch]::StartNew()

# winget adds agy to PATH, but shells started before install may not see it
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
$agy = Get-Command agy -ErrorAction SilentlyContinue
if (-not $agy) {
    Write-Output 'REVIEW_FAILED: agy not found. Install with: winget install --id Google.AntigravityCLI -e'
    exit 1
}

$root = (git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $root) {
    Write-Output 'REVIEW_FAILED: not inside a git repository'
    exit 1
}

# Tracked changes (staged + unstaged) against Base, then untracked files appended as new files
$diff = (git -C $root diff $Base --no-color) -join "`n"
if ($LASTEXITCODE -ne 0) {
    Write-Output "REVIEW_FAILED: git diff failed for base '$Base'"
    exit 1
}
$diffBytes = [System.Text.Encoding]::UTF8.GetByteCount($diff)
if ($diffBytes -gt ($MaxDiffKB * 1KB)) {
    $diffKB = [math]::Round($diffBytes / 1KB)
    Write-Output "TOO_LARGE: diff is ${diffKB}KB, limit is ${MaxDiffKB}KB. Narrow the scope with -Base, or review in smaller batches."
    exit 1
}

$untracked = @(git -C $root ls-files --others --exclude-standard)
$extra = New-Object System.Text.StringBuilder
$extraBytes = 0
foreach ($rel in $untracked) {
    $full = Join-Path $root $rel
    $file = Get-Item -LiteralPath $full -ErrorAction SilentlyContinue
    if (-not $file -or $file.PSIsContainer) { continue }
    if ($file.Length -gt ($MaxUntrackedKB * 1KB)) {
        [void]$extra.AppendLine("### new file (skipped, larger than ${MaxUntrackedKB}KB): $rel")
        continue
    }
    if (($extraBytes + $file.Length) -gt ($MaxUntrackedTotalKB * 1KB)) {
        [void]$extra.AppendLine("### new file (skipped, untracked total over ${MaxUntrackedTotalKB}KB): $rel")
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($full)
    if ($bytes -contains 0) {
        [void]$extra.AppendLine("### new file (skipped, binary): $rel")
        continue
    }
    $extraBytes += $bytes.Length
    [void]$extra.AppendLine("### new file: $rel")
    [void]$extra.AppendLine([System.Text.Encoding]::UTF8.GetString($bytes))
}

if (-not $diff.Trim() -and $extra.Length -eq 0) {
    Write-Output 'NO_CHANGES'
    exit 0
}

$focusLine = if ($Focus) { "Additional focus from the user: $Focus" } else { '' }
$instructions = @"
You are a strict code reviewer. Review ONLY the changes in the diff section below.
You have a hard time limit, so work efficiently and finish with the review.

Scope:
- Report correctness problems only: logic errors, wrong conditions, off-by-one, null or undefined handling, broken error handling, race conditions, resource leaks, security issues, and behaviour that contradicts what the change clearly intends.
- Do NOT report style, naming, formatting, missing comments, or refactoring and simplification suggestions.
- The diff already contains enough context for most judgements. Decide from the diff alone whenever you can.
- Only when a suspicion truly depends on code outside the diff, you may read at most $MaxReadFiles other files in the current working directory. Do not browse or explore. Do not report something you could not confirm.
- Do NOT modify any file, and do NOT run shell commands. Shell commands are denied in this session.
- To inspect other files use only the read-only tools: view_file, grep_search, list_dir, find_by_name. Never use run_command, not even for git, grep, cat or Get-Content.
- If any tool call is denied, do not retry it and do not stop. Continue with the diff below and always finish with the review in the required output format.
$focusLine

Output rules:
- Write the whole answer in Traditional Chinese (Taiwan usage). Keep file paths, identifiers and code in their original form.
- List the most severe problem first. Report at most 10 problems.
- Use this format for every problem:
  - file:line
  - one sentence describing the defect
  - a concrete failure scenario: which input or state leads to which wrong result
- If you find no problem, reply with exactly: 沒有發現問題
- No preamble and no closing summary.

===== DIFF (base: $Base) =====
$diff

===== NEW UNTRACKED FILES =====
$($extra.ToString())
"@

$tmpDir = Join-Path $env:TEMP 'agy-review'
New-Item -ItemType Directory -Force $tmpDir | Out-Null
# A run killed from outside never reaches the finally block; sweep what it left behind
Get-ChildItem $tmpDir -Filter 'review-*.md' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-1) } |
    Remove-Item -Force -ErrorAction SilentlyContinue
$promptFile = Join-Path $tmpDir ('review-' + [guid]::NewGuid().ToString('N') + '.md')
[System.IO.File]::WriteAllText($promptFile, $instructions, (New-Object System.Text.UTF8Encoding($false)))

# The file path is the only thing on the command line, so diff size and quoting never matter
$command = "Read the file $promptFile and carry out the code review it describes. Reply with the review only."

# Run agy under a hard deadline; kill the whole process tree when it overruns.
function Invoke-Agy([int]$budgetSec) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $agy.Source
    foreach ($a in @('-p', $command, '--model', $Model, '--add-dir', $tmpDir, '--print-timeout', "${budgetSec}s")) {
        [void]$psi.ArgumentList.Add($a)
    }
    $psi.WorkingDirectory = $root
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()
    # Give agy's own timeout a few seconds to report before the hard kill
    $finished = $proc.WaitForExit(($budgetSec + 10) * 1000)
    if (-not $finished) {
        try { $proc.Kill($true) } catch {}
        $proc.WaitForExit(5000) | Out-Null
    }
    [pscustomobject]@{
        TimedOut = -not $finished
        Code     = if ($finished) { $proc.ExitCode } else { -1 }
        Output   = ($outTask.Result + $errTask.Result)
    }
}

# Retry only for the intermittent "run_command denied" failure, and only with the time left.
$result = $null
$denied = $false
try {
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $remaining = [int]($TotalTimeoutSec - $startedAt.Elapsed.TotalSeconds)
        if ($remaining -lt 30) { break }
        $result = Invoke-Agy $remaining
        $denied = $result.Output -match '(?m)^\s*jetski:.*(no output produced|auto-denied)'
        if ($result.TimedOut -or -not $denied) { break }
    }
} finally {
    Remove-Item -LiteralPath $promptFile -Force -ErrorAction SilentlyContinue
}

if (-not $result) {
    Write-Output "REVIEW_FAILED: no time budget left (${TotalTimeoutSec}s total)"
    exit 1
}
if ($result.TimedOut) {
    Write-Output "REVIEW_TIMEOUT: exceeded ${TotalTimeoutSec}s with model $Model. Narrow the scope with -Base or -Focus; do not rerun unchanged."
    exit 1
}
if ($result.Code -ne 0 -or -not $result.Output.Trim() -or $denied) {
    Write-Output "REVIEW_FAILED (exit $($result.Code))"
    Write-Output $result.Output
    exit 1
}

Write-Output "[gemini-review model=$Model base=$Base elapsed=$([int]$startedAt.Elapsed.TotalSeconds)s]"
Write-Output $result.Output.Trim()
