# ============================================================================
# Project LUCID - First Run v1.0
# Module: OneDrive.psm1
# ============================================================================

function Remove-LucidOneDrive {
    [CmdletBinding()]
    param ()

    Write-LucidLog -Message "Removing OneDrive..." -Level "INFO"

    # 1. Stop OneDrive process if running
    try {
        $oneDriveProcesses = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
        if ($oneDriveProcesses) {
            Write-LucidLog -Message "Stopping running OneDrive processes..." -Level "INFO"
            $oneDriveProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-LucidLog -Message "Error stopping OneDrive process: $_" -Level "WARNING"
    }

    # 2. Locate official uninstaller executable
    $uninstallerPaths = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:LocalAppData\Microsoft\OneDrive\OneDriveSetup.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDriveSetup.exe"
    )

    $uninstallerFound = $false
    foreach ($path in $uninstallerPaths) {
        if (Test-Path -Path $path) {
            $uninstallerFound = $true
            Write-LucidLog -Message "Executing official OneDrive uninstaller ($path)..." -Level "INFO"
            try {
                $process = Start-Process -FilePath $path -ArgumentList "/uninstall" -PassThru -NoNewWindow -Wait -ErrorAction Stop
                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq $null) {
                    Write-LucidLog -Message "Official OneDrive uninstaller completed successfully." -Level "SUCCESS"
                } else {
                    Write-LucidLog -Message "OneDrive uninstaller exited with code $($process.ExitCode)." -Level "WARNING"
                }
            } catch {
                Write-LucidLog -Message "Failed to execute OneDrive uninstaller: $_" -Level "WARNING"
            }
            break
        }
    }

    if (-not $uninstallerFound) {
        Write-LucidLog -Message "OneDrive official setup executable not found; proceeding with startup and residual cleanup." -Level "INFO"
    }

    # 3. Remove startup registry entry
    try {
        $runKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $runProp = Get-ItemProperty -Path $runKeyPath -Name "OneDrive" -ErrorAction SilentlyContinue
        if ($runProp) {
            Remove-ItemProperty -Path $runKeyPath -Name "OneDrive" -Force -ErrorAction Stop
            Write-LucidLog -Message "Removed OneDrive startup registry entry." -Level "SUCCESS"
        } else {
            Write-LucidLog -Message "OneDrive startup entry is not present." -Level "SUCCESS"
        }
    } catch {
        Write-LucidLog -Message "Failed to remove OneDrive startup key: $_" -Level "WARNING"
    }

    # 4. Cleanup leftover directory in LocalAppData
    try {
        $localOneDriveDir = "$env:LocalAppData\Microsoft\OneDrive"
        if (Test-Path -Path $localOneDriveDir) {
            Remove-Item -Path $localOneDriveDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-LucidLog -Message "Cleaned up leftover OneDrive directory." -Level "SUCCESS"
        }
    } catch {
        Write-LucidLog -Message "Could not remove OneDrive leftover directory: $_" -Level "WARNING"
    }
}

Export-ModuleMember -Function Remove-LucidOneDrive
