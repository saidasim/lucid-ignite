# ============================================================================
# LUCID Ignite v1.0
# Module: Apps.psm1
# ============================================================================
# Install policy: Microsoft Store first (exact Store ID). If the app is not on
# the Store or the Store install fails, fall back to the winget community
# repository, which downloads the vendor's official installer and verifies its hash.

# -1978335135 = 0x8A150061 PACKAGE_ALREADY_INSTALLED, -1978335189 = 0x8A15002B UPDATE_NOT_APPLICABLE
# 29, 1638    = installer-specific "already installed" codes kept from v1.0
$script:AlreadyInstalledCodes = @(-1978335135, -1978335189, 29, 1638)

function Test-LucidPackageInstalled {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    $result = Invoke-LucidWinget -Arguments @("list", "--id", $Id, "--exact", "--accept-source-agreements", "--disable-interactivity")
    return ($result.ExitCode -eq 0)
}

function Install-LucidWingetPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [ValidateSet("msstore", "winget")]
        [string]$Source,

        [switch]$Interactive
    )

    $arguments = @("install", "--id", $Id, "--exact", "--source", $Source, "--accept-package-agreements", "--accept-source-agreements")
    if (-not $Interactive) {
        $arguments += @("--silent", "--disable-interactivity")
    }

    $result = Invoke-LucidWinget -Arguments $arguments
    if ($result.ExitCode -eq 0) { return "Installed" }
    if ($script:AlreadyInstalledCodes -contains $result.ExitCode) { return "AlreadyInstalled" }
    return "Failed:$($result.ExitCode)"
}

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
        $packages = @(Get-Content -Path $PackagesJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch {
        Write-LucidLog -Message "Failed to parse packages.json: $_" -Level "ERROR"
        return
    }

    Write-LucidLog -Message "Starting installation of $($packages.Count) target applications..." -Level "INFO"

    foreach ($package in $packages) {
        $name = $package.name
        if (-not $name -or -not $package.winget) {
            Write-LucidLog -Message "Invalid entry in packages.json (name and winget are required). Skipping." -Level "ERROR"
            continue
        }

        Write-LucidLog -Message "Processing $name..." -Level "INFO"

        $isInstalled = Test-LucidPackageInstalled -Id $package.winget
        if (-not $isInstalled -and $package.store) {
            $isInstalled = Test-LucidPackageInstalled -Id $package.store
        }
        if ($isInstalled) {
            Write-LucidLog -Message "$name is already installed." -Level "SUCCESS"
            continue
        }

        # Priority 1: Microsoft Store
        if ($package.store) {
            Write-LucidLog -Message "Installing $name from Microsoft Store ($($package.store))..." -Level "INFO"
            $status = Install-LucidWingetPackage -Id $package.store -Source "msstore"
            if ($status -eq "Installed") {
                Write-LucidLog -Message "$name installed successfully via Microsoft Store." -Level "SUCCESS"
                continue
            }
            if ($status -eq "AlreadyInstalled") {
                Write-LucidLog -Message "$name is already installed." -Level "SUCCESS"
                continue
            }
            Write-LucidLog -Message "Microsoft Store installation of $name failed ($status). Falling back to the official installer via winget." -Level "WARNING"
        } else {
            Write-LucidLog -Message "$name is not available on Microsoft Store. Using the official installer via winget." -Level "INFO"
        }

        # Priority 2: official installer via winget (silent, then interactive)
        $status = Install-LucidWingetPackage -Id $package.winget -Source "winget"
        if ($status -like "Failed:*") {
            Write-LucidLog -Message "Silent installation of $name failed ($status). Retrying with the installer window..." -Level "INFO"
            $status = Install-LucidWingetPackage -Id $package.winget -Source "winget" -Interactive
        }

        switch -Wildcard ($status) {
            "Installed"        { Write-LucidLog -Message "$name installed successfully via winget ($($package.winget))." -Level "SUCCESS" }
            "AlreadyInstalled" { Write-LucidLog -Message "$name is already installed." -Level "SUCCESS" }
            default            { Write-LucidLog -Message "Failed to install $name ($status)." -Level "ERROR" }
        }
    }
}

Export-ModuleMember -Function Install-LucidApplications
