# VMware vCenter Password Management Tool - Configuration Manager
# Version 1.0 - Professional DoD-Compliant Edition
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Developed with assistance from Qodo AI
# Purpose: Manage hosts.txt and users.txt configuration files
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

# Import common functions
. "$PSScriptRoot\Common.ps1"

function Create-ConfigurationForm {
    $form = Create-StandardForm -Title "VMware Configuration Manager - Standalone" -Width 900 -Height 700
    
    # Hosts Configuration Group
    $hostsGroup = New-Object System.Windows.Forms.GroupBox
    $hostsGroup.Text = "ESXi Hosts Configuration"
    $hostsGroup.Size = New-Object System.Drawing.Size(860, 300)
    $hostsGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    $hostsLabel = New-Object System.Windows.Forms.Label
    $hostsLabel.Text = "ESXi Host Addresses (one per line):"
    $hostsLabel.Location = New-Object System.Drawing.Point(10, 20)
    $hostsLabel.Size = New-Object System.Drawing.Size(300, 20)
    
    $script:HostsTextBox = New-Object System.Windows.Forms.TextBox
    $script:HostsTextBox.Location = New-Object System.Drawing.Point(10, 45)
    $script:HostsTextBox.Size = New-Object System.Drawing.Size(840, 200)
    $script:HostsTextBox.Multiline = $true
    $script:HostsTextBox.ScrollBars = "Vertical"
    $script:HostsTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    $saveHostsButton = New-Object System.Windows.Forms.Button
    $saveHostsButton.Text = "Save Hosts"
    $saveHostsButton.Location = New-Object System.Drawing.Point(10, 260)
    $saveHostsButton.Size = New-Object System.Drawing.Size(100, 30)
    $saveHostsButton.BackColor = [System.Drawing.Color]::LightGreen
    $saveHostsButton.Add_Click({
        Save-HostsConfiguration
    })
    
    $loadHostsButton = New-Object System.Windows.Forms.Button
    $loadHostsButton.Text = "Load Hosts"
    $loadHostsButton.Location = New-Object System.Drawing.Point(120, 260)
    $loadHostsButton.Size = New-Object System.Drawing.Size(100, 30)
    $loadHostsButton.BackColor = [System.Drawing.Color]::LightBlue
    $loadHostsButton.Add_Click({
        Load-HostsConfiguration
    })
    
    $validateHostsButton = New-Object System.Windows.Forms.Button
    $validateHostsButton.Text = "Validate Hosts"
    $validateHostsButton.Location = New-Object System.Drawing.Point(230, 260)
    $validateHostsButton.Size = New-Object System.Drawing.Size(100, 30)
    $validateHostsButton.BackColor = [System.Drawing.Color]::LightYellow
    $validateHostsButton.Add_Click({
        Validate-HostsConfiguration
    })
    
    $hostsGroup.Controls.AddRange(@($hostsLabel, $script:HostsTextBox, $saveHostsButton, $loadHostsButton, $validateHostsButton))
    
    # Users Configuration
    $usersGroup = New-Object System.Windows.Forms.GroupBox
    $usersGroup.Text = "Target Users Configuration"
    $usersGroup.Size = New-Object System.Drawing.Size(860, 300)
    $usersGroup.Location = New-Object System.Drawing.Point(10, 320)
    
    $usersLabel = New-Object System.Windows.Forms.Label
    $usersLabel.Text = "Target Usernames (one per line):"
    $usersLabel.Location = New-Object System.Drawing.Point(10, 20)
    $usersLabel.Size = New-Object System.Drawing.Size(300, 20)
    
    $script:UsersTextBox = New-Object System.Windows.Forms.TextBox
    $script:UsersTextBox.Location = New-Object System.Drawing.Point(10, 45)
    $script:UsersTextBox.Size = New-Object System.Drawing.Size(840, 200)
    $script:UsersTextBox.Multiline = $true
    $script:UsersTextBox.ScrollBars = "Vertical"
    $script:UsersTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    $saveUsersButton = New-Object System.Windows.Forms.Button
    $saveUsersButton.Text = "Save Users"
    $saveUsersButton.Location = New-Object System.Drawing.Point(10, 260)
    $saveUsersButton.Size = New-Object System.Drawing.Size(100, 30)
    $saveUsersButton.BackColor = [System.Drawing.Color]::LightGreen
    $saveUsersButton.Add_Click({
        Save-UsersConfiguration
    })
    
    $loadUsersButton = New-Object System.Windows.Forms.Button
    $loadUsersButton.Text = "Load Users"
    $loadUsersButton.Location = New-Object System.Drawing.Point(120, 260)
    $loadUsersButton.Size = New-Object System.Drawing.Size(100, 30)
    $loadUsersButton.BackColor = [System.Drawing.Color]::LightBlue
    $loadUsersButton.Add_Click({
        Load-UsersConfiguration
    })
    
    $validateUsersButton = New-Object System.Windows.Forms.Button
    $validateUsersButton.Text = "Validate Users"
    $validateUsersButton.Location = New-Object System.Drawing.Point(230, 260)
    $validateUsersButton.Size = New-Object System.Drawing.Size(100, 30)
    $validateUsersButton.BackColor = [System.Drawing.Color]::LightYellow
    $validateUsersButton.Add_Click({
        Validate-UsersConfiguration
    })
    
    # Status label
    $script:ConfigStatusLabel = New-Object System.Windows.Forms.Label
    $script:ConfigStatusLabel.Text = "Ready - Load configuration files to begin editing"
    $script:ConfigStatusLabel.Location = New-Object System.Drawing.Point(350, 270)
    $script:ConfigStatusLabel.Size = New-Object System.Drawing.Size(500, 20)
    $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Blue
    
    $usersGroup.Controls.AddRange(@($usersLabel, $script:UsersTextBox, $saveUsersButton, $loadUsersButton, $validateUsersButton, $script:ConfigStatusLabel))
    
    $form.Controls.AddRange(@($hostsGroup, $usersGroup))
    
    return $form
}

function Save-HostsConfiguration {
    try {
        $script:HostsTextBox.Text | Set-Content -Path $script:HostsFilePath
        Write-Log "Hosts configuration saved" "SUCCESS"
        $script:ConfigStatusLabel.Text = "Hosts configuration saved successfully"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Green
        [System.Windows.Forms.MessageBox]::Show("Hosts configuration saved successfully.", "Configuration Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Write-Log "Failed to save hosts configuration: $($_.Exception.Message)" "ERROR"
        $script:ConfigStatusLabel.Text = "Failed to save hosts configuration"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Red
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
                $script:HostsTextBox.Text = ""
            }
            Write-Log "Hosts configuration loaded" "SUCCESS"
            $script:ConfigStatusLabel.Text = "Hosts configuration loaded successfully"
            $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Green
        } else {
            $script:HostsTextBox.Text = ""
            $script:ConfigStatusLabel.Text = "No hosts.txt file found - will be created on save"
            $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Orange
        }
    } catch {
        Write-Log "Failed to load hosts configuration: $($_.Exception.Message)" "ERROR"
        $script:ConfigStatusLabel.Text = "Failed to load hosts configuration"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("Failed to load hosts configuration: $($_.Exception.Message)", "Load Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Validate-HostsConfiguration {
    try {
        $hosts = $script:HostsTextBox.Text -split "`r`n|`r|`n" | Where-Object { 
            $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#')
        }
        
        if ($hosts.Count -eq 0) {
            $script:ConfigStatusLabel.Text = "No valid hosts found in configuration"
            $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Orange
            [System.Windows.Forms.MessageBox]::Show("No valid hosts found in configuration.", "Validation Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $validHosts = 0
        $invalidHosts = @()
        
        foreach ($host in $hosts) {
            $host = $host.Trim()
            # Basic validation - check if it looks like an IP or FQDN
            if ($host -match '^(\d{1,3}\.){3}\d{1,3}$' -or $host -match '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$') {
                $validHosts++
            } else {
                $invalidHosts += $host
            }
        }
        
        $message = "Validation Results:`n`nValid hosts: $validHosts`nTotal hosts: $($hosts.Count)"
        if ($invalidHosts.Count -gt 0) {
            $message += "`n`nPotentially invalid hosts:`n" + ($invalidHosts -join "`n")
        }
        
        $script:ConfigStatusLabel.Text = "Validation complete: $validHosts valid hosts found"
        $script:ConfigStatusLabel.ForeColor = if ($invalidHosts.Count -eq 0) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Orange }
        
        [System.Windows.Forms.MessageBox]::Show($message, "Host Validation Results", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        Write-Log "Host validation completed: $validHosts valid, $($invalidHosts.Count) potentially invalid" "INFO"
    } catch {
        Write-Log "Failed to validate hosts: $($_.Exception.Message)" "ERROR"
        $script:ConfigStatusLabel.Text = "Host validation failed"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Red
    }
}

function Save-UsersConfiguration {
    try {
        $script:UsersTextBox.Text | Set-Content -Path $script:UsersFilePath
        Write-Log "Users configuration saved" "SUCCESS"
        $script:ConfigStatusLabel.Text = "Users configuration saved successfully"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Green
        [System.Windows.Forms.MessageBox]::Show("Users configuration saved successfully.", "Configuration Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Write-Log "Failed to save users configuration: $($_.Exception.Message)" "ERROR"
        $script:ConfigStatusLabel.Text = "Failed to save users configuration"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Red
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
                $script:UsersTextBox.Text = "root"
            }
            Write-Log "Users configuration loaded" "SUCCESS"
            $script:ConfigStatusLabel.Text = "Users configuration loaded successfully"
            $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Green
        } else {
            $script:UsersTextBox.Text = "root"
            $script:ConfigStatusLabel.Text = "No users.txt file found - will be created on save"
            $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Orange
        }
    } catch {
        Write-Log "Failed to load users configuration: $($_.Exception.Message)" "ERROR"
        $script:ConfigStatusLabel.Text = "Failed to load users configuration"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("Failed to load users configuration: $($_.Exception.Message)", "Load Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Validate-UsersConfiguration {
    try {
        $users = $script:UsersTextBox.Text -split "`r`n|`r|`n" | Where-Object { 
            $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#')
        }
        
        if ($users.Count -eq 0) {
            $script:ConfigStatusLabel.Text = "No valid users found in configuration"
            $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Orange
            [System.Windows.Forms.MessageBox]::Show("No valid users found in configuration.", "Validation Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $validUsers = 0
        $suspiciousUsers = @()
        
        foreach ($user in $users) {
            $user = $user.Trim()
            # Basic validation - check for common patterns
            if ($user -match '^[a-zA-Z0-9_\-@\.]+$' -and $user.Length -le 64) {
                $validUsers++
            } else {
                $suspiciousUsers += $user
            }
        }
        
        $message = "Validation Results:`n`nValid users: $validUsers`nTotal users: $($users.Count)"
        if ($suspiciousUsers.Count -gt 0) {
            $message += "`n`nPotentially invalid users:`n" + ($suspiciousUsers -join "`n")
        }
        
        $script:ConfigStatusLabel.Text = "Validation complete: $validUsers valid users found"
        $script:ConfigStatusLabel.ForeColor = if ($suspiciousUsers.Count -eq 0) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Orange }
        
        [System.Windows.Forms.MessageBox]::Show($message, "User Validation Results", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        Write-Log "User validation completed: $validUsers valid, $($suspiciousUsers.Count) potentially invalid" "INFO"
    } catch {
        Write-Log "Failed to validate users: $($_.Exception.Message)" "ERROR"
        $script:ConfigStatusLabel.Text = "User validation failed"
        $script:ConfigStatusLabel.ForeColor = [System.Drawing.Color]::Red
    }
}

# Main execution
function Start-ConfigurationManager {
    Write-Log "Starting Configuration Manager - Standalone Mode" "INFO"
    
    # Show DoD Warning
    Show-DoDWarning
    
    # Create and show the form
    $form = Create-ConfigurationForm
    
    # Load initial configuration
    Load-HostsConfiguration
    Load-UsersConfiguration
    
    Write-Log "Configuration Manager initialized successfully" "SUCCESS"
    
    # Show the form
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form.ShowDialog()
}

# Start the configuration manager with error handling
try {
    Start-ConfigurationManager
} catch {
    $errorMessage = "Critical error starting Configuration Manager: $($_.Exception.Message)"
    Write-Host $errorMessage -ForegroundColor Red
    
    # Try to show error dialog if Windows Forms is available
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Configuration Manager Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } catch {
        Write-Host "Could not display error dialog: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    exit 1
}