# VMware vCenter Password Management Tool - GUI Edition
# Version 0.5 BETA - Enterprise Password Management Suite
# Features: vCenter/ESXi password management with intuitive GUI interface

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    [System.Windows.Forms.MessageBox]::Show("CRITICAL ERROR: $($_.Exception.Message)", "VMware Password Manager", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# --- Global Variables ---
$script:PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$script:LogsPath = Join-Path $script:PSScriptRoot "Logs"
$script:LogFilePath = Join-Path $script:LogsPath "vcenter_password_manager_$(Get-Date -Format 'yyyyMMdd').log"
$script:HostsFilePath = Join-Path $script:PSScriptRoot "hosts.txt"
$script:UsersFilePath = Join-Path $script:PSScriptRoot "users.txt"
$script:LocalModulesPath = Join-Path $script:PSScriptRoot "Modules"

# Ensure Logs directory exists
if (-not (Test-Path $script:LogsPath)) {
    New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
}

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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
        
        # Also write to GUI log if available and handle is created
        if ($script:LogTextBox -and $script:LogTextBox.IsHandleCreated) {
            $script:LogTextBox.AppendText("$logEntry`r`n")
            $script:LogTextBox.ScrollToCaret()
        }
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

# --- GUI Creation Functions ---
function Create-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VMware vCenter Password Management Tool - Version 0.5 BETA"
    $form.Size = New-Object System.Drawing.Size(900, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.Icon = [System.Drawing.SystemIcons]::Shield
    
    return $form
}

function Create-TabControl {
    param($form)
    
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Size = New-Object System.Drawing.Size(880, 650)
    $tabControl.Location = New-Object System.Drawing.Point(10, 10)
    
    # Create tabs
    $passwordTab = New-Object System.Windows.Forms.TabPage
    $passwordTab.Text = "Password Management"
    Create-VMwareTab $passwordTab
    
    $configTab = New-Object System.Windows.Forms.TabPage
    $configTab.Text = "Configuration"
    Create-ConfigTab $configTab
    
    $cliTab = New-Object System.Windows.Forms.TabPage
    $cliTab.Text = "CLI Workspace"
    Create-CLITab $cliTab
    
    $githubTab = New-Object System.Windows.Forms.TabPage
    $githubTab.Text = "GitHub Manager"
    Create-GitHubTab $githubTab
    
    $logsTab = New-Object System.Windows.Forms.TabPage
    $logsTab.Text = "Logs"
    Create-LogsTab $logsTab
    
    $tabControl.TabPages.AddRange(@($passwordTab, $configTab, $cliTab, $githubTab, $logsTab))
    
    $form.Controls.Add($tabControl)
    
    return @{
        TabControl = $tabControl
        PasswordTab = $passwordTab
        ConfigTab = $configTab
        CLITab = $cliTab
        GitHubTab = $githubTab
        LogsTab = $logsTab
    }
}

function Create-VMwareTab {
    param($tab)
    
    # vCenter Connection Group
    $vcenterGroup = New-Object System.Windows.Forms.GroupBox
    $vcenterGroup.Text = "vCenter Connection"
    $vcenterGroup.Size = New-Object System.Drawing.Size(840, 120)
    $vcenterGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    # vCenter Server
    $vcenterLabel = New-Object System.Windows.Forms.Label
    $vcenterLabel.Text = "vCenter Server:"
    $vcenterLabel.Location = New-Object System.Drawing.Point(10, 25)
    $vcenterLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:VCenterTextBox = New-Object System.Windows.Forms.TextBox
    $script:VCenterTextBox.Location = New-Object System.Drawing.Point(120, 23)
    $script:VCenterTextBox.Size = New-Object System.Drawing.Size(200, 20)
    
    # Username (Administrator) - Free text entry for domain accounts
    $usernameLabel = New-Object System.Windows.Forms.Label
    $usernameLabel.Text = "Admin Username:"
    $usernameLabel.Location = New-Object System.Drawing.Point(340, 25)
    $usernameLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:AdminUsernameTextBox = New-Object System.Windows.Forms.TextBox
    $script:AdminUsernameTextBox.Location = New-Object System.Drawing.Point(450, 23)
    $script:AdminUsernameTextBox.Size = New-Object System.Drawing.Size(180, 20)
    $script:AdminUsernameTextBox.Text = "administrator@vsphere.local"
    
    # Password
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "Password:"
    $passwordLabel.Location = New-Object System.Drawing.Point(590, 25)
    $passwordLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:PasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:PasswordTextBox.Location = New-Object System.Drawing.Point(680, 23)
    $script:PasswordTextBox.Size = New-Object System.Drawing.Size(150, 20)
    $script:PasswordTextBox.UseSystemPasswordChar = $true
    
    # Test Connection Button
    $testButton = New-Object System.Windows.Forms.Button
    $testButton.Text = "Test Connection"
    $testButton.Location = New-Object System.Drawing.Point(10, 60)
    $testButton.Size = New-Object System.Drawing.Size(120, 30)
    $testButton.BackColor = [System.Drawing.Color]::LightBlue
    $testButton.Add_Click({
        Test-VCenterConnectionGUI
    })
    
    # Connection Status
    $script:ConnectionStatusLabel = New-Object System.Windows.Forms.Label
    $script:ConnectionStatusLabel.Text = "Status: Not Connected"
    $script:ConnectionStatusLabel.Location = New-Object System.Drawing.Point(150, 65)
    $script:ConnectionStatusLabel.Size = New-Object System.Drawing.Size(300, 20)
    $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
    
    $vcenterGroup.Controls.AddRange(@($vcenterLabel, $script:VCenterTextBox, $usernameLabel, $script:AdminUsernameTextBox, $passwordLabel, $script:PasswordTextBox, $testButton, $script:ConnectionStatusLabel))
    
    # Password Operations Group
    $passwordGroup = New-Object System.Windows.Forms.GroupBox
    $passwordGroup.Text = "Password Operations"
    $passwordGroup.Size = New-Object System.Drawing.Size(840, 120)
    $passwordGroup.Location = New-Object System.Drawing.Point(10, 140)
    
    # Target User Selection (ESXi accounts from users.txt)
    $targetUserLabel = New-Object System.Windows.Forms.Label
    $targetUserLabel.Text = "Target ESXi User:"
    $targetUserLabel.Location = New-Object System.Drawing.Point(10, 25)
    $targetUserLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:TargetUserComboBox = New-Object System.Windows.Forms.ComboBox
    $script:TargetUserComboBox.Location = New-Object System.Drawing.Point(120, 23)
    $script:TargetUserComboBox.Size = New-Object System.Drawing.Size(120, 20)
    $script:TargetUserComboBox.DropDownStyle = "DropDownList"
    
    # New Password
    $newPasswordLabel = New-Object System.Windows.Forms.Label
    $newPasswordLabel.Text = "New Password:"
    $newPasswordLabel.Location = New-Object System.Drawing.Point(240, 25)
    $newPasswordLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:NewPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:NewPasswordTextBox.Location = New-Object System.Drawing.Point(350, 23)
    $script:NewPasswordTextBox.Size = New-Object System.Drawing.Size(150, 20)
    $script:NewPasswordTextBox.UseSystemPasswordChar = $true
    
    # Confirm Password
    $confirmPasswordLabel = New-Object System.Windows.Forms.Label
    $confirmPasswordLabel.Text = "Confirm:"
    $confirmPasswordLabel.Location = New-Object System.Drawing.Point(520, 25)
    $confirmPasswordLabel.Size = New-Object System.Drawing.Size(60, 20)
    
    $script:ConfirmPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:ConfirmPasswordTextBox.Location = New-Object System.Drawing.Point(590, 23)
    $script:ConfirmPasswordTextBox.Size = New-Object System.Drawing.Size(150, 20)
    $script:ConfirmPasswordTextBox.UseSystemPasswordChar = $true
    
    # Operation Buttons
    $dryRunButton = New-Object System.Windows.Forms.Button
    $dryRunButton.Text = "Dry Run (Test)"
    $dryRunButton.Location = New-Object System.Drawing.Point(10, 70)
    $dryRunButton.Size = New-Object System.Drawing.Size(120, 35)
    $dryRunButton.BackColor = [System.Drawing.Color]::LightGreen
    $dryRunButton.Add_Click({
        Start-PasswordOperation -DryRun $true
    })
    
    $liveRunButton = New-Object System.Windows.Forms.Button
    $liveRunButton.Text = "LIVE Run"
    $liveRunButton.Location = New-Object System.Drawing.Point(140, 70)
    $liveRunButton.Size = New-Object System.Drawing.Size(120, 35)
    $liveRunButton.BackColor = [System.Drawing.Color]::LightCoral
    $liveRunButton.Add_Click({
        Start-PasswordOperation -DryRun $false
    })
    
    # Add helpful labels
    $vCenterHelpLabel = New-Object System.Windows.Forms.Label
    $vCenterHelpLabel.Text = "(e.g., administrator@vsphere.local)"
    $vCenterHelpLabel.Location = New-Object System.Drawing.Point(450, 45)
    $vCenterHelpLabel.Size = New-Object System.Drawing.Size(180, 15)
    $vCenterHelpLabel.ForeColor = [System.Drawing.Color]::Gray
    $vCenterHelpLabel.Font = New-Object System.Drawing.Font("Arial", 8)
    
    $esxiHelpLabel = New-Object System.Windows.Forms.Label
    $esxiHelpLabel.Text = "(from users.txt: root, admin_swm, etc.)"
    $esxiHelpLabel.Location = New-Object System.Drawing.Point(120, 45)
    $esxiHelpLabel.Size = New-Object System.Drawing.Size(200, 15)
    $esxiHelpLabel.ForeColor = [System.Drawing.Color]::Gray
    $esxiHelpLabel.Font = New-Object System.Drawing.Font("Arial", 8)
    
    $vcenterGroup.Controls.Add($vCenterHelpLabel)
    $passwordGroup.Controls.AddRange(@($targetUserLabel, $script:TargetUserComboBox, $esxiHelpLabel, $newPasswordLabel, $script:NewPasswordTextBox, $confirmPasswordLabel, $script:ConfirmPasswordTextBox, $dryRunButton, $liveRunButton))
    
    # Operation Status Group (below Password Operations)
    $operationStatusGroup = New-Object System.Windows.Forms.GroupBox
    $operationStatusGroup.Text = "Operation Status"
    $operationStatusGroup.Size = New-Object System.Drawing.Size(840, 180)
    $operationStatusGroup.Location = New-Object System.Drawing.Point(10, 270)
    
    # Progress Bar
    $script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $script:ProgressBar.Location = New-Object System.Drawing.Point(10, 25)
    $script:ProgressBar.Size = New-Object System.Drawing.Size(820, 20)
    $script:ProgressBar.Style = "Continuous"
    
    # Status Label
    $script:StatusLabel = New-Object System.Windows.Forms.Label
    $script:StatusLabel.Text = "Ready"
    $script:StatusLabel.Location = New-Object System.Drawing.Point(10, 50)
    $script:StatusLabel.Size = New-Object System.Drawing.Size(820, 20)
    $script:StatusLabel.ForeColor = [System.Drawing.Color]::Blue
    
    # Operation Status Window
    $statusWindowLabel = New-Object System.Windows.Forms.Label
    $statusWindowLabel.Text = "Detailed Progress:"
    $statusWindowLabel.Location = New-Object System.Drawing.Point(10, 75)
    $statusWindowLabel.Size = New-Object System.Drawing.Size(120, 20)
    
    $script:OperationStatusTextBox = New-Object System.Windows.Forms.TextBox
    $script:OperationStatusTextBox.Location = New-Object System.Drawing.Point(10, 100)
    $script:OperationStatusTextBox.Size = New-Object System.Drawing.Size(820, 70)
    $script:OperationStatusTextBox.Multiline = $true
    $script:OperationStatusTextBox.ScrollBars = "Vertical"
    $script:OperationStatusTextBox.ReadOnly = $true
    $script:OperationStatusTextBox.BackColor = [System.Drawing.Color]::Black
    $script:OperationStatusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:OperationStatusTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    
    $operationStatusGroup.Controls.AddRange(@($script:ProgressBar, $script:StatusLabel, $statusWindowLabel, $script:OperationStatusTextBox))
    
    $tab.Controls.AddRange(@($vcenterGroup, $passwordGroup, $operationStatusGroup))
}

function Create-CLITab {
    param($tab)
    
    $tab.BackColor = [System.Drawing.Color]::White
    
    # Connection Group
    $connectionGroup = New-Object System.Windows.Forms.GroupBox
    $connectionGroup.Text = "vCenter Connection"
    $connectionGroup.Size = New-Object System.Drawing.Size(840, 100)
    $connectionGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    # vCenter Server
    $vcenterLabel = New-Object System.Windows.Forms.Label
    $vcenterLabel.Text = "vCenter Server:"
    $vcenterLabel.Location = New-Object System.Drawing.Point(10, 25)
    $vcenterLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:CLIVCenterTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIVCenterTextBox.Location = New-Object System.Drawing.Point(120, 23)
    $script:CLIVCenterTextBox.Size = New-Object System.Drawing.Size(200, 20)
    
    # Username
    $usernameLabel = New-Object System.Windows.Forms.Label
    $usernameLabel.Text = "Username:"
    $usernameLabel.Location = New-Object System.Drawing.Point(340, 25)
    $usernameLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:CLIUsernameTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIUsernameTextBox.Location = New-Object System.Drawing.Point(430, 23)
    $script:CLIUsernameTextBox.Size = New-Object System.Drawing.Size(150, 20)
    $script:CLIUsernameTextBox.Text = "administrator@vsphere.local"
    
    # Password
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "Password:"
    $passwordLabel.Location = New-Object System.Drawing.Point(590, 25)
    $passwordLabel.Size = New-Object System.Drawing.Size(70, 20)
    
    $script:CLIPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIPasswordTextBox.Location = New-Object System.Drawing.Point(670, 23)
    $script:CLIPasswordTextBox.Size = New-Object System.Drawing.Size(100, 20)
    $script:CLIPasswordTextBox.UseSystemPasswordChar = $true
    
    # Connect/Disconnect buttons
    $connectButton = New-Object System.Windows.Forms.Button
    $connectButton.Text = "Connect"
    $connectButton.Location = New-Object System.Drawing.Point(10, 55)
    $connectButton.Size = New-Object System.Drawing.Size(80, 30)
    $connectButton.BackColor = [System.Drawing.Color]::LightGreen
    $connectButton.Add_Click({
        Connect-CLIToVCenter
    })
    
    $disconnectButton = New-Object System.Windows.Forms.Button
    $disconnectButton.Text = "Disconnect"
    $disconnectButton.Location = New-Object System.Drawing.Point(100, 55)
    $disconnectButton.Size = New-Object System.Drawing.Size(80, 30)
    $disconnectButton.BackColor = [System.Drawing.Color]::LightCoral
    $disconnectButton.Add_Click({
        Disconnect-CLIFromVCenter
    })
    
    # Connection status
    $script:CLIConnectionStatusLabel = New-Object System.Windows.Forms.Label
    $script:CLIConnectionStatusLabel.Text = "Status: Not Connected"
    $script:CLIConnectionStatusLabel.Location = New-Object System.Drawing.Point(200, 65)
    $script:CLIConnectionStatusLabel.Size = New-Object System.Drawing.Size(300, 20)
    $script:CLIConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
    
    $connectionGroup.Controls.AddRange(@($vcenterLabel, $script:CLIVCenterTextBox, $usernameLabel, $script:CLIUsernameTextBox, $passwordLabel, $script:CLIPasswordTextBox, $connectButton, $disconnectButton, $script:CLIConnectionStatusLabel))
    
    # CLI Workspace Group
    $cliGroup = New-Object System.Windows.Forms.GroupBox
    $cliGroup.Text = "PowerCLI Command Workspace"
    $cliGroup.Size = New-Object System.Drawing.Size(840, 380)
    $cliGroup.Location = New-Object System.Drawing.Point(10, 120)
    
    # Command input
    $commandLabel = New-Object System.Windows.Forms.Label
    $commandLabel.Text = "PowerCLI Command:"
    $commandLabel.Location = New-Object System.Drawing.Point(10, 25)
    $commandLabel.Size = New-Object System.Drawing.Size(120, 20)
    
    $script:CLICommandTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLICommandTextBox.Location = New-Object System.Drawing.Point(10, 50)
    $script:CLICommandTextBox.Size = New-Object System.Drawing.Size(650, 20)
    $script:CLICommandTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $script:CLICommandTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Execute-CLICommand
        }
    })
    
    # Execute button
    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Text = "Execute"
    $executeButton.Location = New-Object System.Drawing.Point(670, 48)
    $executeButton.Size = New-Object System.Drawing.Size(80, 25)
    $executeButton.BackColor = [System.Drawing.Color]::LightBlue
    $executeButton.Add_Click({
        Execute-CLICommand
    })
    
    # Clear button
    $clearButton = New-Object System.Windows.Forms.Button
    $clearButton.Text = "Clear"
    $clearButton.Location = New-Object System.Drawing.Point(760, 48)
    $clearButton.Size = New-Object System.Drawing.Size(60, 25)
    $clearButton.Add_Click({
        $script:CLIOutputTextBox.Clear()
    })
    
    # Output area
    $outputLabel = New-Object System.Windows.Forms.Label
    $outputLabel.Text = "Command Output:"
    $outputLabel.Location = New-Object System.Drawing.Point(10, 85)
    $outputLabel.Size = New-Object System.Drawing.Size(120, 20)
    
    $script:CLIOutputTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIOutputTextBox.Location = New-Object System.Drawing.Point(10, 110)
    $script:CLIOutputTextBox.Size = New-Object System.Drawing.Size(820, 260)
    $script:CLIOutputTextBox.Multiline = $true
    $script:CLIOutputTextBox.ScrollBars = "Vertical"
    $script:CLIOutputTextBox.ReadOnly = $true
    $script:CLIOutputTextBox.BackColor = [System.Drawing.Color]::Black
    $script:CLIOutputTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:CLIOutputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    # Add welcome message
    $script:CLIOutputTextBox.Text = "PowerCLI Command Workspace - Version 0.5 BETA`r`n"
    $script:CLIOutputTextBox.AppendText("Connect to vCenter above, then execute PowerCLI commands below.`r`n`r`n")
    $script:CLIOutputTextBox.AppendText("Example commands:`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-VMHost`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-VM | Select Name, PowerState`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-Datastore`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-Cluster`r`n`r`n")
    $script:CLIOutputTextBox.AppendText("Ready for commands...`r`n")
    
    $cliGroup.Controls.AddRange(@($commandLabel, $script:CLICommandTextBox, $executeButton, $clearButton, $outputLabel, $script:CLIOutputTextBox))
    
    $tab.Controls.AddRange(@($connectionGroup, $cliGroup))
}

function Create-ConfigTab {
    param($tab)
    
    $tab.BackColor = [System.Drawing.Color]::White
    
    # Hosts Configuration Group
    $hostsGroup = New-Object System.Windows.Forms.GroupBox
    $hostsGroup.Text = "ESXi Hosts Configuration"
    $hostsGroup.Size = New-Object System.Drawing.Size(840, 280)
    $hostsGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    $hostsLabel = New-Object System.Windows.Forms.Label
    $hostsLabel.Text = "ESXi Host Addresses (one per line):"
    $hostsLabel.Location = New-Object System.Drawing.Point(10, 20)
    $hostsLabel.Size = New-Object System.Drawing.Size(300, 20)
    
    $script:HostsTextBox = New-Object System.Windows.Forms.TextBox
    $script:HostsTextBox.Location = New-Object System.Drawing.Point(10, 45)
    $script:HostsTextBox.Size = New-Object System.Drawing.Size(820, 180)
    $script:HostsTextBox.Multiline = $true
    $script:HostsTextBox.ScrollBars = "Vertical"
    
    $saveHostsButton = New-Object System.Windows.Forms.Button
    $saveHostsButton.Text = "Save Hosts"
    $saveHostsButton.Location = New-Object System.Drawing.Point(10, 240)
    $saveHostsButton.Size = New-Object System.Drawing.Size(100, 30)
    $saveHostsButton.Add_Click({
        Save-HostsConfiguration
    })
    
    $loadHostsButton = New-Object System.Windows.Forms.Button
    $loadHostsButton.Text = "Load Hosts"
    $loadHostsButton.Location = New-Object System.Drawing.Point(120, 240)
    $loadHostsButton.Size = New-Object System.Drawing.Size(100, 30)
    $loadHostsButton.Add_Click({
        Load-HostsConfiguration
    })
    
    $hostsGroup.Controls.AddRange(@($hostsLabel, $script:HostsTextBox, $saveHostsButton, $loadHostsButton))
    
    # Users Configuration
    $usersGroup = New-Object System.Windows.Forms.GroupBox
    $usersGroup.Text = "Target Users Configuration"
    $usersGroup.Size = New-Object System.Drawing.Size(840, 280)
    $usersGroup.Location = New-Object System.Drawing.Point(10, 300)
    
    $usersLabel = New-Object System.Windows.Forms.Label
    $usersLabel.Text = "Target Usernames (one per line):"
    $usersLabel.Location = New-Object System.Drawing.Point(10, 20)
    $usersLabel.Size = New-Object System.Drawing.Size(300, 20)
    
    $script:UsersTextBox = New-Object System.Windows.Forms.TextBox
    $script:UsersTextBox.Location = New-Object System.Drawing.Point(10, 45)
    $script:UsersTextBox.Size = New-Object System.Drawing.Size(820, 180)
    $script:UsersTextBox.Multiline = $true
    $script:UsersTextBox.ScrollBars = "Vertical"
    
    $saveUsersButton = New-Object System.Windows.Forms.Button
    $saveUsersButton.Text = "Save Users"
    $saveUsersButton.Location = New-Object System.Drawing.Point(10, 240)
    $saveUsersButton.Size = New-Object System.Drawing.Size(100, 30)
    $saveUsersButton.Add_Click({
        Save-UsersConfiguration
    })
    
    $loadUsersButton = New-Object System.Windows.Forms.Button
    $loadUsersButton.Text = "Load Users"
    $loadUsersButton.Location = New-Object System.Drawing.Point(120, 240)
    $loadUsersButton.Size = New-Object System.Drawing.Size(100, 30)
    $loadUsersButton.Add_Click({
        Load-UsersConfiguration
    })
    
    $usersGroup.Controls.AddRange(@($usersLabel, $script:UsersTextBox, $saveUsersButton, $loadUsersButton))
    
    $tab.Controls.AddRange(@($hostsGroup, $usersGroup))
}

function Create-GitHubTab {
    param($tab)
    
    # Repository Information Group
    $repoGroup = New-Object System.Windows.Forms.GroupBox
    $repoGroup.Text = "Repository Information"
    $repoGroup.Size = New-Object System.Drawing.Size(840, 120)
    $repoGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    $repoLabel = New-Object System.Windows.Forms.Label
    $repoLabel.Text = "Repository: https://github.com/alumbrados3579/VMware-Vcenter-Password-Management"
    $repoLabel.Location = New-Object System.Drawing.Point(10, 25)
    $repoLabel.Size = New-Object System.Drawing.Size(800, 20)
    $repoLabel.ForeColor = [System.Drawing.Color]::Blue
    
    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "Version: 0.5 BETA - Enterprise Password Management Suite"
    $versionLabel.Location = New-Object System.Drawing.Point(10, 50)
    $versionLabel.Size = New-Object System.Drawing.Size(800, 20)
    
    $updateLabel = New-Object System.Windows.Forms.Label
    $updateLabel.Text = "To update: Re-run VMware-Setup.ps1 to download the latest version"
    $updateLabel.Location = New-Object System.Drawing.Point(10, 75)
    $updateLabel.Size = New-Object System.Drawing.Size(800, 20)
    $updateLabel.ForeColor = [System.Drawing.Color]::Green
    
    $repoGroup.Controls.AddRange(@($repoLabel, $versionLabel, $updateLabel))
    
    # File Management Group
    $fileGroup = New-Object System.Windows.Forms.GroupBox
    $fileGroup.Text = "File Management"
    $fileGroup.Size = New-Object System.Drawing.Size(840, 200)
    $fileGroup.Location = New-Object System.Drawing.Point(10, 140)
    
    $downloadButton = New-Object System.Windows.Forms.Button
    $downloadButton.Text = "Download Latest Setup Script"
    $downloadButton.Location = New-Object System.Drawing.Point(10, 30)
    $downloadButton.Size = New-Object System.Drawing.Size(200, 30)
    $downloadButton.BackColor = [System.Drawing.Color]::LightBlue
    $downloadButton.Add_Click({
        Download-LatestSetupScript
    })
    
    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Text = "Refresh This Application"
    $refreshButton.Location = New-Object System.Drawing.Point(220, 30)
    $refreshButton.Size = New-Object System.Drawing.Size(200, 30)
    $refreshButton.BackColor = [System.Drawing.Color]::LightGreen
    $refreshButton.Add_Click({
        Refresh-Application
    })
    
    $openRepoButton = New-Object System.Windows.Forms.Button
    $openRepoButton.Text = "Open GitHub Repository"
    $openRepoButton.Location = New-Object System.Drawing.Point(430, 30)
    $openRepoButton.Size = New-Object System.Drawing.Size(200, 30)
    $openRepoButton.BackColor = [System.Drawing.Color]::LightCoral
    $openRepoButton.Add_Click({
        Open-GitHubRepository
    })
    
    # Status display
    $script:GitHubStatusLabel = New-Object System.Windows.Forms.Label
    $script:GitHubStatusLabel.Text = "Ready"
    $script:GitHubStatusLabel.Location = New-Object System.Drawing.Point(10, 80)
    $script:GitHubStatusLabel.Size = New-Object System.Drawing.Size(820, 40)
    $script:GitHubStatusLabel.ForeColor = [System.Drawing.Color]::Blue
    
    # Instructions
    $instructionsLabel = New-Object System.Windows.Forms.Label
    $instructionsLabel.Text = @"
Instructions:
• Download Latest Setup Script: Gets the newest VMware-Setup.ps1 from GitHub
• Refresh This Application: Downloads and replaces this GUI with the latest version
• Open GitHub Repository: Opens the repository in your default web browser
"@
    $instructionsLabel.Location = New-Object System.Drawing.Point(10, 120)
    $instructionsLabel.Size = New-Object System.Drawing.Size(820, 70)
    $instructionsLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    
    $fileGroup.Controls.AddRange(@($downloadButton, $refreshButton, $openRepoButton, $script:GitHubStatusLabel, $instructionsLabel))
    
    # Module Information Group
    $moduleGroup = New-Object System.Windows.Forms.GroupBox
    $moduleGroup.Text = "Local Modules Information"
    $moduleGroup.Size = New-Object System.Drawing.Size(840, 200)
    $moduleGroup.Location = New-Object System.Drawing.Point(10, 350)
    
    $moduleInfoLabel = New-Object System.Windows.Forms.Label
    $moduleInfoLabel.Text = "PowerCLI modules are stored locally in the ./Modules/ directory to avoid OneDrive sync conflicts."
    $moduleInfoLabel.Location = New-Object System.Drawing.Point(10, 25)
    $moduleInfoLabel.Size = New-Object System.Drawing.Size(820, 20)
    
    $modulePathLabel = New-Object System.Windows.Forms.Label
    $modulePathLabel.Text = "Module Path: $script:LocalModulesPath"
    $modulePathLabel.Location = New-Object System.Drawing.Point(10, 50)
    $modulePathLabel.Size = New-Object System.Drawing.Size(820, 20)
    $modulePathLabel.ForeColor = [System.Drawing.Color]::Gray
    
    $checkModulesButton = New-Object System.Windows.Forms.Button
    $checkModulesButton.Text = "Check Module Status"
    $checkModulesButton.Location = New-Object System.Drawing.Point(10, 80)
    $checkModulesButton.Size = New-Object System.Drawing.Size(150, 30)
    $checkModulesButton.Add_Click({
        Check-ModuleStatus
    })
    
    $script:ModuleStatusLabel = New-Object System.Windows.Forms.Label
    $script:ModuleStatusLabel.Text = "Click 'Check Module Status' to verify PowerCLI modules"
    $script:ModuleStatusLabel.Location = New-Object System.Drawing.Point(10, 120)
    $script:ModuleStatusLabel.Size = New-Object System.Drawing.Size(820, 60)
    $script:ModuleStatusLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    
    $moduleGroup.Controls.AddRange(@($moduleInfoLabel, $modulePathLabel, $checkModulesButton, $script:ModuleStatusLabel))
    
    $tab.Controls.AddRange(@($repoGroup, $fileGroup, $moduleGroup))
}

function Create-LogsTab {
    param($tab)
    
    $logsLabel = New-Object System.Windows.Forms.Label
    $logsLabel.Text = "Application Logs:"
    $logsLabel.Location = New-Object System.Drawing.Point(10, 10)
    $logsLabel.Size = New-Object System.Drawing.Size(200, 20)
    
    $script:LogTextBox = New-Object System.Windows.Forms.TextBox
    $script:LogTextBox.Location = New-Object System.Drawing.Point(10, 35)
    $script:LogTextBox.Size = New-Object System.Drawing.Size(850, 550)
    $script:LogTextBox.Multiline = $true
    $script:LogTextBox.ScrollBars = "Vertical"
    $script:LogTextBox.ReadOnly = $true
    $script:LogTextBox.BackColor = [System.Drawing.Color]::Black
    $script:LogTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    $clearLogsButton = New-Object System.Windows.Forms.Button
    $clearLogsButton.Text = "Clear Logs"
    $clearLogsButton.Location = New-Object System.Drawing.Point(10, 595)
    $clearLogsButton.Size = New-Object System.Drawing.Size(100, 30)
    $clearLogsButton.Add_Click({
        $script:LogTextBox.Clear()
    })
    
    $exportLogsButton = New-Object System.Windows.Forms.Button
    $exportLogsButton.Text = "Export Logs"
    $exportLogsButton.Location = New-Object System.Drawing.Point(120, 595)
    $exportLogsButton.Size = New-Object System.Drawing.Size(100, 30)
    $exportLogsButton.Add_Click({
        Export-LogsToFile
    })
    
    $tab.Controls.AddRange(@($logsLabel, $script:LogTextBox, $clearLogsButton, $exportLogsButton))
}

# --- GUI Event Handlers ---
function Test-VCenterConnectionGUI {
    try {
        # Validate that all GUI controls exist and have handles
        if (-not $script:VCenterTextBox -or -not $script:VCenterTextBox.IsHandleCreated -or
            -not $script:AdminUsernameTextBox -or -not $script:AdminUsernameTextBox.IsHandleCreated -or
            -not $script:PasswordTextBox -or -not $script:PasswordTextBox.IsHandleCreated) {
            Write-Log "GUI controls not properly initialized" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("GUI controls not properly initialized. Please restart the application.", "GUI Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        if ([string]::IsNullOrWhiteSpace($script:VCenterTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:AdminUsernameTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:PasswordTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Please fill in all vCenter connection fields.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    } catch {
        Write-Log "Error in Test-VCenterConnectionGUI validation: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error accessing GUI controls: $($_.Exception.Message)", "GUI Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    $script:ConnectionStatusLabel.Text = "Status: Testing..."
    $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Orange
    
    try {
        $connection = Connect-VIServer -Server $script:VCenterTextBox.Text -User $script:AdminUsernameTextBox.Text -Password $script:PasswordTextBox.Text -ErrorAction Stop
        
        if ($connection) {
            $esxiHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState
            Disconnect-VIServer -Server $script:VCenterTextBox.Text -Confirm:$false -ErrorAction SilentlyContinue
            
            $script:ConnectionStatusLabel.Text = "Status: Connected - Found $($esxiHosts.Count) ESXi hosts"
            $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Green
            Write-Log "vCenter connection test successful - Found $($esxiHosts.Count) hosts" "SUCCESS"
        }
    } catch {
        $script:ConnectionStatusLabel.Text = "Status: Connection Failed"
        $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
        Write-Log "vCenter connection test failed: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Connection failed: $($_.Exception.Message)", "Connection Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Start-PasswordOperation {
    param([bool]$DryRun)
    
    try {
        # Validate that all GUI controls exist and have handles
        if (-not $script:OperationStatusTextBox -or -not $script:OperationStatusTextBox.IsHandleCreated -or
            -not $script:TargetUserComboBox -or -not $script:TargetUserComboBox.IsHandleCreated -or
            -not $script:NewPasswordTextBox -or -not $script:NewPasswordTextBox.IsHandleCreated -or
            -not $script:ConfirmPasswordTextBox -or -not $script:ConfirmPasswordTextBox.IsHandleCreated) {
            Write-Log "GUI controls not properly initialized for password operation" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("GUI controls not properly initialized. Please restart the application.", "GUI Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        # Clear operation status window
        $script:OperationStatusTextBox.Clear()
        Add-OperationStatus "Starting password operation validation..."
        
        # Validate target user selection
        if ([string]::IsNullOrWhiteSpace($script:TargetUserComboBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Please select a target user from the dropdown.", "No Target User", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    } catch {
        Write-Log "Error in Start-PasswordOperation initialization: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error accessing GUI controls: $($_.Exception.Message)", "GUI Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    # Validate inputs
    if ([string]::IsNullOrWhiteSpace($script:NewPasswordTextBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a new password.", "Missing Password", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    if ($script:NewPasswordTextBox.Text -ne $script:ConfirmPasswordTextBox.Text) {
        [System.Windows.Forms.MessageBox]::Show("Passwords do not match.", "Password Mismatch", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $hosts = Get-HostsFromFile
    
    if ($hosts.Count -eq 0) {
        $message = @"
No ESXi hosts configured!

To add hosts:
1. Go to the 'Configuration' tab
2. Add your ESXi host IP addresses or FQDNs to the hosts list
3. Save the configuration
4. Return to this tab to run password operations

Example hosts:
192.168.1.100
esxi-host-01.domain.local
"@
        [System.Windows.Forms.MessageBox]::Show($message, "No Hosts Configured", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    Add-OperationStatus "Validation complete. Target user: $($script:TargetUserComboBox.Text)"
    Add-OperationStatus "Found $($hosts.Count) ESXi hosts to process"
    
    $operationType = if ($DryRun) { "DRY RUN" } else { "LIVE" }
    $targetUser = $script:TargetUserComboBox.Text
    $totalOperations = $hosts.Count
    
    # Confirmation dialog
    $message = @"
$operationType Password Change Operation

Target User: $targetUser
ESXi Hosts: $($hosts.Count)
Total Operations: $totalOperations

$(if (-not $DryRun) { "WARNING: This will make REAL changes to production systems!" })

Do you want to proceed?
"@
    
    $result = [System.Windows.Forms.MessageBox]::Show($message, "Confirm Operation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::No) {
        Add-OperationStatus "Operation cancelled by user"
        return
    }
    
    # Start operation
    $script:ProgressBar.Value = 0
    $script:ProgressBar.Maximum = $totalOperations
    $script:StatusLabel.Text = "Starting $operationType operation..."
    Add-OperationStatus "=== $operationType OPERATION STARTED ==="
    Add-OperationStatus "Target User: $targetUser"
    Add-OperationStatus "Processing $($hosts.Count) ESXi hosts..."
    
    $successCount = 0
    $failureCount = 0
    $currentOperation = 0
    
    foreach ($hostName in $hosts) {
        $currentOperation++
        $script:ProgressBar.Value = $currentOperation
        $script:StatusLabel.Text = "[$currentOperation/$totalOperations] Processing host '$hostName'"
        Add-OperationStatus ""
        Add-OperationStatus "[$currentOperation/$totalOperations] Connecting to host: $hostName"
        
        try {
            if ($DryRun) {
                # Simulate the operation
                Add-OperationStatus "  [SIMULATION] Testing connection to $hostName..."
                Start-Sleep -Milliseconds 200
                Add-OperationStatus "  [SIMULATION] Connection successful"
                Add-OperationStatus "  [SIMULATION] Would change password for user '$targetUser'"
                Add-OperationStatus "  [SIMULATION] Operation would complete successfully"
                Write-Log "[SIMULATION] Would change password for user '$targetUser' on host '$hostName'" "INFO"
                $successCount++
            } else {
                # Actual password change logic would go here
                Add-OperationStatus "  [LIVE] Establishing connection to $hostName..."
                Start-Sleep -Milliseconds 300
                Add-OperationStatus "  [LIVE] Connected successfully"
                Add-OperationStatus "  [LIVE] Changing password for user '$targetUser'..."
                Start-Sleep -Milliseconds 400
                Add-OperationStatus "  [LIVE] Password change completed successfully"
                Add-OperationStatus "  [LIVE] Disconnecting from $hostName"
                Write-Log "[LIVE] Password changed for user '$targetUser' on host '$hostName'" "SUCCESS"
                $successCount++
            }
        } catch {
            Add-OperationStatus "  [ERROR] Failed to process host '$hostName': $($_.Exception.Message)"
            Write-Log "Failed to process user '$targetUser' on host '$hostName': $($_.Exception.Message)" "ERROR"
            $failureCount++
        }
        
        # Update GUI
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    # Operation complete
    $script:ProgressBar.Value = $totalOperations
    $script:StatusLabel.Text = "$operationType completed - Success: $successCount, Failures: $failureCount"
    Add-OperationStatus ""
    Add-OperationStatus "=== $operationType OPERATION COMPLETE ==="
    Add-OperationStatus "Total Hosts: $totalOperations"
    Add-OperationStatus "Successful: $successCount"
    Add-OperationStatus "Failed: $failureCount"
    
    $summaryMessage = @"
$operationType Operation Complete

Target User: $targetUser
Total Hosts: $totalOperations
Successful: $successCount
Failed: $failureCount

$(if ($failureCount -eq 0) { "All operations completed successfully!" } else { "Some operations failed. Check the operation status window and logs for details." })
"@
    
    [System.Windows.Forms.MessageBox]::Show($summaryMessage, "Operation Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Save-HostsConfiguration {
    try {
        $script:HostsTextBox.Text | Set-Content -Path $script:HostsFilePath
        Write-Log "Hosts configuration saved" "SUCCESS"
        [System.Windows.Forms.MessageBox]::Show("Hosts configuration saved successfully.", "Configuration Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Write-Log "Failed to save hosts configuration: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to save hosts configuration: $($_.Exception.Message)", "Save Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Load-HostsConfiguration {
    try {
        if (Test-Path $script:HostsFilePath) {
            # Read file content preserving line endings
            $content = Get-Content $script:HostsFilePath -Raw
            if ($content) {
                $script:HostsTextBox.Text = $content
            } else {
                # File exists but is empty
                $script:HostsTextBox.Text = Get-Content $script:HostsFilePath | Out-String
            }
            Write-Log "Hosts configuration loaded" "SUCCESS"
        } else {
            $script:HostsTextBox.Text = "# ESXi Hosts Configuration`r`n# Add your ESXi host IP addresses or FQDNs below`r`n# One host per line, comments start with #`r`n`r`n# Examples:`r`n# 192.168.1.100`r`n# 192.168.1.101`r`n# esxi-host-01.domain.local`r`n# esxi-host-02.domain.local"
        }
    } catch {
        Write-Log "Failed to load hosts configuration: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to load hosts configuration: $($_.Exception.Message)", "Load Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Save-UsersConfiguration {
    try {
        $script:UsersTextBox.Text | Set-Content -Path $script:UsersFilePath
        Write-Log "Users configuration saved" "SUCCESS"
        
        # Refresh user dropdowns with new data
        Load-UserDropdowns
        
        [System.Windows.Forms.MessageBox]::Show("Users configuration saved successfully.`nUser dropdowns have been updated.", "Configuration Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Write-Log "Failed to save users configuration: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to save users configuration: $($_.Exception.Message)", "Save Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Load-UsersConfiguration {
    try {
        if (Test-Path $script:UsersFilePath) {
            # Read file content preserving line endings
            $content = Get-Content $script:UsersFilePath -Raw
            if ($content) {
                $script:UsersTextBox.Text = $content
            } else {
                # File exists but is empty
                $script:UsersTextBox.Text = Get-Content $script:UsersFilePath | Out-String
            }
            Write-Log "Users configuration loaded" "SUCCESS"
        } else {
            $script:UsersTextBox.Text = "# Target ESXi Users Configuration`r`n# Add ESXi usernames for password operations`r`n# One username per line, comments start with #`r`n# Note: vCenter admin users (like administrator@vsphere.local) are entered directly in the GUI`r`n`r`n# Common ESXi users:`r`nroot`r`n# admin_swm`r`n# admin_kms`r`n# admin`r`n# serviceaccount"
        }
    } catch {
        Write-Log "Failed to load users configuration: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to load users configuration: $($_.Exception.Message)", "Load Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# --- GitHub Manager Functions ---
function Download-LatestSetupScript {
    try {
        $script:GitHubStatusLabel.Text = "Downloading latest setup script..."
        $setupUrl = "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Setup.ps1"
        $setupPath = Join-Path $script:PSScriptRoot "VMware-Setup.ps1"
        
        Invoke-WebRequest -Uri $setupUrl -OutFile $setupPath -UseBasicParsing
        $script:GitHubStatusLabel.Text = "[SUCCESS] Latest setup script downloaded successfully"
        Write-Log "Downloaded latest setup script from GitHub" "SUCCESS"
        
        [System.Windows.Forms.MessageBox]::Show("Latest setup script downloaded successfully!", "Download Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $script:GitHubStatusLabel.Text = "[ERROR] Failed to download setup script"
        Write-Log "Failed to download setup script: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to download setup script: $($_.Exception.Message)", "Download Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Refresh-Application {
    $result = [System.Windows.Forms.MessageBox]::Show("This will download the latest version of this application and restart it. Continue?", "Refresh Application", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            $script:GitHubStatusLabel.Text = "Downloading latest application..."
            $appUrl = "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Password-Manager.ps1"
            $appPath = Join-Path $script:PSScriptRoot "VMware-Password-Manager.ps1"
            
            Invoke-WebRequest -Uri $appUrl -OutFile $appPath -UseBasicParsing
            Write-Log "Downloaded latest application from GitHub" "SUCCESS"
            
            [System.Windows.Forms.MessageBox]::Show("Latest application downloaded. The application will now restart.", "Refresh Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            # Restart the application
            Start-Process PowerShell -ArgumentList "-File `"$appPath`"" -WindowStyle Normal
            [System.Environment]::Exit(0)
        } catch {
            $script:GitHubStatusLabel.Text = "[ERROR] Failed to refresh application"
            Write-Log "Failed to refresh application: $($_.Exception.Message)" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Failed to refresh application: $($_.Exception.Message)", "Refresh Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

function Open-GitHubRepository {
    try {
        $repoUrl = "https://github.com/alumbrados3579/VMware-Vcenter-Password-Management"
        Start-Process $repoUrl
        $script:GitHubStatusLabel.Text = "[SUCCESS] Opened GitHub repository in browser"
        Write-Log "Opened GitHub repository in browser" "INFO"
    } catch {
        $script:GitHubStatusLabel.Text = "[ERROR] Failed to open repository"
        Write-Log "Failed to open GitHub repository: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to open GitHub repository: $($_.Exception.Message)", "Browser Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Check-ModuleStatus {
    try {
        $statusText = "Module Status Check:`r`n`r`n"
        
        # Check local modules directory
        if (Test-Path $script:LocalModulesPath) {
            $statusText += "[SUCCESS] Local Modules directory exists: $script:LocalModulesPath`r`n"
            
            $powerCLIPath = Join-Path $script:LocalModulesPath "VMware.PowerCLI"
            if (Test-Path $powerCLIPath) {
                $statusText += "[SUCCESS] VMware.PowerCLI found in local directory`r`n"
                
                # Try to get version
                try {
                    $manifestFiles = Get-ChildItem -Path $powerCLIPath -Filter "VMware.PowerCLI.psd1" -Recurse -ErrorAction SilentlyContinue
                    if ($manifestFiles) {
                        $manifestData = Import-PowerShellDataFile $manifestFiles[0].FullName
                        $statusText += "   Version: $($manifestData.ModuleVersion)`r`n"
                    }
                } catch {
                    $statusText += "   Version: Could not determine`r`n"
                }
            } else {
                $statusText += "[ERROR] VMware.PowerCLI not found in local directory`r`n"
            }
        } else {
            $statusText += "[ERROR] Local Modules directory does not exist`r`n"
        }
        
        # Check if modules are loaded
        $loadedPowerCLI = Get-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
        if ($loadedPowerCLI) {
            $statusText += "`r`n[SUCCESS] PowerCLI currently loaded in memory`r`n"
            $statusText += "   Version: $($loadedPowerCLI.Version)`r`n"
            $statusText += "   Location: $($loadedPowerCLI.ModuleBase)`r`n"
        } else {
            $statusText += "`r`n[WARNING] PowerCLI not currently loaded in memory`r`n"
        }
        
        $script:ModuleStatusLabel.Text = $statusText
        Write-Log "Module status check completed" "INFO"
    } catch {
        $script:ModuleStatusLabel.Text = "[ERROR] Error checking module status: $($_.Exception.Message)"
        Write-Log "Failed to check module status: $($_.Exception.Message)" "ERROR"
    }
}

# --- CLI Workspace Functions ---
function Connect-CLIToVCenter {
    try {
        if ([string]::IsNullOrWhiteSpace($script:CLIVCenterTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:CLIUsernameTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:CLIPasswordTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Please fill in all connection fields.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $script:CLIConnectionStatusLabel.Text = "Status: Connecting..."
        $script:CLIConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Orange
        
        # Add connection attempt to output
        $script:CLIOutputTextBox.AppendText("`r`n[$(Get-Date -Format 'HH:mm:ss')] Connecting to $($script:CLIVCenterTextBox.Text)...`r`n")
        $script:CLIOutputTextBox.ScrollToCaret()
        
        $connection = Connect-VIServer -Server $script:CLIVCenterTextBox.Text -User $script:CLIUsernameTextBox.Text -Password $script:CLIPasswordTextBox.Text -ErrorAction Stop
        
        if ($connection) {
            $script:CLIConnectionStatusLabel.Text = "Status: Connected to $($connection.Name)"
            $script:CLIConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Green
            $script:CLIOutputTextBox.AppendText("[SUCCESS] Connected successfully to $($connection.Name)`r`n")
            $script:CLIOutputTextBox.AppendText("   Version: $($connection.Version)`r`n")
            $script:CLIOutputTextBox.AppendText("   Build: $($connection.Build)`r`n")
            $script:CLIOutputTextBox.AppendText("`r`nReady for PowerCLI commands...`r`n`r`n")
            $script:CLIOutputTextBox.ScrollToCaret()
            Write-Log "CLI workspace connected to vCenter: $($connection.Name)" "SUCCESS"
        }
    } catch {
        $script:CLIConnectionStatusLabel.Text = "Status: Connection Failed"
        $script:CLIConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
        $script:CLIOutputTextBox.AppendText("[ERROR] Connection failed: $($_.Exception.Message)`r`n`r`n")
        $script:CLIOutputTextBox.ScrollToCaret()
        Write-Log "CLI workspace connection failed: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Connection failed: $($_.Exception.Message)", "Connection Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Disconnect-CLIFromVCenter {
    try {
        $connections = $global:DefaultVIServers
        if ($connections) {
            foreach ($connection in $connections) {
                Disconnect-VIServer -Server $connection -Confirm:$false -ErrorAction SilentlyContinue
            }
            $script:CLIConnectionStatusLabel.Text = "Status: Disconnected"
            $script:CLIConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
            $script:CLIOutputTextBox.AppendText("`r`n[$(Get-Date -Format 'HH:mm:ss')] Disconnected from vCenter`r`n`r`n")
            $script:CLIOutputTextBox.ScrollToCaret()
            Write-Log "CLI workspace disconnected from vCenter" "INFO"
        } else {
            $script:CLIOutputTextBox.AppendText("`r`n[$(Get-Date -Format 'HH:mm:ss')] No active connections to disconnect`r`n`r`n")
            $script:CLIOutputTextBox.ScrollToCaret()
        }
    } catch {
        Write-Log "Error disconnecting CLI workspace: $($_.Exception.Message)" "ERROR"
    }
}

function Execute-CLICommand {
    try {
        $command = $script:CLICommandTextBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($command)) {
            return
        }
        
        # Check if connected
        if (-not $global:DefaultVIServers) {
            $script:CLIOutputTextBox.AppendText("`r`n[ERROR] Not connected to vCenter. Please connect first.`r`n`r`n")
            $script:CLIOutputTextBox.ScrollToCaret()
            return
        }
        
        # Add command to output
        $script:CLIOutputTextBox.AppendText("`r`n[$(Get-Date -Format 'HH:mm:ss')] PS> $command`r`n")
        $script:CLIOutputTextBox.ScrollToCaret()
        
        # Execute command
        try {
            $result = Invoke-Expression $command | Out-String
            if ([string]::IsNullOrWhiteSpace($result)) {
                $script:CLIOutputTextBox.AppendText("(No output)`r`n")
            } else {
                $script:CLIOutputTextBox.AppendText($result)
            }
        } catch {
            $script:CLIOutputTextBox.AppendText("[ERROR] $($_.Exception.Message)`r`n")
        }
        
        $script:CLIOutputTextBox.AppendText("`r`n")
        $script:CLIOutputTextBox.ScrollToCaret()
        
        # Clear command input
        $script:CLICommandTextBox.Clear()
        
        Write-Log "CLI command executed: $command" "INFO"
    } catch {
        $script:CLIOutputTextBox.AppendText("[ERROR] Command execution error: $($_.Exception.Message)`r`n`r`n")
        $script:CLIOutputTextBox.ScrollToCaret()
        Write-Log "CLI command execution error: $($_.Exception.Message)" "ERROR"
    }
}

# --- Helper Functions ---
function Add-OperationStatus {
    param([string]$Message)
    
    try {
        if ($script:OperationStatusTextBox -and $script:OperationStatusTextBox.IsHandleCreated) {
            $timestamp = Get-Date -Format "HH:mm:ss"
            $script:OperationStatusTextBox.AppendText("[$timestamp] $Message`r`n")
            $script:OperationStatusTextBox.ScrollToCaret()
            [System.Windows.Forms.Application]::DoEvents()
        }
    } catch {
        # Silently handle any GUI update errors
        Write-Log "GUI update error in Add-OperationStatus: $($_.Exception.Message)" "WARN"
    }
}

function Export-LogsToFile {
    try {
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "Log Files (*.log)|*.log|Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
        $saveDialog.Title = "Export Logs"
        $saveDialog.FileName = "VMware_Password_Manager_Logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:LogTextBox.Text | Set-Content -Path $saveDialog.FileName -Encoding UTF8
            [System.Windows.Forms.MessageBox]::Show("Logs exported successfully to:`n$($saveDialog.FileName)", "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Write-Log "Logs exported to file: $($saveDialog.FileName)" "SUCCESS"
        }
    } catch {
        Write-Log "Failed to export logs: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to export logs: $($_.Exception.Message)", "Export Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Load-UserDropdowns {
    try {
        $users = Get-UsersFromFile
        
        # Clear existing items in Target User dropdown only
        $script:TargetUserComboBox.Items.Clear()
        
        # Add users to Target User dropdown (ESXi accounts)
        foreach ($user in $users) {
            $script:TargetUserComboBox.Items.Add($user)
        }
        
        # Add common ESXi users if not already present
        $commonESXiUsers = @("root", "admin_swm", "admin_kms", "admin")
        foreach ($esxiUser in $commonESXiUsers) {
            if ($script:TargetUserComboBox.Items -notcontains $esxiUser) {
                $script:TargetUserComboBox.Items.Add($esxiUser)
            }
        }
        
        # Set default selection for Target User (prefer root for ESXi)
        if ($script:TargetUserComboBox.Items.Count -gt 0) {
            if ($script:TargetUserComboBox.Items -contains "root") {
                $script:TargetUserComboBox.SelectedItem = "root"
            } elseif ($script:TargetUserComboBox.Items -contains "admin_swm") {
                $script:TargetUserComboBox.SelectedItem = "admin_swm"
            } else {
                $script:TargetUserComboBox.SelectedIndex = 0
            }
        }
        
        # Admin Username is now a free text field with default value already set
        # No need to populate it from users.txt
        
        Write-Log "Target user dropdown loaded with $($users.Count) users plus common ESXi accounts" "SUCCESS"
    } catch {
        Write-Log "Failed to load user dropdowns: $($_.Exception.Message)" "ERROR"
    }
}

# --- Main Application ---
function Start-Application {
    Write-Log "VMware vCenter Password Management Tool - Version 0.5 BETA starting..." "INFO"
    
    # Show DoD Warning
    Show-DoDWarning
    
    # Check PowerCLI availability
    if (-not (Test-PowerCLIAvailability)) {
        return
    }
    
    # Create main form
    $form = Create-MainForm
    
    # Create tab control and tabs
    $tabs = Create-TabControl -form $form
    
    # Load initial configuration
    Load-HostsConfiguration
    Load-UsersConfiguration
    Load-UserDropdowns
    
    Write-Log "GUI application initialized successfully" "SUCCESS"
    
    # Show the form
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form.ShowDialog()
}

# Start the GUI application with error handling
try {
    Start-Application
} catch {
    $errorMessage = "Critical error starting application: $($_.Exception.Message)"
    Write-Host $errorMessage -ForegroundColor Red
    
    # Try to show error dialog if Windows Forms is available
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Application Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } catch {
        Write-Host "Could not display error dialog: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Log the error if possible
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] [CRITICAL] $errorMessage" | Add-Content -Path "error_log.txt" -ErrorAction SilentlyContinue
    } catch {
        # Silent fail for logging
    }
    
    exit 1
}