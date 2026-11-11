# board.ps1 - Windows (PowerShell) port of tools/muse/board.sh.
#
# Usage:
#   .\board.ps1 build|flash <board> [serial | COM port]
#
# Boards:
#   k10 s3 s3n s3-18 s3-216 s3-206 185b 185c 143c 143 146 aipi atk-box box3
#   c6 c6-206 watcher cardputer-adv sticks3 crowpanel-43 stopwatch xiao147
#   cores3 core2 fnk0104b jc3248w535 lcd7 lcd128 lcd349 spotpear vn183
#   p4lcd35 rorolee smartring-plus lcd19 s3lcd35 plus2 ai-passport echoear
#
# ESP-Mosaico is the one board not supported by this port: it builds with
# ESP-IDF master and flashes through Espressif's ESP-Iris tooling, which
# assume a Unix environment.
#
# Like board.sh: each board maps to a profile, an IDF target and a flash
# baud (default 460800). The watcher flashes at 115200 through
# paced_esptool.py because its bridge drops bytes at full packet rate.
# Build log: %TEMP%\muse_build_<board>.log
#
# Place this file next to board.sh (esp32\tools\muse\) so it finds the esp32
# project root two levels up, exactly like board.sh does.
#
# The SDK token is not handled here (same as board.sh). Set it with
#   idf.py -B build-muse-<profile> menuconfig
# (ESP32 Device SDK > Muse Gadgets SDK token), or send it over serial later.
#
# Requires ESP-IDF v6.0.3 for Windows, activated in this shell (idf.py and
# python on PATH, e.g. via the ESP-IDF PowerShell shortcut or export.ps1).
# Converted from board.sh as of muse-gadget-sdk main @ 9d8cca1 (2026-11-11).
# Not yet tested on real Windows hardware.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('build', 'flash')]
    [string]$Command,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Board,

    [Parameter(Position = 2)]
    [string]$SerialOrPort
)

$ErrorActionPreference = 'Stop'

# Board name -> profile / IDF target / flash baud (board.sh's case table).
$Boards = @{
    's3'            = @{ Profile = 'waveshare-s3-175c';    Target = 'esp32s3' }
    's3n'           = @{ Profile = 'waveshare-s3-175';     Target = 'esp32s3' }
    's3-18'         = @{ Profile = 'waveshare-s3-18';      Target = 'esp32s3' }
    's3-216'        = @{ Profile = 'waveshare-s3-216';     Target = 'esp32s3' }
    's3-206'        = @{ Profile = 'waveshare-s3-206';     Target = 'esp32s3' }
    '185b'          = @{ Profile = 'waveshare-s3-185b';    Target = 'esp32s3' }
    '185c'          = @{ Profile = 'waveshare-s3-185c';    Target = 'esp32s3' }
    '143c'          = @{ Profile = 'waveshare-s3-143c';    Target = 'esp32s3' }
    '143'           = @{ Profile = 'waveshare-s3-143';     Target = 'esp32s3' }
    '146'           = @{ Profile = 'waveshare-s3-146';     Target = 'esp32s3' }
    'k10'           = @{ Profile = 'dfrobot-unihiker-k10'; Target = 'esp32s3' }
    'aipi'          = @{ Profile = 'aipi';                 Target = 'esp32s3' }
    'atk-box'       = @{ Profile = 'atk-dnesp32s3-box';    Target = 'esp32s3' }
    'echoear'       = @{ Profile = 'ostb-echoear-2st';     Target = 'esp32s3' }
    'box3'          = @{ Profile = 'espressif-box-3';      Target = 'esp32s3' }
    'c6'            = @{ Profile = 'waveshare-c6-18';      Target = 'esp32c6' }
    'c6-206'        = @{ Profile = 'waveshare-c6-206';     Target = 'esp32c6' }
    'watcher'       = @{ Profile = 'sensecap-watcher';     Target = 'esp32s3'; Baud = 115200; Paced = $true }
    'cardputer-adv' = @{ Profile = 'm5stack-cardputer-adv'; Target = 'esp32s3' }
    'sticks3'       = @{ Profile = 'm5stack-sticks3';      Target = 'esp32s3' }
    'crowpanel-43'  = @{ Profile = 'crowpanel-advance-43'; Target = 'esp32s3' }
    'stopwatch'     = @{ Profile = 'm5stack-stopwatch';    Target = 'esp32s3' }
    'xiao147'       = @{ Profile = 'seeed-xiao-s3-147';    Target = 'esp32s3' }
    'cores3'        = @{ Profile = 'm5stack-cores3';       Target = 'esp32s3' }
    'fnk0104b'      = @{ Profile = 'fnk0104b';             Target = 'esp32s3' }
    'jc3248w535'    = @{ Profile = 'guition-jc3248w535';   Target = 'esp32s3' }
    'lcd7'          = @{ Profile = 'waveshare-s3-lcd7';    Target = 'esp32s3' }
    'spotpear'      = @{ Profile = 'spotpear-esp32-ai-128'; Target = 'esp32s3' }
    'lcd128'        = @{ Profile = 'waveshare-s3-lcd128';  Target = 'esp32s3' }
    'lcd349'        = @{ Profile = 'waveshare-s3-lcd349';  Target = 'esp32s3' }
    'vn183'         = @{ Profile = 'vn-s3-183';            Target = 'esp32s3' }
    'p4lcd35'       = @{ Profile = 'waveshare-p4-lcd35';   Target = 'esp32p4' }
    'rorolee'       = @{ Profile = 'deotaland-rorolee';    Target = 'esp32s3' }
    'smartring-plus' = @{ Profile = 'viewe-smartring-plus'; Target = 'esp32s3' }
    'lcd19'         = @{ Profile = 'waveshare-s3-lcd19';   Target = 'esp32s3' }
    's3lcd35'       = @{ Profile = 'waveshare-s3-lcd-35';  Target = 'esp32s3' }
    # Its CH9102 USB-UART bridge drops out above 230400 baud.
    'plus2'         = @{ Profile = 'm5stack-stickc-plus2'; Target = 'esp32'; Baud = 230400 }
    # The Core2's bridge is a CP2104 or a CH9102F: 230400 is safe on both.
    'core2'         = @{ Profile = 'm5stack-core2';        Target = 'esp32'; Baud = 230400 }
    'ai-passport'   = @{ Profile = 'ai-passport';          Target = 'esp32c3' }
}

if ($Board -eq 'mosaico') {
    Write-Error 'ESP-Mosaico is not supported by this PowerShell port (it needs ESP-IDF master and the ESP-Iris tools). Use board.sh on macOS/Linux.'
    exit 2
}
if (-not $Boards.ContainsKey($Board)) {
    Write-Error "unknown board $Board"
    exit 2
}

$Spec    = $Boards[$Board]
$Profile = $Spec.Profile
$Target  = $Spec.Target
$Baud    = if ($Spec.ContainsKey('Baud')) { $Spec.Baud } else { 460800 }
$Paced   = [bool]$Spec.Paced

# Project root: esp32\ (this script lives in esp32\tools\muse\).
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Find-IdfPy {
    return [bool](Get-Command 'idf.py' -ErrorAction SilentlyContinue)
}

# --- Activate ESP-IDF if idf.py is not already on PATH ----------------------
# (board.sh sources export.sh; the Windows equivalent is export.ps1.)
if ($env:IDF_EXPORT) {
    if ($env:IDF_EXPORT -like '*.ps1') {
        . $env:IDF_EXPORT | Out-Null
    } else {
        Write-Warning "IDF_EXPORT is '$env:IDF_EXPORT'. On Windows, dot-source the matching export.ps1 in this shell first."
    }
} elseif (-not (Find-IdfPy)) {
    $candidates = @(
        "$env:USERPROFILE\.espressif\esp-idf-v6.0.3",
        $env:IDF_PATH,
        "$env:USERPROFILE\esp\esp-idf-v6.0.3",
        "$env:USERPROFILE\esp\esp-idf-v6",
        "$env:USERPROFILE\esp\esp-idf",
        'C:\Espressif\frameworks\esp-idf-v6.0.3'
    )
    foreach ($d in $candidates) {
        if ($d -and (Test-Path (Join-Path $d 'export.ps1'))) {
            . (Join-Path $d 'export.ps1') | Out-Null
            break
        }
    }
}

if (-not (Find-IdfPy)) {
    Write-Error 'idf.py not found; activate ESP-IDF v6.0.3 first.'
    exit 1
}

Set-Location $Root

$BuildDir = "build-muse-$Profile"
$Defaults = "sdkconfig.defaults;devices/sdkconfig.muse;devices/sdkconfig.muse-$Profile"

if ($env:MUSE_VIDEO) {
    $BuildDir += '-video'
    $Defaults += ';devices/sdkconfig.muse-video'
}
if ($env:MUSE_BENCH) {
    $BuildDir += '-bench'
    $Defaults += ';devices/sdkconfig.muse-bench'
}

$Log = Join-Path ([System.IO.Path]::GetTempPath()) "muse_build_$Board.log"

function Clean-ManagedComponents {
    # Boards share managed_components/ and each resolves a different
    # dependency set, so start clean and leave nothing behind (as board.sh).
    # Retry: an indexer on the host can recreate files mid-delete.
    for ($i = 0; $i -lt 3; $i++) {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 'managed_components'
        Remove-Item -Force -ErrorAction SilentlyContinue 'dependencies.lock'
        if (-not (Test-Path 'managed_components') -and -not (Test-Path 'dependencies.lock')) {
            return
        }
        Start-Sleep -Seconds 1
    }
}

if ($Command -eq 'build') {
    Clean-ManagedComponents

    & idf.py -B $BuildDir "-DIDF_TARGET=$Target" "-DSDKCONFIG=$BuildDir/sdkconfig" `
        "-DSDKCONFIG_DEFAULTS=$Defaults" build *> $Log
    $rc = $LASTEXITCODE

    Clean-ManagedComponents

    Select-String -Path $Log -Pattern 'error:|undefined reference' |
        Select-Object -First 20 | ForEach-Object { $_.Line }
    Get-Content $Log -Tail 3

    exit $rc
}

# --- flash -------------------------------------------------------------------
# board.sh resolves the port with tools/muse/ports.py (Python + pyserial, so
# it works on Windows too). One difference: ports.py only passes through
# literal ports starting with "/dev/", so a COM port is handled here instead.
if ($SerialOrPort -match '^COM\d+$') {
    $Port = $SerialOrPort
} else {
    $portArgs = @((Join-Path $Root 'tools\muse\ports.py'), $Board)
    if ($SerialOrPort) { $portArgs += $SerialOrPort }
    $Port = & python @portArgs
    if ($LASTEXITCODE -ne 0 -or -not $Port) { exit 1 }
    $Port = "$Port".Trim()
}

# The watcher needs paced writes; everyone else uses esptool as a module.
if ($Paced) {
    $EspTool = @((Join-Path $Root 'tools\muse\paced_esptool.py'))
} else {
    $EspTool = @('-m', 'esptool')
}

Push-Location $BuildDir
try {
    # '@flash_args' must stay quoted: PowerShell would read a bare @ as an
    # array operator, while esptool expands the response file itself.
    & python @EspTool --chip $Target -p $Port -b $Baud `
        --before default-reset --after hard-reset write-flash '@flash_args' |
        Select-Object -Last 3
    $rc = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $rc
