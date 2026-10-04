# ============================================================================
# Project LUCID - First Run v1.0
# Module: Apps.psm1
# ============================================================================

function Install-LucidApplications {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackagesJsonPath
    )

    if (-not (Test-Path -Path $PackagesJsonPath)) {
        Write-LucidLog -Message "Packages configuration file not found at: $PackagesJsonPath" -Level "ERROR"
        return
    }

    try {
        $packageIds = Get-Content -Path $PackagesJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-LucidLog -Message "Failed to parse packages.json: $_" -Level "ERROR"
        return
    }

    Write-LucidLog -Message "Starting installation of $($packageIds.Count) target applications..." -Level "INFO"

    foreach ($packageId in $packageIds) {
        Write-LucidLog -Message "Processing package: $packageId" -Level "INFO"

        $appName = ($packageId -split '\.')[-1]
        $isInstalled = $false

        # Check if already installed
        try {
            $listOutput = winget list --query $packageId --accept-source-agreements --disable-interactivity 2>&1 | Out-String
            if (-not $listOutput -or $listOutput -notmatch [regex]::Escape($appName)) {
                $listOutput = winget list --query $appName --accept-source-agreements --disable-interactivity 2>&1 | Out-String
            }

            if ($listOutput -and ($listOutput -match [regex]::Escape($packageId) -or $listOutput -match [regex]::Escape($appName))) {
                $isInstalled = $true
            }
        } catch {
            $isInstalled = $false
        }

        if ($isInstalled) {
            Write-LucidLog -Message "$packageId is already installed." -Level "WARNING"
            continue
        }

        $installed = $false

        # --------------------------------------------------------------------
        # Priority 1: Try Microsoft Store (msstore) Source First
        # --------------------------------------------------------------------
        try {
            Write-LucidLog -Message "Attempting installation via Microsoft Store (msstore) for $appName..." -Level "INFO"
            winget install --query $appName --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0) {
                Write-LucidLog -Message "$packageId installed successfully via Microsoft Store." -Level "SUCCESS"
                $installed = $true
            } elseif ($exitCode -eq -1978335189 -or $exitCode -eq 29 -or $exitCode -eq 1638) {
                Write-LucidLog -Message "$packageId is already installed." -Level "WARNING"
                $installed = $true
            }
        } catch {
            $installed = $false
        }

        # --------------------------------------------------------------------
        # Priority 2: Fallback to Community (winget) Source
        # --------------------------------------------------------------------
        if (-not $installed) {
            Write-LucidLog -Message "Falling back to winget community repository for $packageId..." -Level "INFO"

            # Attempt 2A: Winget source with --silent
            try {
                winget install --id $packageId --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                $exitCodeSilent = $LASTEXITCODE

                if ($exitCodeSilent -eq 0) {
                    Write-LucidLog -Message "$packageId installed successfully via winget repository." -Level "SUCCESS"
                    $installed = $true
                } elseif ($exitCodeSilent -eq -1978335189 -or $exitCodeSilent -eq 29 -or $exitCodeSilent -eq 1638) {
                    Write-LucidLog -Message "$packageId is already installed." -Level "WARNING"
                    $installed = $true
                }
            } catch {
                $installed = $false
            }

            # Attempt 2B: Winget source standard fallback
            if (-not $installed) {
                try {
                    winget install --id $packageId --exact --source winget --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                    $exitCodeStd = $LASTEXITCODE

                    if ($exitCodeStd -eq 0) {
                        Write-LucidLog -Message "$packageId installed successfully." -Level "SUCCESS"
                    } elseif ($exitCodeStd -eq -1978335189 -or $exitCodeStd -eq 29 -or $exitCodeStd -eq 1638) {
                        Write-LucidLog -Message "$packageId is already installed." -Level "WARNING"
                    } else {
                        Write-LucidLog -Message "Failed to install $packageId (Exit code: $exitCodeStd)." -Level "ERROR"
                    }
                } catch {
                    Write-LucidLog -Message "Exception occurred while installing ${packageId}: $_" -Level "ERROR"
                }
            }
        }
    }
}

Export-ModuleMember -Function Install-LucidApplications
