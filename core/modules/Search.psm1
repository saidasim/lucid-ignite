# ============================================================================
# LUCID Ignite v1.0
# Module: Search.psm1
# ============================================================================

function Invoke-LucidSearchTweaks {
    [CmdletBinding()]
    param ()

    Write-LucidLog -Message "Applying Windows Search tweaks..." -Level "INFO"

    # Disable Bing Search box suggestions & cloud search
    $null = Set-LucidRegistry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
                              -Name "DisableSearchBoxSuggestions" `
                              -Value 1 `
                              -PropertyType "DWord" `
                              -Description "Disable Search Box Suggestions"

    $null = Set-LucidRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                              -Name "BingSearchEnabled" `
                              -Value 0 `
                              -PropertyType "DWord" `
                              -Description "Disable Bing Search in Windows Search"
}

Export-ModuleMember -Function Invoke-LucidSearchTweaks
