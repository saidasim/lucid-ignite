# ============================================================================
# Project LUCID - First Run v1.0
# Module: Privacy.psm1
# ============================================================================

function Invoke-LucidPrivacyTweaks {
    [CmdletBinding()]
    param ()

    Write-LucidLog -Message "Applying Privacy and Telemetry tweaks..." -Level "INFO"

    # 1. Telemetry Policy
    $null = Set-LucidRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
                              -Name "AllowTelemetry" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Telemetry (Group Policy)"

    $null = Set-LucidRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
                              -Name "AllowTelemetry" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Telemetry (System Policy)"

    # Service: DiagTrack (Connected User Experiences and Telemetry)
    try {
        $diagTrackService = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($null -ne $diagTrackService) {
            if ($diagTrackService.Status -eq "Running") {
                Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
            }
            if ($diagTrackService.StartType -ne "Disabled") {
                Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
                Write-LucidLog -Message "Disabled DiagTrack service." -Level "SUCCESS"
            } else {
                Write-LucidLog -Message "DiagTrack service is already disabled." -Level "SUCCESS"
            }
        }
    } catch {
        Write-LucidLog -Message "Could not configure DiagTrack service: $_" -Level "WARNING"
    }

    # 2. Cortana
    $null = Set-LucidRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
                              -Name "AllowCortana" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Cortana"

    # 3. Bing Search & Search Box Suggestions
    $null = Set-LucidRegistry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
                              -Name "DisableSearchBoxSuggestions" `
                              -Value 1 `
                              -PropertyType "DWord" `
                              -Description "Disable Search Box Suggestions"

    $null = Set-LucidRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                              -Name "BingSearchEnabled" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Bing Search in Start Menu"

    $null = Set-LucidRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                              -Name "CortanaConsent" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Cortana Consent"
}

Export-ModuleMember -Function Invoke-LucidPrivacyTweaks
