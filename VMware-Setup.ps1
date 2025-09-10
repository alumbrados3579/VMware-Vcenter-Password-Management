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
    
    # Set execution policy
    try {
        Write-Host "Setting execution policy..." -ForegroundColor Green
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "✅ Execution policy set to RemoteSigned for CurrentUser" -ForegroundColor Green
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

# --- VMware PowerCLI Installation ---
function Install-VMwarePowerCLI {
    Write-Host "=== Installing VMware PowerCLI ===" -ForegroundColor Cyan
    
    try {
        # Check if PowerCLI is already installed
        $powerCLI = Get-Module -Name "VMware.PowerCLI" -ListAvailable -ErrorAction SilentlyContinue
        
        if ($powerCLI) {
            Write-Host "✅ VMware PowerCLI already installed (Version: $($powerCLI.Version))" -ForegroundColor Green
            
            # Check for updates
            Write-Host "Checking for PowerCLI updates..." -ForegroundColor Green
            try {
                $latestVersion = Find-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
                if ($latestVersion -and $latestVersion.Version -gt $powerCLI.Version) {
                    Write-Host "Updating VMware PowerCLI to version $($latestVersion.Version)..." -ForegroundColor Green
                    Update-Module -Name "VMware.PowerCLI" -Force -Scope CurrentUser
                    Write-Host "✅ VMware PowerCLI updated successfully" -ForegroundColor Green
                } else {
                    Write-Host "✅ VMware PowerCLI is up to date" -ForegroundColor Green
                }
            } catch {
                Write-Host "⚠️ Could not check for updates: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Installing VMware PowerCLI from PowerShell Gallery..." -ForegroundColor Green
            Install-Module -Name "VMware.PowerCLI" -Scope CurrentUser -Force -AllowClobber
            Write-Host "✅ VMware PowerCLI installed successfully" -ForegroundColor Green
        }
        
        # Import the module
        Write-Host "Loading VMware PowerCLI..." -ForegroundColor Green
        Import-Module VMware.PowerCLI -Force
        
        # Configure PowerCLI settings
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope User
        
        Write-Host "✅ VMware PowerCLI configured and ready" -ForegroundColor Green
        
        # Display PowerCLI version info
        $powerCLIVersion = Get-Module -Name "VMware.PowerCLI" | Select-Object Version
        Write-Host "VMware PowerCLI Version: $($powerCLIVersion.Version)" -ForegroundColor Cyan
        
        return $true
    } catch {
        Write-Host "❌ Failed to install VMware PowerCLI: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please check your internet connection and PowerShell Gallery access" -ForegroundColor Yellow
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
        Write-Host "3. Run the VMware management tool" -ForegroundColor White
        
        # Check if main tool exists
        $mainTool = Join-Path $PSScriptRoot "VMware-Password-Manager.ps1"
        if (Test-Path $mainTool) {
            Write-Host ""
            $runNow = Read-Host "Would you like to run the VMware Password Manager now? (Y/N)"
            if ($runNow -eq "Y" -or $runNow -eq "y") {
                & $mainTool
            }
        } else {
            Write-Host ""
            Write-Host "Note: Download the main VMware-Password-Manager.ps1 script to complete the setup" -ForegroundColor Yellow
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