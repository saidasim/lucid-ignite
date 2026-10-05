# ============================================================================
# LUCID Ignite v1.0
# Module: Logging.psm1
# ============================================================================

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$script:LogFilePath = $null
$script:CompletedCount = 0
$script:WarningCount = 0
$script:ErrorCount = 0

function Initialize-LucidLogging {
    [CmdletBinding()]
    param (
        [string]$LogDirectory,
        [string]$LogPrefix = "LUCID_Log"
    )

    if (-not (Test-Path -Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:LogFilePath = Join-Path -Path $LogDirectory -ChildPath "${LogPrefix}_$timestamp.log"

    # Reset counters
    $script:CompletedCount = 0
    $script:WarningCount = 0
    $script:ErrorCount = 0

    $headerText = "============================================================================`r`n" +
                  " LUCID Ignite - Execution Log ($LogPrefix)`r`n" +
                  " Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n" +
                  " OS: $([System.Environment]::OSVersion.VersionString)`r`n" +
                  "============================================================================`r`n"

    Add-Content -Path $script:LogFilePath -Value $headerText -Encoding UTF8
    return $script:LogFilePath
}

function Write-LucidLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $formattedLog = "[$timestamp] [$Level] $Message"

    # Console output with colors
    switch ($Level) {
        "INFO" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
            Write-Host "[INFO] " -NoNewline -ForegroundColor Cyan
            Write-Host $Message -ForegroundColor White
        }
        "SUCCESS" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
            Write-Host "[SUCCESS] " -NoNewline -ForegroundColor Green
            Write-Host $Message -ForegroundColor White
            $script:CompletedCount++
        }
        "WARNING" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
            Write-Host "[WARNING] " -NoNewline -ForegroundColor Yellow
            Write-Host $Message -ForegroundColor Yellow
            $script:WarningCount++
        }
        "ERROR" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
            Write-Host "[ERROR] " -NoNewline -ForegroundColor Red
            Write-Host $Message -ForegroundColor Red
            $script:ErrorCount++
        }
    }

    # Write to log file if initialized
    if ($script:LogFilePath -and (Test-Path -Path (Split-Path -Path $script:LogFilePath -Parent))) {
        try {
            Add-Content -Path $script:LogFilePath -Value $formattedLog -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch {
            # Ignore file write failures silently
        }
    }
}

function Get-LucidStats {
    return @{
        Completed = $script:CompletedCount
        Warnings  = $script:WarningCount
        Errors    = $script:ErrorCount
    }
}

Export-ModuleMember -Function Initialize-LucidLogging, Write-LucidLog, Get-LucidStats
