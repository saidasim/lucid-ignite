# ============================================================================
# Project LUCID - First Run v1.0 System Tweaks Engine
# Windows 11 24H2 / 25H2 Post-Installation System Setup Tool
# ============================================================================

# Requires -Version 5.1

[CmdletBinding()]
param (
    [string]$Language = ""
)

$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

# ----------------------------------------------------------------------------
# Language Selection Menu (Default: EN = 1, TR = 2)
# ----------------------------------------------------------------------------
$langFile = Join-Path -Path $ScriptRoot -ChildPath "config\lang.json"
$langData = Get-Content -Path $langFile -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $Language -or ($Language -ne "EN" -and $Language -ne "TR")) {
    Clear-Host
    Write-Host ""
    Write-Host "              __    __  __  ___  ____  ____  _____  ___ " -ForegroundColor Cyan
    Write-Host "             (  )  (  )(  )/ __)(_  _)(  _ \(  _  )/ __)" -ForegroundColor Cyan
    Write-Host "              )(__  )(__)(( (__  _)(_  )(_) ))(_)( \__ \" -ForegroundColor Cyan
    Write-Host "             (____)(______)\___)(____)(____/(_____)(___/" -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "                Project LUCID - First Run v1.0 Engine                       " -ForegroundColor White
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Select Language / Dil Seciniz:" -ForegroundColor Yellow
    Write-Host "  [1] English (EN) [Default]" -ForegroundColor Green
    Write-Host "  [2] Turkce (TR)" -ForegroundColor Green
    Write-Host ""
    $choice = Read-Host " Choice / Secim [1/2] (Default: 1)"
    if ($null -ne $choice -and $choice.ToString().Trim() -eq "2") {
        $Language = "TR"
    } else {
        $Language = "EN"
    }
}

$L = $langData.$Language

# ----------------------------------------------------------------------------
# 1. Header Display
# ----------------------------------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "              __    __  __  ___  ____  ____  _____  ___ " -ForegroundColor Cyan
Write-Host "             (  )  (  )(  )/ __)(_  _)(  _ \(  _  )/ __)" -ForegroundColor Cyan
Write-Host "              )(__  )(__)(( (__  _)(_  )(_) ))(_)( \__ \" -ForegroundColor Cyan
Write-Host "             (____)(______)\___)(____)(____/(_____)(___/" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                $($L.HeaderTitle)                       " -ForegroundColor White
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------------
# 2. Environment Checks
# ----------------------------------------------------------------------------
# Check Administrator Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "$($L.AdminReq)" -ForegroundColor Red
    exit 1
}

# Check Windows Version (Windows 11 build 22000+)
$osBuild = [System.Environment]::OSVersion.Version.Build
if ($osBuild -lt 22000) {
    Write-Host "$($L.WinVerWarn)" -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
# 3. Module & Config Loading
# ----------------------------------------------------------------------------
$modulesDir = Join-Path -Path $ScriptRoot -ChildPath "modules"
$configPath = Join-Path -Path $ScriptRoot -ChildPath "config\config.json"
$parentDir = Split-Path -Parent $ScriptRoot
$logsDir = Join-Path -Path $parentDir -ChildPath "logs"

# Import System Tweaks PowerShell Modules
$systemModules = @("Logging.psm1", "Registry.psm1", "Privacy.psm1", "Search.psm1", "Explorer.psm1", "Graphics.psm1", "OneDrive.psm1", "Summary.psm1")
foreach ($mod in $systemModules) {
    $modPath = Join-Path -Path $modulesDir -ChildPath $mod
    try {
        Import-Module -Name $modPath -Force -ErrorAction Stop
    } catch {
        Write-Host "[ERROR] Failed to import module $mod : $_" -ForegroundColor Red
        exit 1
    }
}

# Initialize Logging with LUCID_System Prefix
Initialize-LucidLogging -LogDirectory $logsDir -LogPrefix "LUCID_System" | Out-Null
Write-LucidLog -Message "Project LUCID System Tweaks Engine Started. Selected Language: $Language" -Level "INFO"

# Load Configuration
if (-not (Test-Path -Path $configPath)) {
    Write-LucidLog -Message "$($L.ConfigErr)" -Level "ERROR"
    exit 1
}

try {
    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-LucidLog -Message "$($L.ConfigLoaded)" -Level "INFO"
} catch {
    Write-LucidLog -Message "$($L.ConfigErr): $_" -Level "ERROR"
    exit 1
}

# Helper for Section Headers (Console + Log File)
function Write-SectionHeader {
    param ([string]$Title)
    Write-Host ""
    Write-Host "----------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " $Title" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-LucidLog -Message "--- $Title ---" -Level "INFO"
}

# ----------------------------------------------------------------------------
# 4. System Registry & Component Tweaks Execution
# ----------------------------------------------------------------------------
# Privacy & Telemetry
if ($config.Telemetry -or $config.Cortana) {
    Write-SectionHeader -Title $L.SecPrivacy
    Invoke-LucidPrivacyTweaks
}

# Search Tweaks
if ($config.Search) {
    Write-SectionHeader -Title $L.SecSearch
    Invoke-LucidSearchTweaks
}

# Explorer & Visual FX Tweaks
if ($config.Explorer) {
    Write-SectionHeader -Title $L.SecExplorer
    Invoke-LucidExplorerTweaks
}

# Graphics Tweaks (HAGS)
if ($config.HAGS) {
    Write-SectionHeader -Title $L.SecGraphics
    Invoke-LucidGraphicsTweaks
}

# OneDrive Removal
if ($config.OneDrive) {
    Write-SectionHeader -Title $L.SecOneDrive
    Remove-LucidOneDrive
}

# ----------------------------------------------------------------------------
# 5. Final Summary Report
# ----------------------------------------------------------------------------
Show-LucidSummary -Title $L.SummaryTitle -LabelCompleted $L.Completed -LabelWarnings $L.Warnings -LabelErrors $L.Errors -LabelRestart $L.RestartRec

if ((Get-LucidStats).Errors -gt 0) {
    Write-Host "`r`n$($L.FinishedWithErrors)" -ForegroundColor Yellow
} else {
    Write-Host "`r`n$($L.Finished)" -ForegroundColor Green
}
