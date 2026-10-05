# ============================================================================
# LUCID Ignite v1.0
# Module: Explorer.psm1
# ============================================================================

function Invoke-LucidExplorerTweaks {
    [CmdletBinding()]
    param ()

    Write-LucidLog -Message "Applying Explorer & Visual Performance tweaks..." -Level "INFO"

    # FontSmoothing = "2" (String)
    $null = Set-LucidRegistry -Path "HKCU:\Control Panel\Desktop" `
                              -Name "FontSmoothing" `
                              -Value "2" `
                              -PropertyType "String" `
                              -Description "Enable Font Smoothing"

    # VisualFXSetting = 3 (DWord)
    $null = Set-LucidRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
                              -Name "VisualFXSetting" `
                              -Value 3 `
                              -PropertyType "DWord" `
                              -Description "Set Visual Effects setting"

    # TaskbarAnimations = 0 (DWord)
    $null = Set-LucidRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                              -Name "TaskbarAnimations" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Taskbar Animations"

    # MinAnimate = "0" (String)
    $null = Set-LucidRegistry -Path "HKCU:\Control Panel\Desktop\WindowMetrics" `
                              -Name "MinAnimate" `
                              -Value "0" `
                              -PropertyType "String" `
                              -Description "Disable Window Minimize/Maximize Animations"

    # RotatingLockScreenOverlayEnabled = 0 (DWord)
    $null = Set-LucidRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                              -Name "RotatingLockScreenOverlayEnabled" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Rotating Lock Screen Overlay"

    # Start_TrackDocs = 1 (DWord)
    $null = Set-LucidRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                              -Name "Start_TrackDocs" `
                              -Value 1 `
                              -PropertyType "DWord" `
                              -Description "Enable Recent Documents Tracking in Start Menu"
}

Export-ModuleMember -Function Invoke-LucidExplorerTweaks
