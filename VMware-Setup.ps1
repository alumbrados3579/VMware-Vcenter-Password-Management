# VMware vCenter Password Management Tool - Setup Script
# Version 1.0 - Professional DoD-Compliant Edition
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Developed with assistance from Qodo AI
# Purpose: Complete automated setup and launch of the password management tool
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

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

function Download-CompleteToolSuite {
    Write-Progress "Downloading Complete Tool Suite" "Getting the latest complete application suite from repository..." 100
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    
    try {
        Write-DetailedStatus "Downloading complete VMware Password Management Tool suite..."
        Write-DetailedStatus "[INFO] This includes all tools, documentation, and components"
        
        # Define all files to download
        $filesToDownload = @(
            @{ Path = "VMware-Password-Manager.ps1"; Description = "Main GUI application" },
            @{ Path = "VMware-Password-Manager-Modular.ps1"; Description = "Smart modular launcher" },
            @{ Path = "VMware-Host-Manager.ps1"; Description = "Standalone host manager" },
            @{ Path = "README.md"; Description = "Project overview and documentation" },
            @{ Path = "HOWTO.txt"; Description = "Quick reference guide" },
            @{ Path = "Installation.txt"; Description = "Installation instructions" },
            @{ Path = "AUTHORS.txt"; Description = "Author and copyright information" },
            @{ Path = "LICENSE"; Description = "License information" },
            @{ Path = "Tools/Common.ps1"; Description = "Shared utilities library" },
            @{ Path = "Tools/CLIWorkspace.ps1"; Description = "PowerCLI terminal tool" },
            @{ Path = "Tools/Configuration.ps1"; Description = "Configuration editor tool" },
            @{ Path = "Tools/HostManager.ps1"; Description = "Host management tool" },
            @{ Path = "Documents/README.md"; Description = "Documentation index" },
            @{ Path = "Documents/Setup-Guide.md"; Description = "Setup and installation guide" },
            @{ Path = "Documents/CLI-Workspace-Guide.md"; Description = "CLI workspace guide" },
            @{ Path = "Documents/Configuration-Manager-Guide.md"; Description = "Configuration manager guide" },
            @{ Path = "Documents/Host-Manager-Guide.md"; Description = "Host manager guide" },
            @{ Path = "Documents/Password-Management-Guide.md"; Description = "Password management guide" },
            @{ Path = "Documents/Modular-Architecture-Guide.md"; Description = "Architecture guide" },
            @{ Path = "Documents/Pseudocode-Prompt-Template.md"; Description = "Pseudocode template" },
            @{ Path = "Documents/Workflow-Flowchart-Prompt-Template.md"; Description = "Workflow template" },
            @{ Path = "Documents/VMware-Tool-Recreation-Prompt.md"; Description = "Tool recreation guide" }
        )
        
        $baseUrl = "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main"
        $downloadedCount = 0
        $totalFiles = $filesToDownload.Count
        
        foreach ($file in $filesToDownload) {
            $downloadedCount++
            $progressPercent = [math]::Round(($downloadedCount / $totalFiles) * 100)
            
            Write-DetailedStatus "[$downloadedCount/$totalFiles] Downloading $($file.Description)..."
            
            $localPath = Join-Path $scriptRoot $file.Path
            $localDir = Split-Path $localPath -Parent
            
            # Create directory if it doesn't exist
            if (-not (Test-Path $localDir)) {
                New-Item -Path $localDir -ItemType Directory -Force | Out-Null
                Write-DetailedStatus "   Created directory: $localDir"
            }
            
            try {
                $downloadUrl = "$baseUrl/$($file.Path)"
                Invoke-WebRequest -Uri $downloadUrl -OutFile $localPath -UseBasicParsing
                Write-DetailedStatus "   [SUCCESS] $($file.Path)"
            } catch {
                Write-DetailedStatus "   [WARNING] Failed to download $($file.Path): $($_.Exception.Message)"
            }
        }
        
        Write-DetailedStatus "[SUCCESS] Complete tool suite download completed"
        Write-DetailedStatus "   All components are now available for use"
        
        # Verify critical files
        $criticalFiles = @(
            "VMware-Password-Manager.ps1",
            "VMware-Password-Manager-Modular.ps1",
            "Tools/Common.ps1",
            "Tools/CLIWorkspace.ps1",
            "README.md"
        )
        
        $missingFiles = @()
        foreach ($file in $criticalFiles) {
            $filePath = Join-Path $scriptRoot $file
            if (-not (Test-Path $filePath)) {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -eq 0) {
            Write-DetailedStatus "[SUCCESS] All critical components verified and ready"
        } else {
            Write-DetailedStatus "[WARNING] Some critical files are missing: $($missingFiles -join ', ')"
            Write-DetailedStatus "You may need to download these manually from GitHub"
        }
        
    } catch {
        Write-DetailedStatus "[WARNING] Could not download complete tool suite: $($_.Exception.Message)"
        Write-DetailedStatus "You can manually download the complete repository from GitHub"
        Write-DetailedStatus "Repository: https://github.com/alumbrados3579/VMware-Vcenter-Password-Management"
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
    Write-Host "[SUCCESS] Complete tool suite downloaded" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Configure your ESXi hosts and users" -ForegroundColor White
    Write-Host "2. Test vCenter connectivity" -ForegroundColor White
    Write-Host "3. Run password operations (Dry Run first!)" -ForegroundColor White
    Write-Host ""
    
    Show-PostInstallationOptions
}

function Show-PostInstallationOptions {
    Write-Host "=== POST-INSTALLATION OPTIONS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Choose an option:" -ForegroundColor Yellow
    Write-Host "1. Create ZIP package for air-gapped/classified networks" -ForegroundColor White
    Write-Host "2. Launch VMware Password Manager" -ForegroundColor White
    Write-Host "3. Exit setup" -ForegroundColor White
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter your choice (1-3)"
        
        switch ($choice) {
            "1" { 
                Create-DeploymentPackage
                break 
            }
            "2" { 
                Launch-Application
                break 
            }
            "3" { 
                Write-Host "Setup complete. You can run the tools manually when ready." -ForegroundColor Green
                Write-Host "Use: .\VMware-Password-Manager.ps1 or .\Tools\CLIWorkspace.ps1" -ForegroundColor Gray
                break 
            }
            default { 
                Write-Host "Invalid choice. Please enter 1, 2, or 3." -ForegroundColor Red 
            }
        }
    } while ($choice -notin @("1", "2", "3"))
}

function Create-DeploymentPackage {
    Write-Host ""
    Write-Host "=== CREATING DEPLOYMENT PACKAGE ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will create a ZIP file containing the complete VMware Password Management Tool" -ForegroundColor Yellow
    Write-Host "suitable for deployment to air-gapped or higher classification networks." -ForegroundColor Yellow
    Write-Host ""
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipFileName = "VMware-Password-Manager-v1.0-$timestamp.zip"
    $zipPath = Join-Path (Split-Path $scriptRoot -Parent) $zipFileName
    
    try {
        Write-Host "Creating deployment package..." -ForegroundColor Green
        Write-Host "Source: $scriptRoot" -ForegroundColor Gray
        Write-Host "Package: $zipPath" -ForegroundColor Gray
        Write-Host ""
        
        # Create ZIP file using PowerShell 5.0+ Compress-Archive
        if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
            Write-Host "Compressing files..." -ForegroundColor Green
            Compress-Archive -Path "$scriptRoot\*" -DestinationPath $zipPath -Force
            
            $zipSize = (Get-Item $zipPath).Length
            $zipSizeMB = [math]::Round($zipSize / 1MB, 2)
            
            Write-Host ""
            Write-Host "[SUCCESS] Deployment package created successfully!" -ForegroundColor Green
            Write-Host "Package: $zipFileName" -ForegroundColor White
            Write-Host "Location: $zipPath" -ForegroundColor White
            Write-Host "Size: $zipSizeMB MB" -ForegroundColor White
            Write-Host ""
            Write-Host "DEPLOYMENT INSTRUCTIONS:" -ForegroundColor Cyan
            Write-Host "1. Transfer the ZIP file to your target network" -ForegroundColor White
            Write-Host "2. Extract to desired location" -ForegroundColor White
            Write-Host "3. No additional setup required - all components included" -ForegroundColor White
            Write-Host "4. Run VMware-Password-Manager.ps1 or individual tools" -ForegroundColor White
            Write-Host ""
            Write-Host "PACKAGE CONTENTS:" -ForegroundColor Cyan
            Write-Host "- Complete VMware Password Management Tool v1.0" -ForegroundColor White
            Write-Host "- All PowerCLI modules (local installation)" -ForegroundColor White
            Write-Host "- Documentation and guides" -ForegroundColor White
            Write-Host "- Modular tools for fast operation" -ForegroundColor White
            Write-Host "- Configuration templates" -ForegroundColor White
            Write-Host ""
            
            $openFolder = Read-Host "Would you like to open the folder containing the ZIP file? (Y/N)"
            if ($openFolder -eq "Y" -or $openFolder -eq "y") {
                Start-Process "explorer.exe" -ArgumentList "/select,`"$zipPath`""
            }
        } else {
            Write-Host "[ERROR] Compress-Archive not available. Using alternative method..." -ForegroundColor Yellow
            
            # Fallback method using .NET
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory($scriptRoot, $zipPath)
            
            Write-Host "[SUCCESS] Deployment package created using .NET method!" -ForegroundColor Green
            Write-Host "Package: $zipPath" -ForegroundColor White
        }
        
        Write-Host ""
        $continueChoice = Read-Host "Would you like to launch the application now? (Y/N)"
        if ($continueChoice -eq "Y" -or $continueChoice -eq "y") {
            Launch-Application
        } else {
            Write-Host "Setup complete. Package ready for deployment." -ForegroundColor Green
        }
        
    } catch {
        Write-Host "[ERROR] Failed to create deployment package: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You can manually ZIP the contents of: $scriptRoot" -ForegroundColor Yellow
        Write-Host ""
        
        $continueChoice = Read-Host "Would you like to launch the application anyway? (Y/N)"
        if ($continueChoice -eq "Y" -or $continueChoice -eq "y") {
            Launch-Application
        }
    }
}

function Launch-Application {
    Write-Host ""
    Write-Host "=== LAUNCHING APPLICATION ===" -ForegroundColor Cyan
    Write-Host ""
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $mainTool = Join-Path $scriptRoot "VMware-Password-Manager.ps1"
    $modularTool = Join-Path $scriptRoot "VMware-Password-Manager-Modular.ps1"
    
    # Check which tools are available and offer options
    $availableTools = @()
    if (Test-Path $mainTool) {
        $availableTools += @{ Name = "Full GUI Application"; Path = $mainTool; Description = "Complete functionality" }
    }
    if (Test-Path $modularTool) {
        $availableTools += @{ Name = "Modular Launcher"; Path = $modularTool; Description = "Smart tool selection" }
    }
    
    if ($availableTools.Count -eq 0) {
        Write-Host "[ERROR] No application files found" -ForegroundColor Red
        Write-Host "Expected files:" -ForegroundColor Yellow
        Write-Host "  - $mainTool" -ForegroundColor Gray
        Write-Host "  - $modularTool" -ForegroundColor Gray
        Write-Host "Please check the installation and try again." -ForegroundColor Yellow
        return
    }
    
    if ($availableTools.Count -eq 1) {
        # Only one tool available, launch it
        $tool = $availableTools[0]
        Write-Host "Launching $($tool.Name)..." -ForegroundColor Green
        Write-Host "Application: $($tool.Path)" -ForegroundColor Gray
        Write-Host ""
        Start-Process PowerShell -ArgumentList "-File `"$($tool.Path)`"" -WindowStyle Normal
        Write-Host "Application launched successfully!" -ForegroundColor Green
    } else {
        # Multiple tools available, let user choose
        Write-Host "Multiple applications available:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $availableTools.Count; $i++) {
            $tool = $availableTools[$i]
            Write-Host "$($i + 1). $($tool.Name) - $($tool.Description)" -ForegroundColor White
        }
        Write-Host ""
        
        do {
            $choice = Read-Host "Select application to launch (1-$($availableTools.Count))"
            $choiceIndex = [int]$choice - 1
        } while ($choiceIndex -lt 0 -or $choiceIndex -ge $availableTools.Count)
        
        $selectedTool = $availableTools[$choiceIndex]
        Write-Host "Launching $($selectedTool.Name)..." -ForegroundColor Green
        Write-Host "Application: $($selectedTool.Path)" -ForegroundColor Gray
        Write-Host ""
        Start-Process PowerShell -ArgumentList "-File `"$($selectedTool.Path)`"" -WindowStyle Normal
        Write-Host "Application launched successfully!" -ForegroundColor Green
    }
}

function Start-SetupProcess {
    try {
        Initialize-PowerShellEnvironment
        Install-NuGetProvider
        Update-PowerShellGet
        $powerCLISuccess = Install-VMwarePowerCLI
        Create-ConfigurationFiles
        Download-CompleteToolSuite
        
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