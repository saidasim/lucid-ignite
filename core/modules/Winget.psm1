# ============================================================================
# Project LUCID - First Run v1.0
# Module: Winget.psm1
# ============================================================================

# Winget exit codes (https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md)
$script:WINGET_NO_APPLICATIONS_FOUND  = -1978335212  # 0x8A150014
$script:WINGET_UPDATE_NOT_APPLICABLE  = -1978335189  # 0x8A15002B
$script:WINGET_UPDATE_ALL_HAS_FAILURE = -1978335188  # 0x8A15002C

function Invoke-LucidWinget {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    # Windows PowerShell 5.1 turns redirected native stderr into errors; with
    # $ErrorActionPreference = "Stop" a harmless winget message would abort the call.
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & winget @Arguments 2>&1 | ForEach-Object { "$_" }
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = ($output -join "`n")
    }
}

function Test-LucidWingetAvailable {
    [CmdletBinding()]
    param ()

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        return $true
    }

    # On a fresh install winget is registered asynchronously after the first login.
    # Documented fix: https://learn.microsoft.com/en-us/windows/package-manager/winget/
    Write-LucidLog -Message "Winget not found. Requesting App Installer registration..." -Level "INFO"
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
    } catch {
        Write-LucidLog -Message "App Installer registration failed: $_" -Level "WARNING"
    }

    $aliasDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\WindowsApps"
    if ((Test-Path -Path $aliasDir) -and ($env:Path -notlike "*$aliasDir*")) {
        $env:Path = "$env:Path;$aliasDir"
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-LucidLog -Message "Winget is now available." -Level "SUCCESS"
        return $true
    }

    Write-LucidLog -Message "Winget is still unavailable. Install 'App Installer' from Microsoft Store (9NBLGGH4NNS1), then run Apps.bat again." -Level "ERROR"
    return $false
}

function Repair-LucidWingetSources {
    [CmdletBinding()]
    param ()

    $result = Invoke-LucidWinget -Arguments @("source", "update", "--disable-interactivity")
    if ($result.ExitCode -eq 0) {
        Write-LucidLog -Message "Winget sources updated successfully." -Level "SUCCESS"
    } else {
        Write-LucidLog -Message "Winget source update failed (exit code $($result.ExitCode)). Continuing with cached sources." -Level "WARNING"
    }
}

function Update-LucidApplications {
    [CmdletBinding()]
    param ()

    $result = Invoke-LucidWinget -Arguments @("upgrade", "--all", "--silent", "--disable-interactivity", "--accept-package-agreements", "--accept-source-agreements")
    switch ($result.ExitCode) {
        0 {
            Write-LucidLog -Message "Winget application upgrade completed successfully." -Level "SUCCESS"
        }
        { $_ -eq $script:WINGET_UPDATE_NOT_APPLICABLE } {
            Write-LucidLog -Message "All applications are already up to date." -Level "SUCCESS"
        }
        { $_ -eq $script:WINGET_UPDATE_ALL_HAS_FAILURE } {
            Write-LucidLog -Message "Winget upgrade completed with failures. Run 'winget upgrade' to see which packages failed." -Level "ERROR"
        }
        default {
            Write-LucidLog -Message "Winget upgrade failed (exit code $($result.ExitCode))." -Level "ERROR"
        }
    }
}

Export-ModuleMember -Function Invoke-LucidWinget, Test-LucidWingetAvailable, Repair-LucidWingetSources, Update-LucidApplications
