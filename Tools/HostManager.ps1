# VMware vCenter Host Management Tool - Host Manager
# Version 1.0 - Professional DoD-Compliant Edition
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Developed with assistance from Qodo AI
# Purpose: Standalone host management for VMware vCenter environments
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

# Import common functions
. "$PSScriptRoot\Common.ps1"

# Global variables for host manager
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

function Create-HostManagerForm {
    $form = Create-StandardForm -Title "VMware Host Manager - Standalone" -Width 900 -Height 700
    
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
    
    # Connect/Disconnect buttons
    $connectButton = New-Object System.Windows.Forms.Button
    $connectButton.Text = "Connect"
    $connectButton.Location = New-Object System.Drawing.Point(10, 60)
    $connectButton.Size = New-Object System.Drawing.Size(80, 30)
    $connectButton.BackColor = [System.Drawing.Color]::LightGreen
    $connectButton.Add_Click({
        Test-VCenterConnection
    })
    
    $disconnectButton = New-Object System.Windows.Forms.Button
    $disconnectButton.Text = "Disconnect"
    $disconnectButton.Location = New-Object System.Drawing.Point(100, 60)
    $disconnectButton.Size = New-Object System.Drawing.Size(80, 30)
    $disconnectButton.BackColor = [System.Drawing.Color]::LightCoral
    $disconnectButton.Add_Click({
        Disconnect-VCenterConnection
    })
    
    # Connection status
    $script:ConnectionStatusLabel = New-Object System.Windows.Forms.Label
    $script:ConnectionStatusLabel.Text = "Status: Not Connected"
    $script:ConnectionStatusLabel.Location = New-Object System.Drawing.Point(200, 65)
    $script:ConnectionStatusLabel.Size = New-Object System.Drawing.Size(300, 20)
    $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
    
    $vcenterGroup.Controls.AddRange(@($vcenterLabel, $script:VCenterTextBox, $usernameLabel, $script:AdminUsernameTextBox, $passwordLabel, $script:PasswordTextBox, $connectButton, $disconnectButton, $script:ConnectionStatusLabel))
    
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

function Disconnect-VCenterConnection {
    try {
        $connections = $global:DefaultVIServers
        if ($connections) {
            foreach ($connection in $connections) {
                Disconnect-VIServer -Server $connection -Confirm:$false -ErrorAction SilentlyContinue
            }
            $script:ConnectionStatusLabel.Text = "Status: Disconnected"
            $script:ConnectionStatusLabel.ForeColor = [System.Drawing.Color]::Red
            Write-Log "Disconnected from vCenter" "INFO"
        } else {
            Write-Log "No active connections to disconnect" "INFO"
        }
    } catch {
        Write-Log "Error disconnecting: $($_.Exception.Message)" "ERROR"
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
    Write-Log "Starting Host Manager - Standalone Mode" "INFO"
    
    # Show DoD Warning
    Show-DoDWarning
    
    # Check PowerCLI availability
    if (-not (Test-PowerCLIAvailability)) {
        return
    }
    
    # Create and show the form
    $form = Create-HostManagerForm
    
    Write-Log "Host Manager initialized successfully" "SUCCESS"
    
    # Show the form
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form.ShowDialog()
}

# Start the host manager with error handling
try {
    Start-HostManager
} catch {
    $errorMessage = "Critical error starting Host Manager: $($_.Exception.Message)"
    Write-Host $errorMessage -ForegroundColor Red
    
    # Try to show error dialog if Windows Forms is available
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Host Manager Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } catch {
        Write-Host "Could not display error dialog: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    exit 1
}