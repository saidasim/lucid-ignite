# ============================================================================
# Project LUCID - First Run v1.0
# Module: Graphics.psm1
# ============================================================================

function Invoke-LucidGraphicsTweaks {
    [CmdletBinding()]
    param ()

    Write-LucidLog -Message "Applying Graphics configuration..." -Level "INFO"

    # HAGS (Hardware-Accelerated GPU Scheduling): 2 = Enabled
    $null = Set-LucidRegistry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
                              -Name "HwSchMode" `
                              -Value 2 `
                              -PropertyType "DWord" `
                              -Description "Enable Hardware-Accelerated GPU Scheduling (HAGS)"
}

Export-ModuleMember -Function Invoke-LucidGraphicsTweaks
