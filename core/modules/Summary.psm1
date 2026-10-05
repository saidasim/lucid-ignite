# ============================================================================
# LUCID Ignite v1.0
# Module: Summary.psm1
# ============================================================================

function Show-LucidSummary {
    [CmdletBinding()]
    param (
        [string]$Title = "EXECUTION SUMMARY REPORT",
        [string]$LabelCompleted = "Completed",
        [string]$LabelWarnings = "Warnings",
        [string]$LabelErrors = "Errors",
        [string]$LabelRestart = "Recommended"
    )

    $stats = Get-LucidStats

    $summaryHeader = "`r`n============================================================================`r`n" +
                     "                      $Title                                                `r`n" +
                     "============================================================================`r`n"
    Write-Host $summaryHeader -ForegroundColor Cyan

    Write-Host "${LabelCompleted} : " -NoNewline -ForegroundColor White
    Write-Host "$($stats.Completed)" -ForegroundColor Green

    Write-Host "`r`n${LabelWarnings}  : " -NoNewline -ForegroundColor White
    Write-Host "$($stats.Warnings)" -ForegroundColor Yellow

    Write-Host "`r`n${LabelErrors}    : " -NoNewline -ForegroundColor White
    Write-Host "$($stats.Errors)" -ForegroundColor Red

    Write-Host "`r`nRestart   : " -NoNewline -ForegroundColor White
    Write-Host "$LabelRestart" -ForegroundColor Magenta

    Write-Host "`r`n============================================================================`r`n" -ForegroundColor Cyan

    # Also record in log file
    Write-LucidLog -Message "Summary -> ${LabelCompleted}: $($stats.Completed) | ${LabelWarnings}: $($stats.Warnings) | ${LabelErrors}: $($stats.Errors) | Restart: $LabelRestart" -Level "INFO"
}

Export-ModuleMember -Function Show-LucidSummary
