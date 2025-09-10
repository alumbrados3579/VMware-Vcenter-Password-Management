# VMware vCenter Password Management Tool - CLI Workspace
# Version 0.5 BETA - Standalone PowerCLI Terminal
# Purpose: Interactive PowerCLI command workspace with vCenter connectivity

# Import common functions
. "$PSScriptRoot\Common.ps1"

# Global variables for CLI workspace
$script:CLICommandHistory = @()
$script:CLIHistoryIndex = -1

function Create-CLIWorkspaceForm {
    $form = Create-StandardForm -Title "VMware PowerCLI Workspace - Standalone" -Width 900 -Height 700
    
    # Connection Group
    $connectionGroup = New-Object System.Windows.Forms.GroupBox
    $connectionGroup.Text = "vCenter Connection"
    $connectionGroup.Size = New-Object System.Drawing.Size(860, 100)
    $connectionGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    # vCenter Server
    $vcenterLabel = New-Object System.Windows.Forms.Label
    $vcenterLabel.Text = "vCenter Server:"
    $vcenterLabel.Location = New-Object System.Drawing.Point(10, 25)
    $vcenterLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $script:CLIVCenterTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIVCenterTextBox.Location = New-Object System.Drawing.Point(110, 23)
    $script:CLIVCenterTextBox.Size = New-Object System.Drawing.Size(180, 20)
    
    # Username
    $usernameLabel = New-Object System.Windows.Forms.Label
    $usernameLabel.Text = "Username:"
    $usernameLabel.Location = New-Object System.Drawing.Point(300, 25)
    $usernameLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:CLIUsernameTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIUsernameTextBox.Location = New-Object System.Drawing.Point(390, 23)
    $script:CLIUsernameTextBox.Size = New-Object System.Drawing.Size(170, 20)
    $script:CLIUsernameTextBox.Text = "administrator@vsphere.local"
    
    # Password
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "Password:"
    $passwordLabel.Location = New-Object System.Drawing.Point(570, 25)
    $passwordLabel.Size = New-Object System.Drawing.Size(80, 20)
    
    $script:CLIPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIPasswordTextBox.Location = New-Object System.Drawing.Point(660, 23)
    $script:CLIPasswordTextBox.Size = New-Object System.Drawing.Size(170, 20)
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
    $cliGroup.Size = New-Object System.Drawing.Size(860, 520)
    $cliGroup.Location = New-Object System.Drawing.Point(10, 120)
    
    # Command input
    $commandLabel = New-Object System.Windows.Forms.Label
    $commandLabel.Text = "PowerCLI Command (Press Enter to execute, UP/DOWN for history):"
    $commandLabel.Location = New-Object System.Drawing.Point(10, 25)
    $commandLabel.Size = New-Object System.Drawing.Size(400, 20)
    
    $script:CLICommandTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLICommandTextBox.Location = New-Object System.Drawing.Point(10, 50)
    $script:CLICommandTextBox.Size = New-Object System.Drawing.Size(680, 20)
    $script:CLICommandTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $script:CLICommandTextBox.Add_KeyDown({
        Handle-CLIKeyPress $_
    })
    
    # Execute button
    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Text = "Execute"
    $executeButton.Location = New-Object System.Drawing.Point(700, 48)
    $executeButton.Size = New-Object System.Drawing.Size(70, 25)
    $executeButton.BackColor = [System.Drawing.Color]::LightBlue
    $executeButton.Add_Click({
        Execute-CLICommand
    })
    
    # Clear button
    $clearButton = New-Object System.Windows.Forms.Button
    $clearButton.Text = "Clear"
    $clearButton.Location = New-Object System.Drawing.Point(780, 48)
    $clearButton.Size = New-Object System.Drawing.Size(60, 25)
    $clearButton.Add_Click({
        $script:CLIOutputTextBox.Clear()
        Initialize-CLIWelcomeMessage
    })
    
    # Output area
    $outputLabel = New-Object System.Windows.Forms.Label
    $outputLabel.Text = "Command Output:"
    $outputLabel.Location = New-Object System.Drawing.Point(10, 85)
    $outputLabel.Size = New-Object System.Drawing.Size(120, 20)
    
    $script:CLIOutputTextBox = New-Object System.Windows.Forms.TextBox
    $script:CLIOutputTextBox.Location = New-Object System.Drawing.Point(10, 110)
    $script:CLIOutputTextBox.Size = New-Object System.Drawing.Size(840, 400)
    $script:CLIOutputTextBox.Multiline = $true
    $script:CLIOutputTextBox.ScrollBars = "Vertical"
    $script:CLIOutputTextBox.ReadOnly = $true
    $script:CLIOutputTextBox.BackColor = [System.Drawing.Color]::Black
    $script:CLIOutputTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:CLIOutputTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    # Initialize welcome message
    Initialize-CLIWelcomeMessage
    
    $cliGroup.Controls.AddRange(@($commandLabel, $script:CLICommandTextBox, $executeButton, $clearButton, $outputLabel, $script:CLIOutputTextBox))
    
    $form.Controls.AddRange(@($connectionGroup, $cliGroup))
    
    return $form
}

function Initialize-CLIWelcomeMessage {
    $script:CLIOutputTextBox.Text = "PowerCLI Command Workspace - Standalone Version 0.5 BETA`r`n"
    $script:CLIOutputTextBox.AppendText("Interactive Terminal Mode - Connect to vCenter above, then type commands below.`r`n`r`n")
    $script:CLIOutputTextBox.AppendText("Terminal Features:`r`n")
    $script:CLIOutputTextBox.AppendText("  - Press ENTER to execute commands`r`n")
    $script:CLIOutputTextBox.AppendText("  - Use UP/DOWN arrows for command history`r`n")
    $script:CLIOutputTextBox.AppendText("  - Type 'help' for PowerCLI help`r`n")
    $script:CLIOutputTextBox.AppendText("  - Type 'clear' to clear this window`r`n")
    $script:CLIOutputTextBox.AppendText("  - Type 'exit' to close this tool`r`n`r`n")
    $script:CLIOutputTextBox.AppendText("Example commands:`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-VMHost`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-VM | Select Name, PowerState`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-Datastore | Sort FreeSpaceGB`r`n")
    $script:CLIOutputTextBox.AppendText("  Get-Cluster`r`n`r`n")
    $script:CLIOutputTextBox.AppendText("Ready for commands...`r`n")
}

function Handle-CLIKeyPress {
    param($KeyEventArgs)
    
    if ($KeyEventArgs.KeyCode -eq "Enter") {
        Execute-CLICommand
    }
    if ($KeyEventArgs.KeyCode -eq "Up") {
        # Command history - previous command
        if ($script:CLICommandHistory -and $script:CLICommandHistory.Count -gt 0) {
            if ($script:CLIHistoryIndex -eq -1) {
                $script:CLIHistoryIndex = $script:CLICommandHistory.Count - 1
            } elseif ($script:CLIHistoryIndex -gt 0) {
                $script:CLIHistoryIndex--
            }
            $script:CLICommandTextBox.Text = $script:CLICommandHistory[$script:CLIHistoryIndex]
            $script:CLICommandTextBox.SelectionStart = $script:CLICommandTextBox.Text.Length
        }
    }
    if ($KeyEventArgs.KeyCode -eq "Down") {
        # Command history - next command
        if ($script:CLICommandHistory -and $script:CLICommandHistory.Count -gt 0) {
            if ($script:CLIHistoryIndex -lt ($script:CLICommandHistory.Count - 1)) {
                $script:CLIHistoryIndex++
                $script:CLICommandTextBox.Text = $script:CLICommandHistory[$script:CLIHistoryIndex]
            } else {
                $script:CLIHistoryIndex = -1
                $script:CLICommandTextBox.Text = ""
            }
            $script:CLICommandTextBox.SelectionStart = $script:CLICommandTextBox.Text.Length
        }
    }
}

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
        
        # Add to command history
        if ($script:CLICommandHistory -notcontains $command) {
            $script:CLICommandHistory += $command
            # Keep only last 50 commands
            if ($script:CLICommandHistory.Count -gt 50) {
                $script:CLICommandHistory = $script:CLICommandHistory[-50..-1]
            }
        }
        $script:CLIHistoryIndex = -1
        
        # Handle special commands
        if ($command -eq "clear") {
            $script:CLIOutputTextBox.Clear()
            Initialize-CLIWelcomeMessage
            $script:CLICommandTextBox.Clear()
            return
        }
        
        if ($command -eq "exit") {
            $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to exit the CLI Workspace?", "Exit Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                [System.Environment]::Exit(0)
            }
            $script:CLICommandTextBox.Clear()
            return
        }
        
        if ($command -eq "help") {
            $script:CLIOutputTextBox.AppendText("`r`n[$(Get-Date -Format 'HH:mm:ss')] PS> $command`r`n")
            $script:CLIOutputTextBox.AppendText("PowerCLI Command Workspace Help:`r`n")
            $script:CLIOutputTextBox.AppendText("  clear          - Clear the terminal window`r`n")
            $script:CLIOutputTextBox.AppendText("  help           - Show this help`r`n")
            $script:CLIOutputTextBox.AppendText("  exit           - Exit the CLI workspace`r`n")
            $script:CLIOutputTextBox.AppendText("  Get-Command    - List all available PowerCLI commands`r`n")
            $script:CLIOutputTextBox.AppendText("  Get-Help <cmd> - Get help for a specific command`r`n")
            $script:CLIOutputTextBox.AppendText("`r`nCommon PowerCLI commands:`r`n")
            $script:CLIOutputTextBox.AppendText("  Get-VMHost, Get-VM, Get-Datastore, Get-Cluster`r`n")
            $script:CLIOutputTextBox.AppendText("  Connect-VIServer, Disconnect-VIServer`r`n`r`n")
            $script:CLICommandTextBox.Clear()
            $script:CLIOutputTextBox.ScrollToCaret()
            return
        }
        
        # Check if connected for PowerCLI commands
        if (-not $global:DefaultVIServers -and $command -notlike "Get-Command*" -and $command -notlike "Get-Help*") {
            $script:CLIOutputTextBox.AppendText("`r`n[ERROR] Not connected to vCenter. Please connect first.`r`n")
            $script:CLIOutputTextBox.AppendText("Use the Connect button above or try: Connect-VIServer -Server <server>`r`n`r`n")
            $script:CLIOutputTextBox.ScrollToCaret()
            $script:CLICommandTextBox.Clear()
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
        
        # Clear command input and focus back to it
        $script:CLICommandTextBox.Clear()
        $script:CLICommandTextBox.Focus()
        
        Write-Log "CLI command executed: $command" "INFO"
    } catch {
        $script:CLIOutputTextBox.AppendText("[ERROR] Command execution error: $($_.Exception.Message)`r`n`r`n")
        $script:CLIOutputTextBox.ScrollToCaret()
        Write-Log "CLI command execution error: $($_.Exception.Message)" "ERROR"
    }
}

# Main execution
function Start-CLIWorkspace {
    Write-Log "Starting PowerCLI Workspace - Standalone Mode" "INFO"
    
    # Show DoD Warning
    Show-DoDWarning
    
    # Check PowerCLI availability
    if (-not (Test-PowerCLIAvailability)) {
        return
    }
    
    # Create and show the form
    $form = Create-CLIWorkspaceForm
    
    Write-Log "CLI Workspace initialized successfully" "SUCCESS"
    
    # Show the form
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form.ShowDialog()
}

# Start the CLI workspace with error handling
try {
    Start-CLIWorkspace
} catch {
    $errorMessage = "Critical error starting CLI Workspace: $($_.Exception.Message)"
    Write-Host $errorMessage -ForegroundColor Red
    
    # Try to show error dialog if Windows Forms is available
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "CLI Workspace Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } catch {
        Write-Host "Could not display error dialog: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    exit 1
}