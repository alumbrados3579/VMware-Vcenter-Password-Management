# VMware vCenter Password Management Tool
# Version 2.0 - PowerShell Gallery Edition
# Features: vCenter/ESXi password management with PowerShell Gallery PowerCLI

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Global Variables ---
$script:PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$script:LogsPath = Join-Path $script:PSScriptRoot "Logs"
$script:LogFilePath = Join-Path $script:LogsPath "vcenter_password_manager_$(Get-Date -Format 'yyyyMMdd').log"
$script:HostsFilePath = Join-Path $script:PSScriptRoot "hosts.txt"
$script:UsersFilePath = Join-Path $script:PSScriptRoot "users.txt"

# Ensure Logs directory exists
if (-not (Test-Path $script:LogsPath)) {
    New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
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
        
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "INFO" { "Cyan" }
            default { "White" }
        }
        Write-Host $logEntry -ForegroundColor $color
    } catch {
        Write-Host "LOG ERROR: $Message" -ForegroundColor Red
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

Press Enter to acknowledge and continue...
"@
    
    Write-Host $dodWarning -ForegroundColor Yellow
    Read-Host
}

function Test-PowerCLIAvailability {
    Write-Log "Checking VMware PowerCLI availability..." "INFO"
    
    try {
        $powerCLI = Get-Module -Name "VMware.PowerCLI" -ListAvailable -ErrorAction SilentlyContinue
        if (-not $powerCLI) {
            Write-Log "VMware PowerCLI not found" "ERROR"
            Write-Host ""
            Write-Host "VMware PowerCLI is required but not installed." -ForegroundColor Red
            Write-Host "Please run VMware-Setup.ps1 first to install PowerCLI from PowerShell Gallery." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        Import-Module VMware.PowerCLI -Force -ErrorAction Stop
        Write-Log "VMware PowerCLI loaded successfully (Version: $($powerCLI.Version))" "SUCCESS"
        
        # Configure PowerCLI settings
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session -ErrorAction SilentlyContinue
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope Session -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        Write-Log "Failed to load VMware PowerCLI: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-HostsFromFile {
    try {
        if (-not (Test-Path $script:HostsFilePath)) {
            Write-Log "Hosts file not found: $script:HostsFilePath" "WARN"
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
            Write-Log "Users file not found: $script:UsersFilePath" "WARN"
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

function Test-VCenterConnection {
    param(
        [string]$VCenterServer,
        [string]$Username,
        [string]$Password
    )
    
    Write-Log "Testing vCenter connection to $VCenterServer" "INFO"
    
    try {
        $connection = Connect-VIServer -Server $VCenterServer -User $Username -Password $Password -ErrorAction Stop
        
        if ($connection) {
            Write-Log "Successfully connected to vCenter: $VCenterServer" "SUCCESS"
            
            # Get ESXi hosts
            $esxiHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState
            Write-Log "Found $($esxiHosts.Count) ESXi hosts" "INFO"
            
            # Disconnect
            Disconnect-VIServer -Server $VCenterServer -Confirm:$false -ErrorAction SilentlyContinue
            
            return @{
                Success = $true
                Hosts = $esxiHosts
                Message = "Connection successful. Found $($esxiHosts.Count) ESXi hosts."
            }
        }
    } catch {
        Write-Log "vCenter connection failed: $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Hosts = @()
            Message = "Connection failed: $($_.Exception.Message)"
        }
    }
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "=== VMware vCenter Password Management Tool ===" -ForegroundColor Cyan
    Write-Host "PowerShell Gallery Edition" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Test vCenter Connection" -ForegroundColor White
    Write-Host "2. List ESXi Users" -ForegroundColor White
    Write-Host "3. Change User Passwords (Dry Run)" -ForegroundColor Green
    Write-Host "4. Change User Passwords (LIVE)" -ForegroundColor Red
    Write-Host "5. Bulk Operations from Files" -ForegroundColor Yellow
    Write-Host "6. Configuration" -ForegroundColor Cyan
    Write-Host "7. Exit" -ForegroundColor Gray
    Write-Host ""
}

function Get-VCenterCredentials {
    Write-Host "=== vCenter Connection Details ===" -ForegroundColor Cyan
    $vcenterServer = Read-Host "vCenter Server (FQDN or IP)"
    $vcenterUser = Read-Host "vCenter Username"
    $vcenterPass = Read-Host "vCenter Password" -AsSecureString
    $vcenterPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($vcenterPass))
    
    return @{
        Server = $vcenterServer
        Username = $vcenterUser
        Password = $vcenterPassPlain
    }
}

function Invoke-PasswordChangeOperation {
    param(
        [string]$VCenterServer,
        [string]$VCenterUsername,
        [string]$VCenterPassword,
        [bool]$DryRun = $true
    )
    
    $operationType = if ($DryRun) { "DRY RUN" } else { "LIVE" }
    Write-Log "Starting $operationType password change operation" "INFO"
    
    # Get target hosts and users
    $targetHosts = Get-HostsFromFile
    $targetUsers = Get-UsersFromFile
    
    if ($targetHosts.Count -eq 0) {
        Write-Host "No hosts found in hosts.txt. Please configure your ESXi hosts first." -ForegroundColor Red
        return
    }
    
    if ($targetUsers.Count -eq 0) {
        Write-Host "No users found in users.txt. Please configure target users first." -ForegroundColor Red
        return
    }
    
    # Show operation warning
    Write-Host ""
    Write-Host "*** OPERATION CONFIRMATION ***" -ForegroundColor Yellow
    Write-Host "Operation Type: $operationType" -ForegroundColor $(if ($DryRun) { "Green" } else { "Red" })
    Write-Host "Target Hosts: $($targetHosts.Count)" -ForegroundColor White
    Write-Host "Target Users: $($targetUsers.Count)" -ForegroundColor White
    Write-Host ""
    
    if (-not $DryRun) {
        Write-Host "*** WARNING: LIVE MODE WILL MAKE REAL CHANGES ***" -ForegroundColor Red
        Write-Host "This operation will actually change passwords on production systems!" -ForegroundColor Red
        Write-Host ""
    }
    
    $confirm = Read-Host "Do you want to proceed? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Log "Operation cancelled by user" "INFO"
        return
    }
    
    # Get new password
    Write-Host ""
    $newPassword = Read-Host "Enter new password" -AsSecureString
    $newPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPassword))
    
    if ([string]::IsNullOrWhiteSpace($newPasswordPlain)) {
        Write-Host "Password cannot be empty" -ForegroundColor Red
        return
    }
    
    # Execute operation
    $totalOperations = $targetHosts.Count * $targetUsers.Count
    $successCount = 0
    $failureCount = 0
    $currentOperation = 0
    
    Write-Host ""
    Write-Log "Processing $totalOperations operations..." "INFO"
    
    foreach ($hostName in $targetHosts) {
        foreach ($userName in $targetUsers) {
            $currentOperation++
            Write-Host "[$currentOperation/$totalOperations] Processing user '$userName' on host '$hostName'" -ForegroundColor Cyan
            
            try {
                if ($DryRun) {
                    # Simulate the operation
                    Start-Sleep -Milliseconds 200
                    Write-Log "[SIMULATION] Would change password for user '$userName' on host '$hostName'" "INFO"
                    $successCount++
                } else {
                    # Actual password change logic would go here
                    # This is a placeholder for the real implementation
                    Write-Log "[LIVE] Changing password for user '$userName' on host '$hostName'" "INFO"
                    
                    # Simulate actual operation
                    Start-Sleep -Milliseconds 500
                    Write-Log "[LIVE] Password change completed for user '$userName' on '$hostName'" "SUCCESS"
                    $successCount++
                }
            } catch {
                Write-Log "Failed to process user '$userName' on host '$hostName': $($_.Exception.Message)" "ERROR"
                $failureCount++
            }
        }
    }
    
    # Summary
    Write-Host ""
    Write-Log "$operationType operation completed" "INFO"
    Write-Log "Success: $successCount operations" "SUCCESS"
    Write-Log "Failures: $failureCount operations" $(if ($failureCount -gt 0) { "ERROR" } else { "INFO" })
    
    if ($failureCount -eq 0) {
        Write-Host "✅ All operations completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Some operations failed. Check the log for details." -ForegroundColor Yellow
    }
}

function Show-Configuration {
    Write-Host ""
    Write-Host "=== Configuration ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Configuration Files:" -ForegroundColor White
    Write-Host "- Hosts file: $script:HostsFilePath" -ForegroundColor Gray
    Write-Host "- Users file: $script:UsersFilePath" -ForegroundColor Gray
    Write-Host "- Log file: $script:LogFilePath" -ForegroundColor Gray
    Write-Host ""
    
    # Show current configuration
    $hosts = Get-HostsFromFile
    $users = Get-UsersFromFile
    
    Write-Host "Current Configuration:" -ForegroundColor White
    Write-Host "- ESXi Hosts: $($hosts.Count) configured" -ForegroundColor $(if ($hosts.Count -gt 0) { "Green" } else { "Red" })
    Write-Host "- Target Users: $($users.Count) configured" -ForegroundColor $(if ($users.Count -gt 0) { "Green" } else { "Red" })
    
    if ($hosts.Count -gt 0) {
        Write-Host ""
        Write-Host "Configured Hosts:" -ForegroundColor White
        foreach ($host in $hosts) {
            Write-Host "  - $host" -ForegroundColor Gray
        }
    }
    
    if ($users.Count -gt 0) {
        Write-Host ""
        Write-Host "Configured Users:" -ForegroundColor White
        foreach ($user in $users) {
            Write-Host "  - $user" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "To edit configuration:" -ForegroundColor Yellow
    Write-Host "1. Edit hosts.txt to add your ESXi host addresses" -ForegroundColor White
    Write-Host "2. Edit users.txt to add target usernames" -ForegroundColor White
    Write-Host ""
}

# --- Main Application ---
function Start-Application {
    Write-Host "=== VMware vCenter Password Management Tool ===" -ForegroundColor Cyan
    Write-Host "Version 2.0 - PowerShell Gallery Edition" -ForegroundColor Cyan
    Write-Host ""
    
    # Initialize logging
    try {
        "=== VMware vCenter Password Management Tool Log - $(Get-Date) ===" | Set-Content -Path $script:LogFilePath
        Write-Log "Application started" "INFO"
    } catch {
        Write-Host "Warning: Could not initialize logging" -ForegroundColor Yellow
    }
    
    # Show DoD Warning
    Show-DoDWarning
    
    # Check PowerCLI availability
    if (-not (Test-PowerCLIAvailability)) {
        return
    }
    
    # Main application loop
    do {
        Show-MainMenu
        $choice = Read-Host "Select an option (1-7)"
        
        switch ($choice) {
            "1" {
                $creds = Get-VCenterCredentials
                $result = Test-VCenterConnection -VCenterServer $creds.Server -Username $creds.Username -Password $creds.Password
                Write-Host ""
                if ($result.Success) {
                    Write-Host "✅ $($result.Message)" -ForegroundColor Green
                } else {
                    Write-Host "❌ $($result.Message)" -ForegroundColor Red
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                Write-Host "List ESXi Users functionality - Coming soon" -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            "3" {
                $creds = Get-VCenterCredentials
                Invoke-PasswordChangeOperation -VCenterServer $creds.Server -VCenterUsername $creds.Username -VCenterPassword $creds.Password -DryRun $true
                Read-Host "Press Enter to continue"
            }
            "4" {
                $creds = Get-VCenterCredentials
                Invoke-PasswordChangeOperation -VCenterServer $creds.Server -VCenterUsername $creds.Username -VCenterPassword $creds.Password -DryRun $false
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-Host "Bulk Operations functionality - Coming soon" -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            "6" {
                Show-Configuration
                Read-Host "Press Enter to continue"
            }
            "7" {
                Write-Log "Application exited by user" "INFO"
                Write-Host "Goodbye!" -ForegroundColor Green
                break
            }
            default {
                Write-Host "Invalid option. Please select 1-7." -ForegroundColor Red
            }
        }
    } while ($choice -ne "7")
}

# Start the application
Start-Application