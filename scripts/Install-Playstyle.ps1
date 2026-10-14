# Installs one v1.6 playstyle for the Windows client. No Python required.
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Playstyle.ps1 -Style road_trip
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('base_building','local_exploration','road_trip')]
    [string]$Style,
    [string]$PlayersDir = '',
    [string]$ZomboidDir = (Join-Path $env:USERPROFILE 'Zomboid')
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$src = Join-Path $repo ('playstyles\' + $Style)
$srcMod = Join-Path $src 'ZomboidAPCheckTracker'
$srcYaml = Join-Path $src 'Players\ZomboidPlayer.yaml'
$srcBridge = Join-Path $repo 'bridge'
$modDir = Join-Path $ZomboidDir 'mods\ZomboidAPCheckTracker'
$bridgeDir = Join-Path $ZomboidDir 'APBridge'
if (!(Test-Path -LiteralPath (Join-Path $srcMod '42\mod.info')) -or !(Test-Path -LiteralPath $srcYaml)) {
    throw 'Missing v1.6 source files. Extract the FULL repository ZIP first.'
}
if ([string]::IsNullOrWhiteSpace($PlayersDir)) {
    $candidates = @(
        (Join-Path $env:ProgramData 'Archipelago\Players'),
        (Join-Path $env:USERPROFILE 'Archipelago\Players'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Archipelago\Players')
    )
    $found = @($candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique)
    if ($found.Count -eq 1) {
        $PlayersDir = [string]$found[0]
    } elseif ($found.Count -gt 1) {
        Write-Host 'Found multiple possible Archipelago Players folders:' -ForegroundColor Yellow
        $found | ForEach-Object { Write-Host ('  ' + $_) }
        throw 'Please rerun with -PlayersDir "FULL\PATH\TO\Players".'
    } else {
        throw 'Archipelago Players folder not found. Open it from Archipelago Launcher, then rerun with -PlayersDir "FULL\PATH\TO\Players".'
    }
}
if (!(Test-Path -LiteralPath $PlayersDir -PathType Container)) { throw "Players folder does not exist: $PlayersDir" }
if (!(Test-Path -LiteralPath $ZomboidDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $ZomboidDir | Out-Null
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $ZomboidDir ('APBackups\' + $stamp + '-' + ([guid]::NewGuid().ToString('N').Substring(0,8)))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Write-Host "Installing '$Style'" -ForegroundColor Cyan
Write-Host "Backups: $backup"

# Move the old mod OUTSIDE mods/ so Build 42 never loads two copies with the same mod ID.
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $modDir) | Out-Null
if (Test-Path -LiteralPath $modDir) {
    Move-Item -LiteralPath $modDir -Destination (Join-Path $backup 'ZomboidAPCheckTracker')
}
Copy-Item -LiteralPath $srcMod -Destination $modDir -Recurse -Force

# Preserve any other players' YAMLs. Move old configs of THIS slot out of Players.
$oldYamls = @(Get-ChildItem -LiteralPath $PlayersDir -File | Where-Object { $_.Extension -in @('.yaml','.yml') })
$oldSlotFiles = @()
foreach ($yaml in $oldYamls) {
    if ($yaml.Name -eq 'ZomboidPlayer.yaml') { $oldSlotFiles += $yaml; continue }
    foreach ($line in @(Get-Content -LiteralPath $yaml.FullName -Encoding UTF8 -ErrorAction SilentlyContinue)) {
        if ($line -match '^\s*name:\s*[''" ]?ZomboidPlayer[''" ]?\s*(?:#.*)?$') {
            $oldSlotFiles += $yaml; break
        }
    }
}
if ($oldSlotFiles.Count -gt 0) {
    $yamlBackup = Join-Path $backup 'Players'
    New-Item -ItemType Directory -Path $yamlBackup | Out-Null
    foreach ($old in $oldSlotFiles) {
        Move-Item -LiteralPath $old.FullName -Destination (Join-Path $yamlBackup $old.Name)
    }
}
Copy-Item -LiteralPath $srcYaml -Destination (Join-Path $PlayersDir 'ZomboidPlayer.yaml') -Force

# Keep the bridge in a known, separate directory; back up the old installed bridge.
if (Test-Path -LiteralPath $bridgeDir) {
    Copy-Item -LiteralPath $bridgeDir -Destination (Join-Path $backup 'APBridge') -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $bridgeDir | Out-Null
Copy-Item -LiteralPath (Join-Path $srcBridge 'Archipelago-Bridge.ps1') -Destination $bridgeDir -Force
Copy-Item -LiteralPath (Join-Path $srcBridge 'Start-Archipelago-Bridge.bat') -Destination $bridgeDir -Force

Write-Host ''
Write-Host 'Installed mod, YAML, and bridge successfully.' -ForegroundColor Green
Write-Host 'Next steps:'
Write-Host '  1. In Archipelago Launcher: Install APWorld from archipelago\project_zomboid.apworld, then RESTART launcher.'
Write-Host '  2. Generate a NEW multiworld and upload the output ZIP to archipelago.gg.'
Write-Host '  3. Enable ONLY the installed playstyle in Project Zomboid Build 42.'
Write-Host '  4. In-game F10: set NEW server address and ZomboidPlayer slot.'
Write-Host '  5. Run the new bridge BAT:'
Write-Host ('     ' + (Join-Path $bridgeDir 'Start-Archipelago-Bridge.bat'))
Write-Host '  6. F8 = checks, F9 = reward stash, F10 = connection settings.'
Write-Host 'No reward/check files were deleted. This installer does not modify saves.'
