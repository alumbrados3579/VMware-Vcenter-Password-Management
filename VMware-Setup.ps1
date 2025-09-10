# VMware vCenter Password Management Tool - Setup Script
# Version 2.0 - PowerShell Gallery Edition
# Purpose: Setup PowerCLI from PowerShell Gallery and launch the management tool

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# --- DoD Warning Banner ---
function Show-DoDWarning {
    $dodWarning = @"
*** U.S. GOVERNMENT COMPUTER SYSTEM WARNING ***

You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.
By using this IS (which includes any device attached to this IS), you consent to the following conditions:

- The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, 
  penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), 
  law enforcement (LE), and counterintelligence (CI) investigations.
- At any time, the USG may inspect and seize data stored on this IS.
- Communications using, or data stored on, this IS are not private, are subject to routine monitoring, 
  interception, and search, and may be disclosed or used for any USG-authorized purpose.
- This IS includes security mechanisms to protect USG interests--not for your personal benefit or privacy.

VMware vCenter Password Management Tool - DoD Compliant Edition
This tool provides secure password management for VMware vCenter and ESXi environments.

Press Enter to acknowledge and continue...
"@
    
    Write-Host $dodWarning -ForegroundColor Yellow
    Read-Host
}

# --- PowerShell Environment Setup ---
function Initialize-PowerShellEnvironment {
    Write-Host "=== Initializing PowerShell Environment ===" -ForegroundColor Cyan
    
    # Set execution policy (RemoteSigned is better than Bypass for security)
    try {
        Write-Host "Setting execution policy to RemoteSigned (secure but allows local scripts)..." -ForegroundColor Green
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "✅ Execution policy set to RemoteSigned for CurrentUser" -ForegroundColor Green
        Write-Host "   This allows local scripts while maintaining security for downloaded scripts" -ForegroundColor Cyan
    } catch {
        Write-Host "⚠️ Warning: Could not set execution policy: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Ensure TLS 1.2 for secure downloads
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Host "✅ TLS 1.2 enabled for secure downloads" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Warning: Could not set TLS 1.2" -ForegroundColor Yellow
    }
    
    # Add PowerShell Gallery to trusted repositories
    try {
        Write-Host "Configuring PowerShell Gallery..." -ForegroundColor Green
        if (-not (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Default
        }
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        Write-Host "✅ PowerShell Gallery configured as trusted repository" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Warning: Could not configure PowerShell Gallery: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# --- NuGet Provider Setup ---
function Install-NuGetProvider {
    Write-Host "=== Checking NuGet Provider ===" -ForegroundColor Cyan
    
    try {
        $nugetProvider = Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue
        if (-not $nugetProvider) {
            Write-Host "Installing NuGet package provider..." -ForegroundColor Green
            Install-PackageProvider -Name "NuGet" -Force -Scope CurrentUser
            Write-Host "✅ NuGet provider installed successfully" -ForegroundColor Green
        } else {
            Write-Host "✅ NuGet provider already available (Version: $($nugetProvider.Version))" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Failed to install NuGet provider: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "This may affect module installation capabilities" -ForegroundColor Yellow
    }
}

# --- PowerShellGet Module Update ---
function Update-PowerShellGet {
    Write-Host "=== Checking PowerShellGet Module ===" -ForegroundColor Cyan
    
    try {
        $psGetModule = Get-Module -Name "PowerShellGet" -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        
        if (-not $psGetModule -or $psGetModule.Version -lt [Version]"2.0.0") {
            Write-Host "Updating PowerShellGet module..." -ForegroundColor Green
            Install-Module -Name "PowerShellGet" -Force -Scope CurrentUser -AllowClobber
            Write-Host "✅ PowerShellGet module updated" -ForegroundColor Green
            Write-Host "⚠️ Please restart PowerShell and run this script again for best results" -ForegroundColor Yellow
        } else {
            Write-Host "✅ PowerShellGet module is current (Version: $($psGetModule.Version))" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Warning: Could not update PowerShellGet: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# --- VMware PowerCLI Local Installation ---
function Install-VMwarePowerCLI {
    Write-Host "=== Installing VMware PowerCLI to Local Modules Directory ===" -ForegroundColor Cyan
    Write-Host "This avoids OneDrive sync issues and keeps modules in your working directory" -ForegroundColor Yellow
    
    # Get script directory and create local Modules path
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $localModulesPath = Join-Path $scriptRoot "Modules"
    
    try {
        # Create local Modules directory if it doesn't exist
        if (-not (Test-Path $localModulesPath)) {
            Write-Host "Creating local Modules directory: $localModulesPath" -ForegroundColor Green
            New-Item -Path $localModulesPath -ItemType Directory -Force | Out-Null
        }
        
        # Add local modules path to PSModulePath (highest priority)
        $currentPSModulePath = $env:PSModulePath
        if ($currentPSModulePath -notlike "*$localModulesPath*") {
            $env:PSModulePath = "$localModulesPath;$currentPSModulePath"
            Write-Host "✅ Added local Modules directory to PowerShell module path" -ForegroundColor Green
        }
        
        # Check if PowerCLI is already available locally (thorough check)
        $localPowerCLIPath = Join-Path $localModulesPath "VMware.PowerCLI"
        $powerCLIExists = $false
        
        if (Test-Path $localPowerCLIPath) {
            # Check for PowerCLI manifest file to verify it's a complete installation
            $manifestFiles = Get-ChildItem -Path $localPowerCLIPath -Filter "VMware.PowerCLI.psd1" -Recurse -ErrorAction SilentlyContinue
            
            if ($manifestFiles) {
                try {
                    $manifestData = Import-PowerShellDataFile $manifestFiles[0].FullName
                    Write-Host "✅ VMware PowerCLI found in local Modules directory" -ForegroundColor Green
                    Write-Host "Local PowerCLI Version: $($manifestData.ModuleVersion)" -ForegroundColor Cyan
                    Write-Host "Location: $localPowerCLIPath" -ForegroundColor Gray
                    $powerCLIExists = $true
                } catch {
                    Write-Host "⚠️ Local PowerCLI found but manifest is corrupted, will re-download" -ForegroundColor Yellow
                }
            } else {
                Write-Host "⚠️ Local PowerCLI directory exists but appears incomplete, will re-download" -ForegroundColor Yellow
            }
        }
        
        if (-not $powerCLIExists) {
            Write-Host "Downloading VMware PowerCLI to local Modules directory..." -ForegroundColor Green
            Write-Host "This may take a few minutes and avoids OneDrive sync conflicts" -ForegroundColor Yellow
            Write-Host "Target directory: $localModulesPath" -ForegroundColor Gray
            
            # Remove incomplete installation if it exists
            if (Test-Path $localPowerCLIPath) {
                Write-Host "Removing incomplete PowerCLI installation..." -ForegroundColor Yellow
                Remove-Item -Path $localPowerCLIPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Download PowerCLI modules to local directory
            Save-Module -Name "VMware.PowerCLI" -Path $localModulesPath -Force
            Write-Host "✅ VMware PowerCLI downloaded to local Modules directory" -ForegroundColor Green
        } else {
            Write-Host "✅ Using existing local PowerCLI installation (no download needed)" -ForegroundColor Green
        }
        
        # Check if PowerCLI is already loaded in current session
        $loadedPowerCLI = Get-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
        
        if ($loadedPowerCLI) {
            Write-Host "✅ VMware PowerCLI already loaded in current session" -ForegroundColor Green
            Write-Host "Version: $($loadedPowerCLI.Version)" -ForegroundColor Cyan
            Write-Host "Location: $($loadedPowerCLI.ModuleBase)" -ForegroundColor Cyan
        } else {
            # Try to import the module
            Write-Host "Loading VMware PowerCLI..." -ForegroundColor Green
            try {
                # Try to import without forcing to avoid conflicts
                Import-Module VMware.PowerCLI -ErrorAction Stop
                Write-Host "✅ VMware PowerCLI loaded successfully" -ForegroundColor Green
            } catch {
                Write-Host "⚠️ Could not load PowerCLI, checking for conflicts..." -ForegroundColor Yellow
                
                # Check if any VMware modules are already loaded
                $vmwareModules = Get-Module | Where-Object { $_.Name -like "VMware.*" }
                if ($vmwareModules) {
                    Write-Host "Found existing VMware modules in memory:" -ForegroundColor Yellow
                    foreach ($module in $vmwareModules) {
                        Write-Host "  - $($module.Name) v$($module.Version)" -ForegroundColor Gray
                    }
                    Write-Host "These modules are already loaded and working. Continuing..." -ForegroundColor Green
                } else {
                    # Fallback: try to install system-wide if local fails
                    try {
                        Write-Host "Attempting system-wide installation..." -ForegroundColor Yellow
                        Install-Module -Name "VMware.PowerCLI" -Scope CurrentUser -Force -AllowClobber
                        Import-Module VMware.PowerCLI -Force
                        Write-Host "✅ VMware PowerCLI installed and loaded from system location" -ForegroundColor Green
                    } catch {
                        throw "Failed to install PowerCLI: $($_.Exception.Message)"
                    }
                }
            }
        }
        
        # Configure PowerCLI settings
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User -ErrorAction SilentlyContinue
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope User -ErrorAction SilentlyContinue
        
        Write-Host "✅ VMware PowerCLI configured and ready" -ForegroundColor Green
        
        # Display PowerCLI version and location info
        try {
            $powerCLIModule = Get-Module -Name "VMware.PowerCLI"
            if ($powerCLIModule) {
                Write-Host "VMware PowerCLI Version: $($powerCLIModule.Version)" -ForegroundColor Cyan
                Write-Host "Module Location: $($powerCLIModule.ModuleBase)" -ForegroundColor Cyan
                
                if ($powerCLIModule.ModuleBase -like "*$localModulesPath*") {
                    Write-Host "✅ Using LOCAL modules (OneDrive-safe)" -ForegroundColor Green
                } else {
                    Write-Host "⚠️ Using SYSTEM modules" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "PowerCLI loaded but version info unavailable" -ForegroundColor Cyan
        }
        
        return $true
    } catch {
        Write-Host "❌ Failed to install VMware PowerCLI: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please check your internet connection and PowerShell Gallery access" -ForegroundColor Yellow
        Write-Host "Local Modules Path: $localModulesPath" -ForegroundColor Gray
        return $false
    }
}

# --- Create Configuration Files ---
function Create-ConfigurationFiles {
    Write-Host "=== Creating Configuration Files ===" -ForegroundColor Cyan
    
    $scriptRoot = $PSScriptRoot
    if (-not $scriptRoot) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
    }
    
    # Create hosts.txt if it doesn't exist
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
        Write-Host "✅ Created hosts.txt configuration file" -ForegroundColor Green
    } else {
        Write-Host "✅ hosts.txt configuration file already exists" -ForegroundColor Green
    }
    
    # Create users.txt if it doesn't exist
    $usersFile = Join-Path $scriptRoot "users.txt"
    if (-not (Test-Path $usersFile)) {
        $usersContent = @"
# Target Users Configuration
# Add usernames that can be targeted for password changes
# One username per line, comments start with #

# Common ESXi users:
root
# admin
# serviceaccount
"@
        $usersContent | Set-Content -Path $usersFile
        Write-Host "✅ Created users.txt configuration file" -ForegroundColor Green
    } else {
        Write-Host "✅ users.txt configuration file already exists" -ForegroundColor Green
    }
}

# --- Main Setup Function ---
function Start-VMwareSetup {
    Write-Host "=== VMware vCenter Password Management Tool - Setup ===" -ForegroundColor Cyan
    Write-Host "PowerShell Gallery Edition - Automated PowerCLI Installation" -ForegroundColor Cyan
    Write-Host ""
    
    # Show DoD Warning
    Show-DoDWarning
    
    # Initialize PowerShell environment
    Initialize-PowerShellEnvironment
    
    # Install/Update NuGet provider
    Install-NuGetProvider
    
    # Update PowerShellGet if needed
    Update-PowerShellGet
    
    # Install/Update VMware PowerCLI
    $powerCLISuccess = Install-VMwarePowerCLI
    
    # Create configuration files
    Create-ConfigurationFiles
    
    Write-Host ""
    Write-Host "=== Setup Complete ===" -ForegroundColor Green
    
    if ($powerCLISuccess) {
        Write-Host "✅ VMware PowerCLI is installed and configured" -ForegroundColor Green
        Write-Host "✅ Configuration files are ready" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Edit hosts.txt with your ESXi host addresses" -ForegroundColor White
        Write-Host "2. Edit users.txt with target usernames (optional)" -ForegroundColor White
        Write-Host "3. Run the VMware management tool with GUI interface" -ForegroundColor White
        
        # Check if main tool exists
        $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
        $mainTool = Join-Path $scriptRoot "VMware-Password-Manager.ps1"
        if (Test-Path $mainTool) {
            Write-Host ""
            $runNow = Read-Host "Would you like to run the VMware Password Manager with GUI now? (Y/N)"
            if ($runNow -eq "Y" -or $runNow -eq "y") {
                Write-Host "Starting VMware Password Manager with GUI..." -ForegroundColor Green
                & $mainTool
            }
        } else {
            Write-Host ""
            Write-Host "Note: Download the main VMware-Password-Manager.ps1 script to complete the setup" -ForegroundColor Yellow
            Write-Host "The GUI interface will be available once you have the main script" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ PowerCLI installation failed" -ForegroundColor Red
        Write-Host "Please check your internet connection and try again" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    Read-Host
}

# Start the setup
Start-VMwareSetup