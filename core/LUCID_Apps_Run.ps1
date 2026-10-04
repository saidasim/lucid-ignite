# ============================================================================
# Project LUCID - Application Deployer Engine
# Windows 11 24H2 / 25H2 Post-Installation Application Tool
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
    Write-Host "                Project LUCID - Application Deployer Engine                 " -ForegroundColor White
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
Write-Host "                $($L.SecApps)                             " -ForegroundColor White
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------------
# 2. Environment & Module Setup
# ----------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "$($L.AdminReq)" -ForegroundColor Red
    exit 1
}

$modulesDir = Join-Path -Path $ScriptRoot -ChildPath "modules"
$packagesPath = Join-Path -Path $ScriptRoot -ChildPath "config\packages.json"
$parentDir = Split-Path -Parent $ScriptRoot
$logsDir = Join-Path -Path $parentDir -ChildPath "logs"

# Import Application PowerShell Modules
$appModules = @("Logging.psm1", "Winget.psm1", "Apps.psm1", "Summary.psm1")
foreach ($mod in $appModules) {
    $modPath = Join-Path -Path $modulesDir -ChildPath $mod
    try {
        Import-Module -Name $modPath -Force -ErrorAction Stop
    } catch {
        Write-Host "[ERROR] Failed to import module $mod : $_" -ForegroundColor Red
        exit 1
    }
}

# Initialize Logging with LUCID_Apps Prefix
Initialize-LucidLogging -LogDirectory $logsDir -LogPrefix "LUCID_Apps" | Out-Null
Write-LucidLog -Message "Project LUCID Application Deployer Started. Selected Language: $Language" -Level "INFO"

# Check Internet Connectivity
$hasInternet = $false
try {
    $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($ping) {
        $hasInternet = $true
        Write-LucidLog -Message "$($L.InternetOK)" -Level "SUCCESS"
    } else {
        Write-LucidLog -Message "$($L.InternetFail)" -Level "WARNING"
    }
} catch {
    Write-LucidLog -Message "$($L.InternetFail)" -Level "WARNING"
}

# ----------------------------------------------------------------------------
# 3. Application Deployment & Upgrades
# ----------------------------------------------------------------------------
if ($hasInternet) {
    if (Test-LucidWingetAvailable) {
        Write-LucidLog -Message "$($L.WingetStart)" -Level "INFO"
        Repair-LucidWingetSources

        Write-LucidLog -Message "$($L.AppsStart)" -Level "INFO"
        Install-LucidApplications -PackagesJsonPath $packagesPath

        Write-LucidLog -Message "Upgrading installed Winget packages..." -Level "INFO"
        Update-LucidApplications
    } else {
        Write-LucidLog -Message "Winget executable not found. Skipping application installation." -Level "WARNING"
    }
} else {
    Write-LucidLog -Message "$($L.AppsSkipOffline)" -Level "WARNING"
}

# ----------------------------------------------------------------------------
# 4. Summary & Exit
# ----------------------------------------------------------------------------
Show-LucidSummary -Title $L.SummaryTitle -LabelCompleted $L.Completed -LabelWarnings $L.Warnings -LabelErrors $L.Errors -LabelRestart $L.RestartRec

Write-Host "`r`n$($L.Finished)" -ForegroundColor Green
