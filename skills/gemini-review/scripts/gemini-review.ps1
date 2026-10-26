# Review the current git diff with Gemini through Google Antigravity CLI (agy).
# Usage: pwsh -File gemini-review.ps1 [-Base <git ref>] [-Model <model id>] [-Focus <extra instruction>] [-TimeoutSec <n>]
param(
    [string]$Base = 'HEAD',
    [string]$Model = 'gemini-3.8-flash-medium',
    [string]$Focus,
    [int]$TimeoutSec = 600,
    [int]$MaxUntrackedKB = 100
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# winget adds agy to PATH, but shells started before install may not see it
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
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
$untracked = @(git -C $root ls-files --others --exclude-standard)
$extra = New-Object System.Text.StringBuilder
foreach ($rel in $untracked) {
    $full = Join-Path $root $rel
    $file = Get-Item -LiteralPath $full -ErrorAction SilentlyContinue
    if (-not $file -or $file.PSIsContainer) { continue }
    if ($file.Length -gt ($MaxUntrackedKB * 1KB)) {
        [void]$extra.AppendLine("### new file (skipped, larger than ${MaxUntrackedKB}KB): $rel")
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($full)
    if ($bytes -contains 0) {
        [void]$extra.AppendLine("### new file (skipped, binary): $rel")
        continue
    }
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

Scope:
- Report correctness problems only: logic errors, wrong conditions, off-by-one, null or undefined handling, broken error handling, race conditions, resource leaks, security issues, and behaviour that contradicts what the change clearly intends.
- Do NOT report style, naming, formatting, missing comments, or refactoring and simplification suggestions.
- You may read other files in the current working directory to confirm how changed code is used. Verify a suspicion against the real code before reporting it. Do not report something you could not confirm.
- Do NOT modify any file, and do NOT run shell commands. Shell commands are denied in this session.
- To inspect other files use only the read-only tools: view_file, grep_search, list_dir, find_by_name. Never use run_command, not even for git, grep, cat or Get-Content.
- If any tool call is denied, do not retry it and do not stop. Continue with the read-only tools, or with the diff below, and always finish with the review in the required output format.
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
$promptFile = Join-Path $tmpDir ('review-' + [guid]::NewGuid().ToString('N') + '.md')
[System.IO.File]::WriteAllText($promptFile, $instructions, (New-Object System.Text.UTF8Encoding($false)))

# The file path is the only thing on the command line, so diff size and quoting never matter
$command = "Read the file $promptFile and carry out the code review it describes. Reply with the review only."

# agy sometimes tries run_command anyway; headless mode denies it and the run ends with no review.
# That is intermittent, so retry once before reporting failure.
$maxAttempts = 2
Push-Location $root
try {
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $output = agy -p $command --model $Model --add-dir $tmpDir --print-timeout "${TimeoutSec}s" 2>&1 | Out-String
        $code = $LASTEXITCODE
        $denied = $output -match '^\s*jetski:.*(no output produced|auto-denied)'
        if ($code -eq 0 -and $output.Trim() -and -not $denied) { break }
    }
} finally {
    Pop-Location
    Remove-Item -LiteralPath $promptFile -Force -ErrorAction SilentlyContinue
}

if ($code -ne 0 -or -not $output.Trim() -or $denied) {
    Write-Output "REVIEW_FAILED (exit $code)"
    Write-Output $output
    exit 1
}

Write-Output "[gemini-review model=$Model base=$Base]"
Write-Output $output.Trim()
