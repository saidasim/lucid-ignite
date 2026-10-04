# ============================================================================
# Project LUCID - First Run v1.0
# Module: Winget.psm1
# ============================================================================

function Test-LucidWingetAvailable {
    [CmdletBinding()]
    param ()

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    return ($null -ne $wingetCmd)
}

function Repair-LucidWingetSources {
    [CmdletBinding()]
    param ()

    Write-LucidLog -Message "Updating Winget package sources..." -Level "INFO"

    try {
        winget source update --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
        Write-LucidLog -Message "Winget sources updated successfully." -Level "SUCCESS"
    } catch {
        Write-LucidLog -Message "Winget source update encountered a non-critical issue: $_" -Level "WARNING"
    }
}

function Update-LucidApplications {
    [CmdletBinding()]
    param ()

    Write-LucidLog -Message "Upgrading installed Winget packages..." -Level "INFO"

    try {
        winget upgrade --all --silent --disable-interactivity --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        Write-LucidLog -Message "Winget application upgrade completed successfully." -Level "SUCCESS"
    } catch {
        Write-LucidLog -Message "Winget upgrade command failed: $_" -Level "WARNING"
    }
}

Export-ModuleMember -Function Test-LucidWingetAvailable, Repair-LucidWingetSources, Update-LucidApplications
