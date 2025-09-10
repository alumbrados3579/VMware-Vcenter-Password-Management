# VMware vCenter Password Management Tool - Setup Script
# Version 0.5 BETA - CLI Setup Edition
# Purpose: Complete automated setup and launch of the password management tool

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Global variables
$script:CurrentStep = 0
$script:TotalSteps = 6

function Show-DoDWarning {
    Clear-Host
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host "*** U.S. GOVERNMENT COMPUTER SYSTEM WARNING ***" -ForegroundColor Red
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You are accessing a U.S. Government (USG) Information System (IS) that is" -ForegroundColor White
    Write-Host "provided for USG-authorized use only." -ForegroundColor White
    Write-Host ""
    Write-Host "By using this IS (which includes any device attached to this IS), you consent" -ForegroundColor White
    Write-Host "to the following conditions:" -ForegroundColor White
    Write-Host ""
    Write-Host "- The USG routinely intercepts and monitors communications on this IS" -ForegroundColor Cyan
    Write-Host "- At any time, the USG may inspect and seize data stored on this IS" -ForegroundColor Cyan
    Write-Host "- Communications using, or data stored on, this IS are not private" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "VMware vCenter Password Management Tool - Version 0.5 BETA Setup" -ForegroundColor Green
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host ""
    $acknowledge = Read-Host "Type 'AGREE' to acknowledge and continue"
    if ($acknowledge -ne "AGREE") {
        Write-Host "Setup cancelled by user" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

function Write-Progress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )
    
    $script:CurrentStep++
    $progressChar = "="
    $emptyChar = " "
    $totalBars = 50
    $filledBars = [math]::Floor(($PercentComplete / 100) * $totalBars)
    $emptyBars = $totalBars - $filledBars
    
    $progressBar = ($progressChar * $filledBars) + ($emptyChar * $emptyBars)
    
    Write-Host ""
    Write-Host "[$script:CurrentStep/$script:TotalSteps] $Activity" -ForegroundColor Cyan
    Write-Host "[$progressBar] $PercentComplete%" -ForegroundColor Green
    Write-Host "Status: $Status" -ForegroundColor White
    Write-Host ""
}

function Write-DetailedStatus {
    param([string]$Message)
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Gray
}

function Initialize-PowerShellEnvironment {
    Write-Progress "Configuring PowerShell Environment" "Setting up PowerShell execution policy and environment..." 17
    
    try {
        Write-DetailedStatus "Setting execution policy to RemoteSigned (secure but allows local scripts)..."
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-DetailedStatus "[SUCCESS] Execution policy configured successfully"
        Write-DetailedStatus "   This allows local scripts while maintaining security for downloaded scripts"
    } catch {
        Write-DetailedStatus "[WARNING] Could not set execution policy: $($_.Exception.Message)"
    }
    
    try {
        Write-DetailedStatus "Enabling TLS 1.2 for secure downloads..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-DetailedStatus "[SUCCESS] TLS 1.2 enabled for secure connections"
    } catch {
        Write-DetailedStatus "[WARNING] Could not configure TLS: $($_.Exception.Message)"
    }
    
    Start-Sleep -Milliseconds 500
}

function Install-NuGetProvider {
    Write-Progress "Installing NuGet Provider" "Installing package management components..." 33
    
    try {
        Write-DetailedStatus "Checking for NuGet provider..."
        $nuget = Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue
        
        if (-not $nuget) {
            Write-DetailedStatus "Installing NuGet provider (required for PowerShell Gallery)..."
            Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
            Write-DetailedStatus "[SUCCESS] NuGet provider installed successfully"
        } else {
            Write-DetailedStatus "[SUCCESS] NuGet provider already installed (Version: $($nuget.Version))"
        }
    } catch {
        Write-DetailedStatus "[WARNING] Could not install NuGet provider: $($_.Exception.Message)"
    }
    
    Start-Sleep -Milliseconds 500
}

function Update-PowerShellGet {
    Write-Progress "Updating PowerShellGet Module" "Ensuring latest package management capabilities..." 50
    
    try {
        Write-DetailedStatus "Checking PowerShellGet module version..."
        $psGet = Get-Module -Name "PowerShellGet" -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        
        if ($psGet) {
            Write-DetailedStatus "Current PowerShellGet version: $($psGet.Version)"
        }
        
        # Check if PackageManagement is in use and handle gracefully
        $packageMgmt = Get-Module -Name "PackageManagement"
        if ($packageMgmt) {
            Write-DetailedStatus "PackageManagement v$($packageMgmt.Version) is currently loaded"
            Write-DetailedStatus "Skipping PowerShellGet update to avoid module conflicts"
            Write-DetailedStatus "[SUCCESS] Using existing PowerShellGet installation"
        } else {
            Write-DetailedStatus "Updating PowerShellGet module..."
            Install-Module -Name "PowerShellGet" -Force -Scope CurrentUser -AllowClobber
            Write-DetailedStatus "[SUCCESS] PowerShellGet module updated successfully"
        }
    } catch {
        Write-DetailedStatus "[WARNING] Could not update PowerShellGet: $($_.Exception.Message)"
        Write-DetailedStatus "This is often due to module conflicts and can be safely ignored"
    }
    
    Start-Sleep -Milliseconds 500
}

function Test-ExistingPowerCLI {
    param(
        [string]$LocalModulesPath
    )
    
    Write-DetailedStatus "Checking for existing PowerCLI installations..."
    
    # Check if PowerCLI is already loaded in memory
    $loadedPowerCLI = Get-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
    if ($loadedPowerCLI) {
        Write-DetailedStatus "[SUCCESS] VMware PowerCLI already loaded in current session"
        Write-DetailedStatus "   Version: $($loadedPowerCLI.Version)"
        Write-DetailedStatus "   Location: $($loadedPowerCLI.ModuleBase)"
        return $true
    }
    
    # Check local modules directory
    $localPowerCLIPath = Join-Path $LocalModulesPath "VMware.PowerCLI"
    if (Test-Path $localPowerCLIPath) {
        Write-DetailedStatus "Found local PowerCLI directory: $localPowerCLIPath"
        $manifestFiles = Get-ChildItem -Path $localPowerCLIPath -Filter "VMware.PowerCLI.psd1" -Recurse -ErrorAction SilentlyContinue
        
        if ($manifestFiles) {
            try {
                $manifestData = Import-PowerShellDataFile $manifestFiles[0].FullName
                Write-DetailedStatus "[SUCCESS] Valid PowerCLI installation found locally"
                Write-DetailedStatus "   Version: $($manifestData.ModuleVersion)"
                Write-DetailedStatus "   Location: $localPowerCLIPath"
                return $true
            } catch {
                Write-DetailedStatus "[WARNING] Local PowerCLI manifest is corrupted"
            }
        } else {
            Write-DetailedStatus "[WARNING] Local PowerCLI directory incomplete"
        }
    }
    
    # Check system-wide PowerCLI
    $systemPowerCLI = Get-Module -Name "VMware.PowerCLI" -ListAvailable -ErrorAction SilentlyContinue
    if ($systemPowerCLI) {
        Write-DetailedStatus "[SUCCESS] System-wide PowerCLI installation found"
        Write-DetailedStatus "   Version: $($systemPowerCLI.Version)"
        Write-DetailedStatus "   Location: $($systemPowerCLI.ModuleBase)"
        return $true
    }
    
    Write-DetailedStatus "[WARNING] No existing PowerCLI installation found"
    return $false
}

function Install-VMwarePowerCLI {
    Write-Progress "Installing VMware PowerCLI" "Checking existing installations and configuring VMware modules..." 67
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $localModulesPath = Join-Path $scriptRoot "Modules"
    
    try {
        Write-DetailedStatus "Creating local Modules directory for enterprise-safe installation..."
        if (-not (Test-Path $localModulesPath)) {
            New-Item -Path $localModulesPath -ItemType Directory -Force | Out-Null
            Write-DetailedStatus "[SUCCESS] Local Modules directory created: $localModulesPath"
        }
        
        Write-DetailedStatus "Adding local modules to PowerShell module path..."
        $currentPSModulePath = $env:PSModulePath
        if ($currentPSModulePath -notlike "*$localModulesPath*") {
            $env:PSModulePath = "$localModulesPath;$currentPSModulePath"
            Write-DetailedStatus "[SUCCESS] Local Modules directory added to PowerShell module path"
        }
        
        # Check for existing PowerCLI installations
        $powerCLIExists = Test-ExistingPowerCLI -LocalModulesPath $localModulesPath
        
        if (-not $powerCLIExists) {
            Write-DetailedStatus "No existing PowerCLI found - downloading to local directory..."
            Write-DetailedStatus "[INFO] This may take several minutes depending on your internet connection"
            Write-DetailedStatus "   Target directory: $localModulesPath"
            
            # Remove incomplete installation if it exists
            $localPowerCLIPath = Join-Path $localModulesPath "VMware.PowerCLI"
            if (Test-Path $localPowerCLIPath) {
                Write-DetailedStatus "Removing incomplete PowerCLI installation..."
                Remove-Item -Path $localPowerCLIPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Download PowerCLI modules to local directory
            Save-Module -Name "VMware.PowerCLI" -Path $localModulesPath -Force
            Write-DetailedStatus "[SUCCESS] VMware PowerCLI downloaded to local directory successfully"
        } else {
            Write-DetailedStatus "[SUCCESS] Using existing PowerCLI installation (no download needed)"
        }
        
        # Check if PowerCLI is already loaded in current session
        $loadedPowerCLI = Get-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
        
        if ($loadedPowerCLI) {
            Write-DetailedStatus "[SUCCESS] VMware PowerCLI already loaded in current session"
            Write-DetailedStatus "   Version: $($loadedPowerCLI.Version)"
            Write-DetailedStatus "   Location: $($loadedPowerCLI.ModuleBase)"
        } else {
            Write-DetailedStatus "Loading VMware PowerCLI modules..."
            Write-DetailedStatus "[INFO] This step may take 1-2 minutes - please be patient"
            
            try {
                Import-Module VMware.PowerCLI -ErrorAction Stop
                $loadedModule = Get-Module -Name "VMware.PowerCLI"
                Write-DetailedStatus "[SUCCESS] VMware PowerCLI loaded successfully"
                Write-DetailedStatus "   Version: $($loadedModule.Version)"
                
                if ($loadedModule.ModuleBase -like "*$localModulesPath*") {
                    Write-DetailedStatus "[SUCCESS] Using LOCAL modules (enterprise-safe installation)"
                } else {
                    Write-DetailedStatus "[WARNING] Using SYSTEM modules"
                }
            } catch {
                Write-DetailedStatus "[WARNING] Could not load PowerCLI, checking for conflicts..."
                
                $vmwareModules = Get-Module | Where-Object { $_.Name -like "VMware.*" }
                if ($vmwareModules) {
                    Write-DetailedStatus "Found existing VMware modules in memory:"
                    foreach ($module in $vmwareModules) {
                        Write-DetailedStatus "  - $($module.Name) v$($module.Version)"
                    }
                    Write-DetailedStatus "[SUCCESS] These modules are already loaded and working"
                } else {
                    throw "Failed to load PowerCLI: $($_.Exception.Message)"
                }
            }
        }
        
        Write-DetailedStatus "Configuring PowerCLI settings..."
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User -ErrorAction SilentlyContinue
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope User -ErrorAction SilentlyContinue
        Write-DetailedStatus "[SUCCESS] VMware PowerCLI configured and ready for use"
        
        return $true
    } catch {
        Write-DetailedStatus "[ERROR] Failed to install VMware PowerCLI: $($_.Exception.Message)"
        Write-DetailedStatus "Please check your internet connection and try again"
        return $false
    }
}

function Create-ConfigurationFiles {
    Write-Progress "Creating Configuration Files" "Setting up hosts.txt and users.txt configuration files..." 83
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    
    try {
        # Create hosts.txt
        $hostsFile = Join-Path $scriptRoot "hosts.txt"
        if (-not (Test-Path $hostsFile)) {
            $hostsContent = @"
# ESXi Hosts Configuration
# Add your ESXi host IP addresses or FQDNs below
# One host per line, comments start with #

# Examples:
# 192.168.1.100
# 192.168.1.101
# esxi-host-01.domain.local
# esxi-host-02.domain.local
"@
            $hostsContent | Set-Content -Path $hostsFile
            Write-DetailedStatus "[SUCCESS] Created hosts.txt configuration file"
        } else {
            Write-DetailedStatus "[SUCCESS] hosts.txt already exists"
        }
        
        # Create users.txt
        $usersFile = Join-Path $scriptRoot "users.txt"
        if (-not (Test-Path $usersFile)) {
            $usersContent = @"
# Target ESXi Users Configuration
# Add ESXi usernames for password operations
# One username per line, comments start with #
# Note: vCenter admin users (like administrator@vsphere.local) are entered directly in the GUI

# Common ESXi users:
root
# admin_swm
# admin_kms
# admin
# serviceaccount
"@
            $usersContent | Set-Content -Path $usersFile
            Write-DetailedStatus "[SUCCESS] Created users.txt configuration file"
        } else {
            Write-DetailedStatus "[SUCCESS] users.txt already exists"
        }
        
        Write-DetailedStatus "Configuration files are ready for customization"
        
    } catch {
        Write-DetailedStatus "[WARNING] Could not create configuration files: $($_.Exception.Message)"
    }
    
    Start-Sleep -Milliseconds 500
}

function Download-MainApplication {
    Write-Progress "Downloading Main Application" "Getting the latest GUI application from repository..." 100
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $mainTool = Join-Path $scriptRoot "VMware-Password-Manager.ps1"
    
    try {
        Write-DetailedStatus "Downloading latest VMware Password Manager GUI..."
        $guiUrl = "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Password-Manager.ps1"
        Invoke-WebRequest -Uri $guiUrl -OutFile $mainTool -UseBasicParsing
        Write-DetailedStatus "[SUCCESS] VMware Password Manager GUI downloaded successfully"
        Write-DetailedStatus "   Application ready to launch"
    } catch {
        Write-DetailedStatus "[WARNING] Could not download GUI application: $($_.Exception.Message)"
        Write-DetailedStatus "You can manually download VMware-Password-Manager.ps1 from GitHub"
    }
    
    Start-Sleep -Milliseconds 500
}

function Complete-Setup {
    Write-Progress "Setup Complete!" "All components installed and configured successfully" 100
    
    Write-Host ""
    Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Green
    Write-Host "[SUCCESS] PowerShell environment configured" -ForegroundColor Green
    Write-Host "[SUCCESS] VMware PowerCLI installed and ready" -ForegroundColor Green
    Write-Host "[SUCCESS] Configuration files created" -ForegroundColor Green
    Write-Host "[SUCCESS] Main application downloaded" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Configure your ESXi hosts and users" -ForegroundColor White
    Write-Host "2. Test vCenter connectivity" -ForegroundColor White
    Write-Host "3. Run password operations (Dry Run first!)" -ForegroundColor White
    Write-Host ""
    
    $launch = Read-Host "Would you like to launch the VMware Password Manager now? (Y/N)"
    if ($launch -eq "Y" -or $launch -eq "y") {
        $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
        $mainTool = Join-Path $scriptRoot "VMware-Password-Manager.ps1"
        if (Test-Path $mainTool) {
            Write-Host "Launching VMware Password Manager..." -ForegroundColor Green
            Start-Process PowerShell -ArgumentList "-File `"$mainTool`"" -WindowStyle Normal
        } else {
            Write-Host "Main application file not found: $mainTool" -ForegroundColor Red
        }
    }
}

function Start-SetupProcess {
    try {
        Initialize-PowerShellEnvironment
        Install-NuGetProvider
        Update-PowerShellGet
        $powerCLISuccess = Install-VMwarePowerCLI
        Create-ConfigurationFiles
        Download-MainApplication
        
        if ($powerCLISuccess) {
            Complete-Setup
        } else {
            Write-Host "Setup completed with warnings. Check output for issues." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Main execution
Show-DoDWarning
Start-SetupProcess