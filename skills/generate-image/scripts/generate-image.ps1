# Generate an image with Google Antigravity CLI (agy) and copy it to OutDir.
# Usage: pwsh -File generate-image.ps1 -Prompt "<english description>" [-OutDir <dir>] [-Name <basename>]
param(
    [Parameter(Mandatory = $true)][string]$Prompt,
    [string]$OutDir = (Get-Location).Path,
    [string]$Name,
    [int]$TimeoutSec = 300
)

$ErrorActionPreference = 'Stop'

# winget adds agy to PATH, but shells started before install may not see it
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')
if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
    Write-Error "agy not found. Install with: winget install --id Google.AntigravityCLI -e"
    exit 1
}

$brain = Join-Path $env:USERPROFILE '.gemini\antigravity-cli\brain'
# Run agy from an isolated folder so it never touches the user's files
$work = Join-Path $env:TEMP 'agy-imagegen'
New-Item -ItemType Directory -Force $work | Out-Null
New-Item -ItemType Directory -Force $OutDir | Out-Null

$start = Get-Date
$instruction = "Call the generate_image tool exactly once to create: $Prompt. " +
    "Do not run any shell commands or write any files. " +
    "Just report the exact file path where the generated image was saved."

Push-Location $work
try {
    $output = agy -p $instruction --print-timeout "${TimeoutSec}s" 2>&1 | Out-String
} finally {
    Pop-Location
}

$images = @()
if (Test-Path $brain) {
    $images = Get-ChildItem $brain -Recurse -File -Include *.jpg, *.jpeg, *.png, *.webp |
        Where-Object { $_.LastWriteTime -gt $start } |
        Sort-Object LastWriteTime
}

if (-not $images) {
    Write-Output "NO_IMAGE_GENERATED"
    Write-Output $output
    exit 1
}

foreach ($img in $images) {
    $base = if ($Name) { $Name } else { $img.BaseName -replace '_\d{10,}$', '' }
    $dest = Join-Path $OutDir ($base + $img.Extension)
    $i = 2
    while (Test-Path $dest) {
        $dest = Join-Path $OutDir ("{0}_{1}{2}" -f $base, $i, $img.Extension)
        $i++
    }
    Copy-Item $img.FullName $dest
    Write-Output "SAVED: $dest"
}
