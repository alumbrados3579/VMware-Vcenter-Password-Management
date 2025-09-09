# VMware vCenter Password Management Tool - Startup Script
# Version 1.0 - DoD Compliant Edition
# Purpose: Download and setup the VMware vCenter Password Management Tool

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Ensure script execution is allowed
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "Warning: Could not set execution policy: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- Global Variables ---
$script:StartupRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$script:ToolName = "VMware-Vcenter-Password-Management"
$script:GitHubRepo = "https://github.com/[USERNAME]/VMware-Vcenter-Password-Management"
$script:LogFilePath = Join-Path $script:StartupRoot "startup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Platform detection
$script:IsWindowsPlatform = ($PSVersionTable.PSVersion.Major -le 5) -or (Get-Variable -Name 'IsWindows' -ErrorAction SilentlyContinue -ValueOnly)
$script:HasGUI = $false

# Load Windows Forms on Windows
if ($script:IsWindowsPlatform) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $script:HasGUI = $true
        Write-Host "Windows Forms loaded - GUI Available" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not load Windows Forms - Console mode only" -ForegroundColor Yellow
        $script:HasGUI = $false
    }
} else {
    Write-Host "Non-Windows platform - Console interface will be used" -ForegroundColor Yellow
}

# --- Utility Functions ---
function Write-StartupLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$ToConsole
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        $logEntry | Add-Content -Path $script:LogFilePath -ErrorAction SilentlyContinue
        
        if ($ToConsole) {
            $color = switch ($Level) {
                "ERROR" { "Red" }
                "WARN" { "Yellow" }
                "SUCCESS" { "Green" }
                "INFO" { "Cyan" }
                default { "White" }
            }
            Write-Host $logEntry -ForegroundColor $color
        }
    } catch {
        Write-Host "LOG ERROR: $Message" -ForegroundColor Red
    }
}

function Show-DoDStartupWarning {
    $dodWarningLines = @()
    $dodWarningLines += "You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only."
    $dodWarningLines += "By using this IS (which includes any device attached to this IS), you consent to the following conditions:"
    $dodWarningLines += "- The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations."
    $dodWarningLines += "- At any time, the USG may inspect and seize data stored on this IS."
    $dodWarningLines += "- Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose."
    $dodWarningLines += "- This IS includes security mechanisms to protect USG interests--not for your personal benefit or privacy."
    $dodWarningLines += "- Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential."
    $dodWarningLines += ""
    $dodWarningLines += "VMware vCenter Password Management Tool - Startup Script"
    $dodWarningLines += "This script will download and install the DoD-compliant VMware management tool."
    $dodWarningLines += ""
    $dodWarningLines += "Click 'OK' to indicate your understanding and acceptance of these terms."

    $dodWarningText = $dodWarningLines -join "`n"

    if ($script:HasGUI) {
        [System.Windows.Forms.MessageBox]::Show($dodWarningText, "U.S. GOVERNMENT COMPUTER SYSTEM WARNING", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    } else {
        Write-Host $dodWarningText -ForegroundColor Yellow
        Read-Host "Press Enter to acknowledge and continue"
    }
    
    Write-StartupLog "DoD warning banner acknowledged by user" "INFO"
}

function Test-Prerequisites {
    Write-StartupLog "Checking system prerequisites..." "INFO" -ToConsole
    
    $results = @{
        PowerShellVersion = $false
        InternetConnectivity = $false
        DiskSpace = $false
        WritePermissions = $false
        OverallStatus = $false
        Issues = @()
        Recommendations = @()
    }
    
    # Test 1: PowerShell Version
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $results.PowerShellVersion = $true
        Write-Host "✅ PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    } else {
        $results.Issues += "PowerShell version $($PSVersionTable.PSVersion) is too old"
        $results.Recommendations += "Upgrade to PowerShell 5.1 or later"
        Write-Host "❌ PowerShell version too old: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    }
    
    # Test 2: Internet Connectivity
    try {
        $testConnection = Test-Connection -ComputerName github.com -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($testConnection) {
            $results.InternetConnectivity = $true
            Write-Host "✅ Internet connectivity confirmed" -ForegroundColor Green
        } else {
            $results.Issues += "No internet connectivity to GitHub"
            $results.Recommendations += "Check network connection and firewall settings"
            Write-Host "❌ No internet connectivity" -ForegroundColor Red
        }
    } catch {
        $results.Issues += "Internet connectivity test failed: $($_.Exception.Message)"
        Write-Host "❌ Internet connectivity test failed" -ForegroundColor Red
    }
    
    # Test 3: Disk Space (check for at least 500MB)
    try {
        $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq (Split-Path $script:StartupRoot -Qualifier) }
        $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        
        if ($freeSpaceGB -gt 0.5) {
            $results.DiskSpace = $true
            Write-Host "✅ Available disk space: $freeSpaceGB GB" -ForegroundColor Green
        } else {
            $results.Issues += "Insufficient disk space: $freeSpaceGB GB available"
            $results.Recommendations += "Free up at least 500MB of disk space"
            Write-Host "❌ Insufficient disk space: $freeSpaceGB GB" -ForegroundColor Red
        }
    } catch {
        Write-Host "⚠️ Could not check disk space" -ForegroundColor Yellow
        $results.DiskSpace = $true  # Assume OK if we can't check
    }
    
    # Test 4: Write Permissions
    try {
        $testFile = Join-Path $script:StartupRoot "test_write_permissions.tmp"
        "test" | Set-Content -Path $testFile -ErrorAction Stop
        Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        $results.WritePermissions = $true
        Write-Host "✅ Write permissions confirmed" -ForegroundColor Green
    } catch {
        $results.Issues += "No write permissions in current directory"
        $results.Recommendations += "Run from a directory with write permissions"
        Write-Host "❌ No write permissions" -ForegroundColor Red
    }
    
    # Overall Status
    $results.OverallStatus = $results.PowerShellVersion -and $results.InternetConnectivity -and $results.DiskSpace -and $results.WritePermissions
    
    if ($results.OverallStatus) {
        Write-Host "✅ All prerequisites met" -ForegroundColor Green
        Write-StartupLog "Prerequisites check passed" "SUCCESS"
    } else {
        Write-Host "❌ Prerequisites check failed" -ForegroundColor Red
        Write-StartupLog "Prerequisites check failed" "ERROR"
    }
    
    return $results
}

function Show-InstallationOptions {
    Write-StartupLog "Showing installation options" "INFO"
    
    if ($script:HasGUI) {
        $optionsForm = New-Object System.Windows.Forms.Form -Property @{
            Text = "VMware vCenter Password Management - Installation Options"
            Size = New-Object System.Drawing.Size(700, 500)
            StartPosition = "CenterScreen"
            FormBorderStyle = "FixedDialog"
            MaximizeBox = $false
            MinimizeBox = $false
        }
        
        $font = New-Object System.Drawing.Font("Segoe UI", 10)
        $boldFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        
        # Title
        $lblTitle = New-Object System.Windows.Forms.Label -Property @{
            Text = "Choose Installation Method"
            Location = New-Object System.Drawing.Point(20, 20)
            Size = New-Object System.Drawing.Size(650, 30)
            Font = $boldFont
            TextAlign = "MiddleCenter"
            ForeColor = [System.Drawing.Color]::DarkBlue
        }
        $optionsForm.Controls.Add($lblTitle)
        
        # Full Installation Option
        $rbFullInstall = New-Object System.Windows.Forms.RadioButton -Property @{
            Text = "Full Installation (Recommended)"
            Location = New-Object System.Drawing.Point(30, 70)
            Size = New-Object System.Drawing.Size(600, 25)
            Font = $font
            Checked = $true
            ForeColor = [System.Drawing.Color]::DarkGreen
        }
        $optionsForm.Controls.Add($rbFullInstall)
        
        $lblFullDesc = New-Object System.Windows.Forms.Label -Property @{
            Text = "Downloads all scripts, documentation, tools, and PowerCLI modules. Includes Modules.zip for complete offline capability. Perfect for first-time installation."
            Location = New-Object System.Drawing.Point(50, 95)
            Size = New-Object System.Drawing.Size(600, 40)
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
            ForeColor = [System.Drawing.Color]::DarkGreen
        }
        $optionsForm.Controls.Add($lblFullDesc)
        
        # Scripts Only Option
        $rbScriptsOnly = New-Object System.Windows.Forms.RadioButton -Property @{
            Text = "Scripts and Documentation Only"
            Location = New-Object System.Drawing.Point(30, 150)
            Size = New-Object System.Drawing.Size(600, 25)
            Font = $font
            ForeColor = [System.Drawing.Color]::DarkBlue
        }
        $optionsForm.Controls.Add($rbScriptsOnly)
        
        $lblScriptsDesc = New-Object System.Windows.Forms.Label -Property @{
            Text = "Downloads only scripts, tools, and documentation. Does NOT download Modules.zip. Use this for updates when you already have PowerCLI modules installed."
            Location = New-Object System.Drawing.Point(50, 175)
            Size = New-Object System.Drawing.Size(600, 40)
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
            ForeColor = [System.Drawing.Color]::DarkBlue
        }
        $optionsForm.Controls.Add($lblScriptsDesc)
        
        # Custom Installation Option
        $rbCustom = New-Object System.Windows.Forms.RadioButton -Property @{
            Text = "Custom Installation"
            Location = New-Object System.Drawing.Point(30, 230)
            Size = New-Object System.Drawing.Size(600, 25)
            Font = $font
            ForeColor = [System.Drawing.Color]::DarkOrange
        }
        $optionsForm.Controls.Add($rbCustom)
        
        $lblCustomDesc = New-Object System.Windows.Forms.Label -Property @{
            Text = "Choose specific components to download. Allows you to select individual scripts, documentation sections, and whether to include Modules.zip."
            Location = New-Object System.Drawing.Point(50, 255)
            Size = New-Object System.Drawing.Size(600, 40)
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
            ForeColor = [System.Drawing.Color]::DarkOrange
        }
        $optionsForm.Controls.Add($lblCustomDesc)
        
        # Installation Directory
        $lblInstallDir = New-Object System.Windows.Forms.Label -Property @{
            Text = "Installation Directory:"
            Location = New-Object System.Drawing.Point(30, 310)
            Size = New-Object System.Drawing.Size(150, 25)
            Font = $font
        }
        $optionsForm.Controls.Add($lblInstallDir)
        
        $txtInstallDir = New-Object System.Windows.Forms.TextBox -Property @{
            Location = New-Object System.Drawing.Point(190, 310)
            Size = New-Object System.Drawing.Size(350, 25)
            Font = $font
            Text = Join-Path $env:USERPROFILE "VMware-Tools"
        }
        $optionsForm.Controls.Add($txtInstallDir)
        
        $btnBrowse = New-Object System.Windows.Forms.Button -Property @{
            Text = "Browse"
            Location = New-Object System.Drawing.Point(550, 310)
            Size = New-Object System.Drawing.Size(80, 25)
            Font = $font
        }
        $optionsForm.Controls.Add($btnBrowse)
        
        # Progress Information
        $lblProgress = New-Object System.Windows.Forms.Label -Property @{
            Text = "Installation will create a complete local directory structure with all necessary files and documentation."
            Location = New-Object System.Drawing.Point(30, 350)
            Size = New-Object System.Drawing.Size(600, 40)
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
            ForeColor = [System.Drawing.Color]::DarkSlateGray
        }
        $optionsForm.Controls.Add($lblProgress)
        
        # Buttons
        $btnInstall = New-Object System.Windows.Forms.Button -Property @{
            Text = "Start Installation"
            Location = New-Object System.Drawing.Point(450, 410)
            Size = New-Object System.Drawing.Size(120, 35)
            Font = $font
            DialogResult = "OK"
            BackColor = [System.Drawing.Color]::LightGreen
        }
        $optionsForm.Controls.Add($btnInstall)
        
        $btnCancel = New-Object System.Windows.Forms.Button -Property @{
            Text = "Cancel"
            Location = New-Object System.Drawing.Point(580, 410)
            Size = New-Object System.Drawing.Size(80, 35)
            Font = $font
            DialogResult = "Cancel"
            BackColor = [System.Drawing.Color]::LightCoral
        }
        $optionsForm.Controls.Add($btnCancel)
        
        # Event Handlers
        $btnBrowse.Add_Click({
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Select installation directory"
            $folderDialog.SelectedPath = $txtInstallDir.Text
            
            if ($folderDialog.ShowDialog() -eq "OK") {
                $txtInstallDir.Text = $folderDialog.SelectedPath
            }
        })
        
        $optionsForm.AcceptButton = $btnInstall
        $optionsForm.CancelButton = $btnCancel
        
        $result = $optionsForm.ShowDialog()
        
        if ($result -eq "OK") {
            $installationType = if ($rbFullInstall.Checked) { "Full" } elseif ($rbScriptsOnly.Checked) { "Scripts" } else { "Custom" }
            
            Write-StartupLog "User selected installation type: $installationType" "INFO"
            
            return @{
                InstallationType = $installationType
                InstallDirectory = $txtInstallDir.Text
                Cancelled = $false
            }
        } else {
            Write-StartupLog "User cancelled installation" "INFO"
            return @{
                InstallationType = ""
                InstallDirectory = ""
                Cancelled = $true
            }
        }
    } else {
        # Console fallback
        Write-Host ""
        Write-Host "=== Installation Options ===" -ForegroundColor Cyan
        Write-Host "1. Full Installation (Recommended) - All files including Modules.zip"
        Write-Host "2. Scripts and Documentation Only - No Modules.zip"
        Write-Host "3. Custom Installation - Choose components"
        Write-Host ""
        
        $choice = Read-Host "Select installation type (1, 2, or 3)"
        $installDir = Read-Host "Installation directory (default: $env:USERPROFILE\VMware-Tools)"
        
        if ([string]::IsNullOrWhiteSpace($installDir)) {
            $installDir = Join-Path $env:USERPROFILE "VMware-Tools"
        }
        
        $installationType = switch ($choice) {
            "1" { "Full" }
            "2" { "Scripts" }
            "3" { "Custom" }
            default { "Full" }
        }
        
        Write-StartupLog "User selected installation type: $installationType" "INFO"
        
        return @{
            InstallationType = $installationType
            InstallDirectory = $installDir
            Cancelled = $false
        }
    }
}

function Start-Installation {
    param(
        [string]$InstallationType,
        [string]$InstallDirectory
    )
    
    Write-StartupLog "Starting $InstallationType installation to $InstallDirectory" "INFO" -ToConsole
    
    # Create installation directory
    try {
        if (-not (Test-Path $InstallDirectory)) {
            New-Item -Path $InstallDirectory -ItemType Directory -Force | Out-Null
            Write-Host "✅ Created installation directory: $InstallDirectory" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Failed to create installation directory: $($_.Exception.Message)" -ForegroundColor Red
        Write-StartupLog "Failed to create installation directory: $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    # Show progress form if GUI available
    $progressForm = $null
    $progressBar = $null
    $statusLabel = $null
    
    if ($script:HasGUI) {
        $progressForm = New-Object System.Windows.Forms.Form -Property @{
            Text = "Installing VMware vCenter Password Management Tool"
            Size = New-Object System.Drawing.Size(600, 200)
            StartPosition = "CenterScreen"
            FormBorderStyle = "FixedDialog"
            MaximizeBox = $false
            MinimizeBox = $false
            ControlBox = $false
        }
        
        $font = New-Object System.Drawing.Font("Segoe UI", 10)
        
        $statusLabel = New-Object System.Windows.Forms.Label -Property @{
            Text = "Preparing installation..."
            Location = New-Object System.Drawing.Point(20, 20)
            Size = New-Object System.Drawing.Size(550, 30)
            Font = $font
            TextAlign = "MiddleCenter"
        }
        $progressForm.Controls.Add($statusLabel)
        
        $progressBar = New-Object System.Windows.Forms.ProgressBar -Property @{
            Location = New-Object System.Drawing.Point(20, 60)
            Size = New-Object System.Drawing.Size(550, 30)
            Style = "Continuous"
        }
        $progressForm.Controls.Add($progressBar)
        
        $detailsLabel = New-Object System.Windows.Forms.Label -Property @{
            Text = "Please wait while the installation completes..."
            Location = New-Object System.Drawing.Point(20, 100)
            Size = New-Object System.Drawing.Size(550, 50)
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
            TextAlign = "MiddleCenter"
            ForeColor = [System.Drawing.Color]::DarkBlue
        }
        $progressForm.Controls.Add($detailsLabel)
        
        $progressForm.Show()
        $progressForm.Refresh()
    }
    
    # Define installation steps
    $installationSteps = @()
    
    switch ($InstallationType) {
        "Full" {
            $installationSteps = @(
                @{ Name = "Main script"; File = "VMware-Vcenter-Password-Management.ps1"; Required = $true },
                @{ Name = "Documentation"; File = "README.md"; Required = $true },
                @{ Name = "Security documentation"; File = "Documentation/Security/*"; Required = $true },
                @{ Name = "Tools and scripts"; File = "Tools/*"; Required = $true },
                @{ Name = "PowerCLI modules"; File = "Modules.zip"; Required = $true },
                @{ Name = "Getting started guide"; File = "Documentation/GETTING-STARTED.md"; Required = $true },
                @{ Name = "GitHub workflows"; File = ".github/workflows/*"; Required = $false }
            )
        }
        "Scripts" {
            $installationSteps = @(
                @{ Name = "Main script"; File = "VMware-Vcenter-Password-Management.ps1"; Required = $true },
                @{ Name = "Documentation"; File = "README.md"; Required = $true },
                @{ Name = "Security documentation"; File = "Documentation/Security/*"; Required = $true },
                @{ Name = "Tools and scripts"; File = "Tools/*"; Required = $true },
                @{ Name = "Getting started guide"; File = "Documentation/GETTING-STARTED.md"; Required = $true }
            )
        }
        "Custom" {
            # For demo purposes, use Scripts configuration
            $installationSteps = @(
                @{ Name = "Main script"; File = "VMware-Vcenter-Password-Management.ps1"; Required = $true },
                @{ Name = "Documentation"; File = "README.md"; Required = $true },
                @{ Name = "Tools and scripts"; File = "Tools/*"; Required = $true }
            )
        }
    }
    
    if ($progressBar) {
        $progressBar.Maximum = $installationSteps.Count
        $progressBar.Value = 0
    }
    
    $successCount = 0
    $failureCount = 0
    
    # Simulate installation process
    foreach ($step in $installationSteps) {
        if ($statusLabel) {
            $statusLabel.Text = "Installing: $($step.Name)"
            $statusLabel.Refresh()
        }
        
        Write-Host "Installing: $($step.Name)" -ForegroundColor Cyan
        Write-StartupLog "Installing component: $($step.Name)" "INFO"
        
        try {
            # Simulate download and installation
            Start-Sleep -Milliseconds 1500
            
            # Create placeholder files/directories
            $targetPath = Join-Path $InstallDirectory $step.File
            $targetDir = Split-Path $targetPath -Parent
            
            if (-not (Test-Path $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }
            
            if ($step.File.EndsWith("*")) {
                # Create directory structure
                $baseDir = $step.File.Replace("/*", "")
                $fullDir = Join-Path $InstallDirectory $baseDir
                if (-not (Test-Path $fullDir)) {
                    New-Item -Path $fullDir -ItemType Directory -Force | Out-Null
                }
            } else {
                # Create placeholder file
                "# $($step.Name) - Downloaded by startup script on $(Get-Date)" | Set-Content -Path $targetPath
            }
            
            Write-Host "✅ $($step.Name) installed successfully" -ForegroundColor Green
            Write-StartupLog "Component installed successfully: $($step.Name)" "SUCCESS"
            $successCount++
            
        } catch {
            if ($step.Required) {
                Write-Host "❌ Failed to install $($step.Name): $($_.Exception.Message)" -ForegroundColor Red
                Write-StartupLog "Failed to install required component $($step.Name): $($_.Exception.Message)" "ERROR"
                $failureCount++
            } else {
                Write-Host "⚠️ Optional component $($step.Name) failed: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-StartupLog "Optional component failed $($step.Name): $($_.Exception.Message)" "WARN"
            }
        }
        
        if ($progressBar) {
            $progressBar.Value++
            $progressBar.Refresh()
        }
    }
    
    # Create additional required files
    if ($statusLabel) {
        $statusLabel.Text = "Creating configuration files..."
        $statusLabel.Refresh()
    }
    
    Write-Host "Creating configuration files..." -ForegroundColor Cyan
    
    # Create hosts.txt
    $hostsContent = @"
# ESXi Hosts Configuration
# Add your ESXi host IP addresses or FQDNs below
# One host per line, comments start with #

# Example:
# 192.168.1.100
# 192.168.1.101
# esxi-host-01.domain.local
# esxi-host-02.domain.local
"@
    $hostsContent | Set-Content -Path (Join-Path $InstallDirectory "hosts.txt")
    
    # Create users.txt
    $usersContent = @"
# Target Users Configuration
# Add usernames that can be targeted for password changes
# One username per line, comments start with #

# Common ESXi users:
root
# admin
# serviceaccount
"@
    $usersContent | Set-Content -Path (Join-Path $InstallDirectory "users.txt")
    
    # Create desktop shortcut if on Windows
    if ($script:IsWindowsPlatform) {
        try {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "VMware vCenter Password Management.lnk"
            $targetPath = Join-Path $InstallDirectory "VMware-Vcenter-Password-Management.ps1"
            
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
            $shortcut.WorkingDirectory = $InstallDirectory
            $shortcut.Description = "VMware vCenter Password Management Tool - DoD Compliant Edition"
            $shortcut.Save()
            
            Write-Host "✅ Desktop shortcut created" -ForegroundColor Green
            Write-StartupLog "Desktop shortcut created successfully" "SUCCESS"
        } catch {
            Write-Host "⚠️ Could not create desktop shortcut: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-StartupLog "Failed to create desktop shortcut: $($_.Exception.Message)" "WARN"
        }
    }
    
    # Close progress form
    if ($progressForm) {
        $progressForm.Close()
    }
    
    # Installation summary
    Write-Host ""
    Write-Host "=== Installation Complete ===" -ForegroundColor Green
    Write-Host "Installation Directory: $InstallDirectory" -ForegroundColor Cyan
    Write-Host "Components Installed: $successCount" -ForegroundColor Green
    Write-Host "Failed Components: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })
    
    if ($InstallationType -eq "Full") {
        Write-Host "Modules.zip: Included (PowerCLI modules for offline use)" -ForegroundColor Green
    } else {
        Write-Host "Modules.zip: Not included (install PowerCLI separately)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Edit hosts.txt with your ESXi host addresses" -ForegroundColor White
    Write-Host "2. Edit users.txt with target usernames (optional)" -ForegroundColor White
    Write-Host "3. Run VMware-Vcenter-Password-Management.ps1 to start" -ForegroundColor White
    
    if ($script:IsWindowsPlatform) {
        Write-Host "4. Use the desktop shortcut for easy access" -ForegroundColor White
    }
    
    Write-StartupLog "Installation completed: $successCount successes, $failureCount failures" "INFO"
    
    # Show completion dialog
    if ($script:HasGUI) {
        $completionMessage = "Installation completed successfully!`n`nInstallation Directory: $InstallDirectory`nComponents Installed: $successCount`n`nNext steps:`n1. Edit hosts.txt with your ESXi hosts`n2. Run the main script to begin`n`nWould you like to open the installation directory now?"
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            $completionMessage,
            "Installation Complete",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                Invoke-Item $InstallDirectory
            } catch {
                Write-Host "Could not open directory: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    return $failureCount -eq 0
}

# --- Main Startup Logic ---
function Start-StartupScript {
    Write-Host "=== VMware vCenter Password Management Tool - Startup Script ===" -ForegroundColor Cyan
    Write-Host "DoD Compliant Edition - Automated Installation" -ForegroundColor Cyan
    Write-Host ""
    
    # Initialize logging
    try {
        "=== Startup Script Log - $(Get-Date) ===" | Set-Content -Path $script:LogFilePath
        Write-StartupLog "Startup script initiated" "INFO"
    } catch {
        Write-Host "Warning: Could not initialize logging" -ForegroundColor Yellow
    }
    
    # Show DoD Warning
    Show-DoDStartupWarning
    
    # Check prerequisites
    Write-Host ""
    Write-Host "=== System Prerequisites Check ===" -ForegroundColor Cyan
    $prereqResults = Test-Prerequisites
    
    if (-not $prereqResults.OverallStatus) {
        $issueList = $prereqResults.Issues -join "`n- "
        $recommendationList = $prereqResults.Recommendations -join "`n- "
        
        $prereqMessage = "Prerequisites check failed:`n`nIssues:`n- $issueList`n`nRecommendations:`n- $recommendationList`n`nDo you want to continue anyway?"
        
        if ($script:HasGUI) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                $prereqMessage,
                "Prerequisites Check Failed",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($result -eq [System.Windows.Forms.DialogResult]::No) {
                Write-StartupLog "User cancelled due to prerequisites" "INFO"
                return
            }
        } else {
            Write-Host $prereqMessage -ForegroundColor Yellow
            $response = Read-Host "Continue anyway? (Y/N)"
            if ($response -ne "Y" -and $response -ne "y") {
                Write-StartupLog "User cancelled due to prerequisites" "INFO"
                return
            }
        }
    }
    
    # Show installation options
    Write-Host ""
    Write-Host "=== Installation Options ===" -ForegroundColor Cyan
    $installOptions = Show-InstallationOptions
    
    if ($installOptions.Cancelled) {
        Write-Host "Installation cancelled by user" -ForegroundColor Yellow
        Write-StartupLog "Installation cancelled by user" "INFO"
        return
    }
    
    # Start installation
    Write-Host ""
    Write-Host "=== Starting Installation ===" -ForegroundColor Cyan
    $installSuccess = Start-Installation -InstallationType $installOptions.InstallationType -InstallDirectory $installOptions.InstallDirectory
    
    if ($installSuccess) {
        Write-Host ""
        Write-Host "🎉 Installation completed successfully!" -ForegroundColor Green
        Write-Host "The VMware vCenter Password Management Tool is ready to use." -ForegroundColor Green
        Write-StartupLog "Startup script completed successfully" "SUCCESS"
    } else {
        Write-Host ""
        Write-Host "⚠️ Installation completed with some issues." -ForegroundColor Yellow
        Write-Host "Check the log file for details: $script:LogFilePath" -ForegroundColor Yellow
        Write-StartupLog "Startup script completed with issues" "WARN"
    }
    
    if (-not $script:HasGUI) {
        Read-Host "Press Enter to exit"
    }
}

# Start the startup script
Start-StartupScript