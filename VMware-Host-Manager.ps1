# VMware vCenter Host Management Tool - Main Application
# Version 1.0 - Professional DoD-Compliant Edition
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Developed with assistance from Qodo AI
# Purpose: Professional DoD-compliant host management for VMware environments
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Global variables
$script:PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$script:LogsPath = Join-Path $script:PSScriptRoot "Logs"
$script:LogFilePath = Join-Path $script:LogsPath "vcenter_host_manager_$(Get-Date -Format 'yyyyMMdd').log"
$script:LocalModulesPath = Join-Path $script:PSScriptRoot "Modules"

# Ensure Logs directory exists
if (-not (Test-Path $script:LogsPath)) {
    New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
}

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global form controls
$script:VCenterTextBox = $null
$script:AdminUsernameTextBox = $null
$script:PasswordTextBox = $null
$script:ConnectionStatusLabel = $null
$script:OperationComboBox = $null
$script:HostNameTextBox = $null
$script:HostIPTextBox = $null
$script:HostUsernameTextBox = $null
$script:HostPasswordTextBox = $null
$script:HostListBox = $null
$script:OperationStatusTextBox = $null
$script:ProgressBar = $null

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        $logEntry | Add-Content -Path $script:LogFilePath -ErrorAction SilentlyContinue
        
        # Also write to operation status if available
        if ($script:OperationStatusTextBox) {
            $script:OperationStatusTextBox.AppendText("[$timestamp] $Message`r`n")
            $script:OperationStatusTextBox.ScrollToCaret()
        }
        
        Write-Host "[$timestamp] $Message" -ForegroundColor $(
            switch ($Level) {
                "SUCCESS" { "Green" }
                "ERROR" { "Red" }
                "WARNING" { "Yellow" }
                default { "White" }
            }
        )
    } catch {
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

VMware vCenter Host Management Tool - DoD Compliant Edition

Click OK to acknowledge and continue...
"@
    
    [System.Windows.Forms.MessageBox]::Show($dodWarning, "DoD System Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

function Test-PowerCLIAvailability {
    Write-Log "Checking VMware PowerCLI availability..." "INFO"
    
    try {
        # Check if PowerCLI is already loaded
        $loadedPowerCLI = Get-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
        
        if ($loadedPowerCLI) {
            Write-Log "VMware PowerCLI already loaded (Version: $($loadedPowerCLI.Version))" "SUCCESS"
            return $true
        }
        
        # Check local modules directory
        if (Test-Path $script:LocalModulesPath) {
            $localPowerCLI = Get-ChildItem -Path $script:LocalModulesPath -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
            if ($localPowerCLI) {
                Write-Log "Found local PowerCLI modules" "SUCCESS"
                $currentPSModulePath = $env:PSModulePath
                if ($currentPSModulePath -notlike "*$script:LocalModulesPath*") {
                    $env:PSModulePath = "$script:LocalModulesPath;$currentPSModulePath"
                    Write-Log "Added local Modules directory to PowerShell module path" "INFO"
                }
            }
        }
        
        # Try to import PowerCLI
        Import-Module VMware.PowerCLI -ErrorAction Stop
        $loadedModule = Get-Module -Name "VMware.PowerCLI"
        Write-Log "VMware PowerCLI loaded successfully (Version: $($loadedModule.Version))" "SUCCESS"
        
        # Configure PowerCLI settings
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session -ErrorAction SilentlyContinue
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope Session -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        Write-Log "Failed to load VMware PowerCLI: $($_.Exception.Message)" "ERROR"
        $message = @"
VMware PowerCLI is required but not installed.

Please run VMware-Setup.ps1 first to install PowerCLI to local Modules directory.
This avoids OneDrive sync issues and keeps modules in your working directory.

Expected local path: $script:LocalModulesPath
"@
        [System.Windows.Forms.MessageBox]::Show($message, "PowerCLI Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
}

function Create-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VMware vCenter Host Management Tool - Version 1.0"
    $form.Size = New-Object System.Drawing.Size(900, 700)
    $form.MinimumSize = New-Object System.Drawing.Size(900, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "Sizable"
    $form.MaximizeBox = $true
    $form.Icon = [System.Drawing.SystemIcons]::Shield
    
    # vCenter Connection Group
    $vcenterGroup = New-Object System.Windows.Forms.GroupBox
    $vcenterGroup.Text = "vCenter Connection"
    $vcenterGroup.Size = New-Object System.Drawing.Size(860, 120)
    $vcenterGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    # vCenter Server
    $vcenterLabel = New-Object System.Windows.Forms.Label
    $vcenterLabel.Text = "vCenter Server:"
    $vcenterLabel.Location = New-Object System.Drawing.Point(10, 25)
    $vcenterLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:VCenterTextBox = New-Object System.Windows.Forms.TextBox
    $script:VCenterTextBox.Location = New-Object System.Drawing.Point(110, 23)
    $script:VCenterTextBox.Size = New-Object System.Drawing.Size(180, 20)
    
    # Username
    $usernameLabel = New-Object System.Windows.Forms.Label
    $usernameLabel.Text = "Username:"
    $usernameLabel.Location = New-Object System.Drawing.Point(300, 25)
    $usernameLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:AdminUsernameTextBox = New-Object System.Windows.Forms.TextBox
    $script:AdminUsernameTextBox.Location = New-Object System.Drawing.Point(390, 23)
    $script:AdminUsernameTextBox.Size = New-Object System.Drawing.Size(170, 20)
    $script:AdminUsernameTextBox.Text = "administrator@vsphere.local"
    
    # Password
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "Password:"
    $passwordLabel.Location = New-Object System.Drawing.Point(570, 25)
    $passwordLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:PasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:PasswordTextBox.Location = New-Object System.Drawing.Point(660, 23)
    $script:PasswordTextBox.Size = New-Object System.Drawing.Size(170, 20)
    $script:PasswordTextBox.UseSystemPasswordChar = $true
    
    # Test Connection Button
    $testButton = New-Object System.Windows.Forms.Button
    $testButton.Text = "Test Connection"
    $testButton.Location = New-Object System.Drawing.Point(10, 60)
    $testButton.Size = New-Object System.Drawing.Size(120, 30)
    $testButton.BackColor = [System.Drawing.Color]::LightGreen
    $testButton.Add_Click({
        Test-VCenterConnection
    })
    
    # Connection Status
    $script:ConnectionStatusLabel = New-Object System.Windows.Forms.Label
    $script:ConnectionStatusLabel.Text = "Status: Not Connected"
    $script:ConnectionStatusLabel.Location = New-Object System.Drawing.Point(150, 65)
    $script:ConnectionStatusLabel.Size = New-Object System.Drawing.Size(300, 20)
    $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
    
    $vcenterGroup.Controls.AddRange(@($vcenterLabel, $script:VCenterTextBox, $usernameLabel, $script:AdminUsernameTextBox, $passwordLabel, $script:PasswordTextBox, $testButton, $script:ConnectionStatusLabel))
    
    # Host Operations Group
    $hostGroup = New-Object System.Windows.Forms.GroupBox
    $hostGroup.Text = "Host Operations"
    $hostGroup.Size = New-Object System.Drawing.Size(860, 200)
    $hostGroup.Location = New-Object System.Drawing.Point(10, 140)
    
    # Operation Selection
    $operationLabel = New-Object System.Windows.Forms.Label
    $operationLabel.Text = "Operation:"
    $operationLabel.Location = New-Object System.Drawing.Point(10, 25)
    $operationLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:OperationComboBox = New-Object System.Windows.Forms.ComboBox
    $script:OperationComboBox.Location = New-Object System.Drawing.Point(100, 23)
    $script:OperationComboBox.Size = New-Object System.Drawing.Size(150, 20)
    $script:OperationComboBox.DropDownStyle = "DropDownList"
    $script:OperationComboBox.Items.AddRange(@("Create Host", "List Hosts", "Delete Host"))
    $script:OperationComboBox.Add_SelectedIndexChanged({
        Update-HostOperationFields
    })
    
    # Host Details (for Create/Delete operations)
    $hostNameLabel = New-Object System.Windows.Forms.Label
    $hostNameLabel.Text = "Host Name:"
    $hostNameLabel.Location = New-Object System.Drawing.Point(10, 60)
    $hostNameLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:HostNameTextBox = New-Object System.Windows.Forms.TextBox
    $script:HostNameTextBox.Location = New-Object System.Drawing.Point(100, 58)
    $script:HostNameTextBox.Size = New-Object System.Drawing.Size(150, 20)
    $script:HostNameTextBox.Enabled = $false
    
    $hostIPLabel = New-Object System.Windows.Forms.Label
    $hostIPLabel.Text = "Host IP:"
    $hostIPLabel.Location = New-Object System.Drawing.Point(270, 60)
    $hostIPLabel.Size = New-Object System.Drawing.Size(60, 20)
    
    $script:HostIPTextBox = New-Object System.Windows.Forms.TextBox
    $script:HostIPTextBox.Location = New-Object System.Drawing.Point(340, 58)
    $script:HostIPTextBox.Size = New-Object System.Drawing.Size(120, 20)
    $script:HostIPTextBox.Enabled = $false
    
    $hostUsernameLabel = New-Object System.Windows.Forms.Label
    $hostUsernameLabel.Text = "Host User:"
    $hostUsernameLabel.Location = New-Object System.Drawing.Point(480, 60)
    $hostUsernameLabel.Size = New-Object System.Drawing.Size(70, 20)
    
    $script:HostUsernameTextBox = New-Object System.Windows.Forms.TextBox
    $script:HostUsernameTextBox.Location = New-Object System.Drawing.Point(560, 58)
    $script:HostUsernameTextBox.Size = New-Object System.Drawing.Size(100, 20)
    $script:HostUsernameTextBox.Text = "root"
    $script:HostUsernameTextBox.Enabled = $false
    
    $hostPasswordLabel = New-Object System.Windows.Forms.Label
    $hostPasswordLabel.Text = "Host Pass:"
    $hostPasswordLabel.Location = New-Object System.Drawing.Point(680, 60)
    $hostPasswordLabel.Size = New-Object System.Drawing.Size(70, 20)
    
    $script:HostPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:HostPasswordTextBox.Location = New-Object System.Drawing.Point(760, 58)
    $script:HostPasswordTextBox.Size = New-Object System.Drawing.Size(90, 20)
    $script:HostPasswordTextBox.UseSystemPasswordChar = $true
    $script:HostPasswordTextBox.Enabled = $false
    
    # Execute Button
    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Text = "Execute Operation"
    $executeButton.Location = New-Object System.Drawing.Point(10, 100)
    $executeButton.Size = New-Object System.Drawing.Size(120, 30)
    $executeButton.BackColor = [System.Drawing.Color]::LightBlue
    $executeButton.Add_Click({
        Execute-HostOperation
    })
    
    # Host List (for List/Delete operations)
    $hostListLabel = New-Object System.Windows.Forms.Label
    $hostListLabel.Text = "Available Hosts:"
    $hostListLabel.Location = New-Object System.Drawing.Point(150, 105)
    $hostListLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:HostListBox = New-Object System.Windows.Forms.ListBox
    $script:HostListBox.Location = New-Object System.Drawing.Point(150, 130)
    $script:HostListBox.Size = New-Object System.Drawing.Size(700, 60)
    $script:HostListBox.Enabled = $false
    
    $hostGroup.Controls.AddRange(@($operationLabel, $script:OperationComboBox, $hostNameLabel, $script:HostNameTextBox, $hostIPLabel, $script:HostIPTextBox, $hostUsernameLabel, $script:HostUsernameTextBox, $hostPasswordLabel, $script:HostPasswordTextBox, $executeButton, $hostListLabel, $script:HostListBox))
    
    # Operation Status Group
    $operationStatusGroup = New-Object System.Windows.Forms.GroupBox
    $operationStatusGroup.Text = "Operation Status"
    $operationStatusGroup.Size = New-Object System.Drawing.Size(860, 300)
    $operationStatusGroup.Location = New-Object System.Drawing.Point(10, 350)
    
    # Progress Bar
    $script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $script:ProgressBar.Location = New-Object System.Drawing.Point(10, 25)
    $script:ProgressBar.Size = New-Object System.Drawing.Size(840, 20)
    $script:ProgressBar.Style = "Continuous"
    
    # Status Label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Ready for operations"
    $statusLabel.Location = New-Object System.Drawing.Point(10, 55)
    $statusLabel.Size = New-Object System.Drawing.Size(200, 20)
    
    # Detailed Progress Window
    $statusWindowLabel = New-Object System.Windows.Forms.Label
    $statusWindowLabel.Text = "Detailed Status:"
    $statusWindowLabel.Location = New-Object System.Drawing.Point(10, 80)
    $statusWindowLabel.Size = New-Object System.Drawing.Size(120, 20)
    
    $script:OperationStatusTextBox = New-Object System.Windows.Forms.TextBox
    $script:OperationStatusTextBox.Location = New-Object System.Drawing.Point(10, 105)
    $script:OperationStatusTextBox.Size = New-Object System.Drawing.Size(840, 185)
    $script:OperationStatusTextBox.Multiline = $true
    $script:OperationStatusTextBox.ScrollBars = "Vertical"
    $script:OperationStatusTextBox.ReadOnly = $true
    $script:OperationStatusTextBox.BackColor = [System.Drawing.Color]::Black
    $script:OperationStatusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:OperationStatusTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    
    $operationStatusGroup.Controls.AddRange(@($script:ProgressBar, $statusLabel, $statusWindowLabel, $script:OperationStatusTextBox))
    
    $form.Controls.AddRange(@($vcenterGroup, $hostGroup, $operationStatusGroup))
    
    return $form
}

function Update-HostOperationFields {
    $operation = $script:OperationComboBox.SelectedItem
    
    switch ($operation) {
        "Create Host" {
            $script:HostNameTextBox.Enabled = $true
            $script:HostIPTextBox.Enabled = $true
            $script:HostUsernameTextBox.Enabled = $true
            $script:HostPasswordTextBox.Enabled = $true
            $script:HostListBox.Enabled = $false
            Write-Log "Selected operation: Create Host" "INFO"
        }
        "List Hosts" {
            $script:HostNameTextBox.Enabled = $false
            $script:HostIPTextBox.Enabled = $false
            $script:HostUsernameTextBox.Enabled = $false
            $script:HostPasswordTextBox.Enabled = $false
            $script:HostListBox.Enabled = $true
            Write-Log "Selected operation: List Hosts" "INFO"
        }
        "Delete Host" {
            $script:HostNameTextBox.Enabled = $false
            $script:HostIPTextBox.Enabled = $false
            $script:HostUsernameTextBox.Enabled = $false
            $script:HostPasswordTextBox.Enabled = $false
            $script:HostListBox.Enabled = $true
            Write-Log "Selected operation: Delete Host" "INFO"
        }
    }
}

function Test-VCenterConnection {
    try {
        if ([string]::IsNullOrWhiteSpace($script:VCenterTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:AdminUsernameTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:PasswordTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Please fill in all connection fields.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $script:ConnectionStatusLabel.Text = "Status: Connecting..."
        $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Orange
        Write-Log "Testing connection to $($script:VCenterTextBox.Text)..." "INFO"
        
        $connection = Connect-VIServer -Server $script:VCenterTextBox.Text -User $script:AdminUsernameTextBox.Text -Password $script:PasswordTextBox.Text -ErrorAction Stop
        
        if ($connection) {
            $script:ConnectionStatusLabel.Text = "Status: Connected to $($connection.Name)"
            $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Green
            Write-Log "Successfully connected to vCenter: $($connection.Name)" "SUCCESS"
            Write-Log "Version: $($connection.Version), Build: $($connection.Build)" "INFO"
        }
    } catch {
        $script:ConnectionStatusLabel.Text = "Status: Connection Failed"
        $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
        Write-Log "Connection failed: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Connection failed: $($_.Exception.Message)", "Connection Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Execute-HostOperation {
    $operation = $script:OperationComboBox.SelectedItem
    
    if (-not $operation) {
        [System.Windows.Forms.MessageBox]::Show("Please select an operation.", "No Operation Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    # Check vCenter connection
    if (-not $global:DefaultVIServers) {
        [System.Windows.Forms.MessageBox]::Show("Please connect to vCenter first.", "Not Connected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    switch ($operation) {
        "Create Host" { Execute-CreateHost }
        "List Hosts" { Execute-ListHosts }
        "Delete Host" { Execute-DeleteHost }
    }
}

function Execute-CreateHost {
    try {
        if ([string]::IsNullOrWhiteSpace($script:HostNameTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:HostIPTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:HostUsernameTextBox.Text) -or 
            [string]::IsNullOrWhiteSpace($script:HostPasswordTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Please fill in all host details.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $hostName = $script:HostNameTextBox.Text.Trim()
        $hostIP = $script:HostIPTextBox.Text.Trim()
        $hostUser = $script:HostUsernameTextBox.Text.Trim()
        $hostPass = $script:HostPasswordTextBox.Text
        
        Write-Log "Starting host creation operation..." "INFO"
        $script:ProgressBar.Value = 10
        
        Write-Log "Adding ESXi host: $hostName ($hostIP)" "INFO"
        $script:ProgressBar.Value = 30
        
        # Get the default datacenter or cluster
        $datacenter = Get-Datacenter | Select-Object -First 1
        if (-not $datacenter) {
            throw "No datacenter found in vCenter"
        }
        
        Write-Log "Using datacenter: $($datacenter.Name)" "INFO"
        $script:ProgressBar.Value = 50
        
        # Add the host
        $newHost = Add-VMHost -Name $hostIP -Location $datacenter -User $hostUser -Password $hostPass -Force -ErrorAction Stop
        
        $script:ProgressBar.Value = 80
        Write-Log "Host added successfully: $($newHost.Name)" "SUCCESS"
        Write-Log "Host state: $($newHost.ConnectionState)" "INFO"
        
        $script:ProgressBar.Value = 100
        Write-Log "Host creation operation completed successfully" "SUCCESS"
        
        [System.Windows.Forms.MessageBox]::Show("Host '$hostName' added successfully to vCenter.", "Host Created", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
    } catch {
        Write-Log "Host creation failed: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to create host: $($_.Exception.Message)", "Creation Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $script:ProgressBar.Value = 0
    }
}

function Execute-ListHosts {
    try {
        Write-Log "Retrieving host list from vCenter..." "INFO"
        $script:ProgressBar.Value = 20
        
        $hosts = Get-VMHost | Sort-Object Name
        
        $script:ProgressBar.Value = 60
        Write-Log "Found $($hosts.Count) hosts in vCenter" "INFO"
        
        $script:HostListBox.Items.Clear()
        
        foreach ($host in $hosts) {
            $hostInfo = "$($host.Name) - $($host.ConnectionState) - Version: $($host.Version)"
            $script:HostListBox.Items.Add($hostInfo)
            Write-Log "Host: $($host.Name) - State: $($host.ConnectionState)" "INFO"
        }
        
        $script:ProgressBar.Value = 100
        Write-Log "Host list operation completed successfully" "SUCCESS"
        
        if ($hosts.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No hosts found in vCenter.", "No Hosts", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        
    } catch {
        Write-Log "Host list operation failed: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to retrieve host list: $($_.Exception.Message)", "List Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $script:ProgressBar.Value = 0
    }
}

function Execute-DeleteHost {
    try {
        if ($script:HostListBox.SelectedItem -eq $null) {
            [System.Windows.Forms.MessageBox]::Show("Please select a host to delete.", "No Host Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $selectedHostInfo = $script:HostListBox.SelectedItem.ToString()
        $hostName = $selectedHostInfo.Split(' - ')[0]
        
        $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to remove host '$hostName' from vCenter?`n`nThis will disconnect the host from vCenter management.", "Confirm Host Removal", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        
        if ($result -eq [System.Windows.Forms.DialogResult]::No) {
            Write-Log "Host deletion cancelled by user" "INFO"
            return
        }
        
        Write-Log "Starting host deletion operation..." "INFO"
        $script:ProgressBar.Value = 10
        
        Write-Log "Removing ESXi host: $hostName" "INFO"
        $script:ProgressBar.Value = 30
        
        # Get the host object
        $host = Get-VMHost -Name $hostName -ErrorAction Stop
        
        $script:ProgressBar.Value = 50
        
        # Put host in maintenance mode first
        Write-Log "Putting host in maintenance mode..." "INFO"
        Set-VMHost -VMHost $host -State Maintenance -ErrorAction Stop
        
        $script:ProgressBar.Value = 70
        
        # Remove the host
        Remove-VMHost -VMHost $host -Confirm:$false -ErrorAction Stop
        
        $script:ProgressBar.Value = 90
        Write-Log "Host removed successfully: $hostName" "SUCCESS"
        
        # Refresh the host list
        Execute-ListHosts
        
        $script:ProgressBar.Value = 100
        Write-Log "Host deletion operation completed successfully" "SUCCESS"
        
        [System.Windows.Forms.MessageBox]::Show("Host '$hostName' removed successfully from vCenter.", "Host Deleted", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
    } catch {
        Write-Log "Host deletion failed: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to delete host: $($_.Exception.Message)", "Deletion Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $script:ProgressBar.Value = 0
    }
}

# Main execution
function Start-HostManager {
    Write-Log "Starting VMware vCenter Host Management Tool" "INFO"
    
    # Show DoD Warning
    Show-DoDWarning
    
    # Check PowerCLI availability
    if (-not (Test-PowerCLIAvailability)) {
        return
    }
    
    # Create and show the form
    $form = Create-MainForm
    
    # Initialize status
    Write-Log "Host Management Tool initialized successfully" "SUCCESS"
    Write-Log "Ready for vCenter connection and host operations" "INFO"
    
    # Show the form
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form.ShowDialog()
}

# Start the application with error handling
try {
    Start-HostManager
} catch {
    $errorMessage = "Critical error starting Host Manager: $($_.Exception.Message)"
    Write-Host $errorMessage -ForegroundColor Red
    
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Host Manager Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } catch {
        Write-Host "Could not display error dialog: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    exit 1
}