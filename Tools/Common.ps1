# VMware vCenter Password Management Tool - Common Library
# Version 1.0 - Professional DoD-Compliant Edition
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Developed with assistance from Qodo AI
# Purpose: Common functions used across all modular tools
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

# Global error handling
$ErrorActionPreference = "Continue"

# --- Global Variables ---
if (-not $script:PSScriptRoot) {
    $script:PSScriptRoot = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
}
$script:LogsPath = Join-Path $script:PSScriptRoot "Logs"
$script:LogFilePath = Join-Path $script:LogsPath "vcenter_password_manager_$(Get-Date -Format 'yyyyMMdd').log"
$script:HostsFilePath = Join-Path $script:PSScriptRoot "hosts.txt"
$script:UsersFilePath = Join-Path $script:PSScriptRoot "users.txt"
$script:LocalModulesPath = Join-Path $script:PSScriptRoot "Modules"

# Ensure Logs directory exists
if (-not (Test-Path $script:LogsPath)) {
    New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
}

# Load Windows Forms if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'System.Windows.Forms.Form').Type) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}

# --- Utility Functions ---
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        $logEntry | Add-Content -Path $script:LogFilePath -ErrorAction SilentlyContinue
        
        # Also write to console for standalone tools
        $color = switch ($Level) {
            "SUCCESS" { "Green" }
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            default { "White" }
        }
        Write-Host "[$timestamp] $Message" -ForegroundColor $color
    } catch {
        # Fallback to console if logging fails
        Write-Host "LOG: $Message" -ForegroundColor Cyan
    }
}

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

Click OK to acknowledge and continue...
"@
    
    [System.Windows.Forms.MessageBox]::Show($dodWarning, "DoD System Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

function Test-PowerCLIAvailability {
    Write-Log "Checking VMware PowerCLI availability..." "INFO"
    
    try {
        # Priority 1: Check if PowerCLI is already loaded in current session
        $loadedPowerCLI = Get-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
        
        if ($loadedPowerCLI) {
            Write-Log "VMware PowerCLI already loaded in current session (Version: $($loadedPowerCLI.Version))" "SUCCESS"
            Write-Log "Module location: $($loadedPowerCLI.ModuleBase)" "INFO"
            
            if ($loadedPowerCLI.ModuleBase -like "*$script:LocalModulesPath*") {
                Write-Log "Using LOCAL PowerCLI modules (OneDrive-safe)" "SUCCESS"
            } else {
                Write-Log "Using SYSTEM PowerCLI modules" "INFO"
            }
        } else {
            # Priority 2: Check local Modules directory first
            if (Test-Path $script:LocalModulesPath) {
                $localPowerCLI = Get-ChildItem -Path $script:LocalModulesPath -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
                if ($localPowerCLI) {
                    Write-Log "Found local PowerCLI modules in: $script:LocalModulesPath" "SUCCESS"
                    
                    # Add local modules to PSModulePath if not already there
                    $currentPSModulePath = $env:PSModulePath
                    if ($currentPSModulePath -notlike "*$script:LocalModulesPath*") {
                        $env:PSModulePath = "$script:LocalModulesPath;$currentPSModulePath"
                        Write-Log "Added local Modules directory to PowerShell module path" "INFO"
                    }
                }
            }
            
            # Priority 3: Check if PowerCLI is available (local or system)
            $powerCLI = Get-Module -Name "VMware.PowerCLI" -ListAvailable -ErrorAction SilentlyContinue
            if (-not $powerCLI) {
                Write-Log "VMware PowerCLI not found in local or system modules" "ERROR"
                $message = @"
VMware PowerCLI is required but not installed.

Please run VMware-Setup.ps1 first to install PowerCLI to local Modules directory.
This avoids OneDrive sync issues and keeps modules in your working directory.

Expected local path: $script:LocalModulesPath
"@
                [System.Windows.Forms.MessageBox]::Show($message, "PowerCLI Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return $false
            }
            
            # Try to import the module
            try {
                Import-Module VMware.PowerCLI -ErrorAction Stop
                $loadedModule = Get-Module -Name "VMware.PowerCLI"
                Write-Log "VMware PowerCLI loaded successfully (Version: $($loadedModule.Version))" "SUCCESS"
                
                if ($loadedModule.ModuleBase -like "*$script:LocalModulesPath*") {
                    Write-Log "Using LOCAL PowerCLI modules (OneDrive-safe)" "SUCCESS"
                } else {
                    Write-Log "Using SYSTEM PowerCLI modules" "INFO"
                }
            } catch {
                # Check if VMware modules are already loaded (conflict)
                $vmwareModules = Get-Module | Where-Object { $_.Name -like "VMware.*" }
                if ($vmwareModules) {
                    Write-Log "VMware modules already loaded in memory, using existing modules" "INFO"
                    foreach ($module in $vmwareModules) {
                        Write-Log "  - $($module.Name) v$($module.Version)" "INFO"
                    }
                } else {
                    throw "Failed to load PowerCLI: $($_.Exception.Message)"
                }
            }
        }
        
        # Configure PowerCLI settings
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session -ErrorAction SilentlyContinue
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope Session -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        Write-Log "Failed to load VMware PowerCLI: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to load PowerCLI: $($_.Exception.Message)", "PowerCLI Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
}

function Get-HostsFromFile {
    try {
        if (-not (Test-Path $script:HostsFilePath)) {
            Write-Log "Hosts file not found: $script:HostsFilePath" "WARNING"
            return @()
        }
        
        $hosts = Get-Content $script:HostsFilePath -ErrorAction Stop | Where-Object { 
            $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#')
        }
        
        Write-Log "Loaded $($hosts.Count) hosts from file" "INFO"
        return $hosts
    } catch {
        Write-Log "Error reading hosts file: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Get-UsersFromFile {
    try {
        if (-not (Test-Path $script:UsersFilePath)) {
            Write-Log "Users file not found: $script:UsersFilePath" "WARNING"
            return @()
        }
        
        $users = Get-Content $script:UsersFilePath -ErrorAction Stop | Where-Object { 
            $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#')
        }
        
        Write-Log "Loaded $($users.Count) users from file" "INFO"
        return $users
    } catch {
        Write-Log "Error reading users file: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Export-LogsToFile {
    param([string]$DefaultFileName = "VMware_Tool_Logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').log")
    
    try {
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "Log Files (*.log)|*.log|Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
        $saveDialog.Title = "Export Logs"
        $saveDialog.FileName = $DefaultFileName
        
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            if (Test-Path $script:LogFilePath) {
                Copy-Item $script:LogFilePath $saveDialog.FileName
                [System.Windows.Forms.MessageBox]::Show("Logs exported successfully to:`n$($saveDialog.FileName)", "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                Write-Log "Logs exported to file: $($saveDialog.FileName)" "SUCCESS"
            } else {
                [System.Windows.Forms.MessageBox]::Show("No log file found to export.", "No Logs", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        }
    } catch {
        Write-Log "Failed to export logs: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to export logs: $($_.Exception.Message)", "Export Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Create-StandardForm {
    param(
        [string]$Title,
        [int]$Width = 800,
        [int]$Height = 600,
        [bool]$Resizable = $true
    )
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size($Width, $Height)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = if ($Resizable) { "Sizable" } else { "FixedDialog" }
    $form.MaximizeBox = $Resizable
    $form.Icon = [System.Drawing.SystemIcons]::Shield
    
    return $form
}

# Export functions for use by other modules
Export-ModuleMember -Function *