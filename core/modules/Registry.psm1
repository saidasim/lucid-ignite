# ============================================================================
# Project LUCID - First Run v1.0
# Module: Registry.psm1
# ============================================================================

function Set-LucidRegistry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DWord", "QWord", "String", "ExpandString", "MultiString", "Binary")]
        [string]$PropertyType = "DWord",

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    $displayName = if ($Description) { $Description } else { "$Path -> $Name" }

    try {
        # Ensure parent key exists
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        # Check existing value for idempotency
        $existingProperty = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $existingProperty -and $existingProperty.$Name -eq $Value) {
            Write-LucidLog -Message "$displayName is already configured correctly." -Level "SUCCESS"
            return $true
        }

        # Set registry property
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $PropertyType -Force -ErrorAction Stop

        # Validate write
        $verifyProperty = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $verifyProperty -and $verifyProperty.$Name -eq $Value) {
            Write-LucidLog -Message "Successfully updated $displayName to '$Value'." -Level "SUCCESS"
            return $true
        } else {
            Write-LucidLog -Message "Validation failed for $displayName." -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-LucidLog -Message "Failed to set $displayName. Error: $_" -Level "ERROR"
        return $false
    }
}

Export-ModuleMember -Function Set-LucidRegistry
