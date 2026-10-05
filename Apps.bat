@echo off
setlocal enabledelayedexpansion
title LUCID Ignite - Apps Deployer

cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ============================================================================
    echo  [INFO] Requesting Administrator Privileges ^(UAC Prompt^)...
    echo ============================================================================
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs -WorkingDirectory '%~dp0'"
    exit /b
)

echo.
echo               __    __  __  ___  ____  ____  _____  ___ 
echo              (  )  (  )(  )/ __)(_  _)(  _ \(  _  )/ __)
echo               )(__  )(__)(( (__  _)(_  )(_) ))(_)( \__ \
echo              (____)(______)\___)(____)(____/(_____)(___/                          
echo ============================================================================
echo                LUCID Ignite - Application Deployer Engine                 
echo ============================================================================
echo.

if exist "%~dp0core\LUCID_Ignite_Apps.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0core\LUCID_Ignite_Apps.ps1"
) else (
    echo [ERROR] LUCID_Ignite_Apps.ps1 not found!
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo  Execution finished. Press any key to exit...
echo ============================================================================
pause