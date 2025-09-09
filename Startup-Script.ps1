# VMware vCenter Password Management Tool - Startup Script
# Version 1.1 - DoD Compliant Edition
# Purpose: Download and setup the VMware vCenter Password Management Tool from GitHub

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
$script:GitHubRepo = "https://github.com/alumbrados3579/VMware-Vcenter-Password-Management"
$script:GitHubRawUrl = "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main"
$script:LogsPath = Join-Path $script:StartupRoot "Logs"
$script:LogFilePath = Join-Path $script:LogsPath "startup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Ensure Logs directory exists
if (-not (Test-Path $script:LogsPath)) {
    New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
}

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
    $dodWarningLines += "This script will download the DoD-compliant VMware management tool from GitHub."
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

function Show-DownloadOptions {
    Write-StartupLog "Showing download options" "INFO"
    
    if ($script:HasGUI) {
        $optionsForm = New-Object System.Windows.Forms.Form -Property @{
            Text = "VMware vCenter Password Management - Download Options"
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
            Text = "Choose Download Method"
            Location = New-Object System.Drawing.Point(20, 20)
            Size = New-Object System.Drawing.Size(650, 30)
            Font = $boldFont
            TextAlign = "MiddleCenter"
            ForeColor = [System.Drawing.Color]::DarkBlue
        }
        $optionsForm.Controls.Add($lblTitle)
        
        # Full Download Option
        $rbFullDownload = New-Object System.Windows.Forms.RadioButton -Property @{
            Text = "Full Download (Recommended)"
            Location = New-Object System.Drawing.Point(30, 70)
            Size = New-Object System.Drawing.Size(600, 25)
            Font = $font
            Checked = $true
            ForeColor = [System.Drawing.Color]::DarkGreen
        }
        $optionsForm.Controls.Add($rbFullDownload)
        
        $lblFullDesc = New-Object System.Windows.Forms.Label -Property @{
            Text = "Downloads all scripts, documentation, tools, and PowerCLI modules. Includes split PowerCLI-Modules.zip files for complete offline capability. Perfect for first-time setup."
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
            Text = "Downloads only scripts, tools, and documentation. Does NOT download PowerCLI modules. Use this for updates when you already have PowerCLI modules installed."
            Location = New-Object System.Drawing.Point(50, 175)
            Size = New-Object System.Drawing.Size(600, 40)
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
            ForeColor = [System.Drawing.Color]::DarkBlue
        }
        $optionsForm.Controls.Add($lblScriptsDesc)
        
        # Custom Download Option
        $rbCustom = New-Object System.Windows.Forms.RadioButton -Property @{
            Text = "Custom Download"
            Location = New-Object System.Drawing.Point(30, 230)
            Size = New-Object System.Drawing.Size(600, 25)
            Font = $font
            ForeColor = [System.Drawing.Color]::DarkOrange
        }
        $optionsForm.Controls.Add($rbCustom)
        
        $lblCustomDesc = New-Object System.Windows.Forms.Label -Property @{
            Text = "Choose specific components to download. Allows you to select individual scripts, documentation sections, and whether to include PowerCLI modules."
            Location = New-Object System.Drawing.Point(50, 255)
            Size = New-Object System.Drawing.Size(600, 40)
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
            ForeColor = [System.Drawing.Color]::DarkOrange
        }
        $optionsForm.Controls.Add($lblCustomDesc)
        
        # Download Directory
        $lblDownloadDir = New-Object System.Windows.Forms.Label -Property @{
            Text = "Download Directory:"
            Location = New-Object System.Drawing.Point(30, 310)
            Size = New-Object System.Drawing.Size(150, 25)
            Font = $font
        }
        $optionsForm.Controls.Add($lblDownloadDir)
        
        $txtDownloadDir = New-Object System.Windows.Forms.TextBox -Property @{
            Location = New-Object System.Drawing.Point(190, 310)
            Size = New-Object System.Drawing.Size(350, 25)
            Font = $font
            Text = Join-Path $env:USERPROFILE "VMware-Tools"
        }
        $optionsForm.Controls.Add($txtDownloadDir)
        
        $btnBrowse = New-Object System.Windows.Forms.Button -Property @{
            Text = "Browse"
            Location = New-Object System.Drawing.Point(550, 310)
            Size = New-Object System.Drawing.Size(80, 25)
            Font = $font
        }
        $optionsForm.Controls.Add($btnBrowse)
        
        # Progress Information
        $lblProgress = New-Object System.Windows.Forms.Label -Property @{
            Text = "Download will create a complete local directory structure with all necessary files and documentation from GitHub."
            Location = New-Object System.Drawing.Point(30, 350)
            Size = New-Object System.Drawing.Size(600, 40)
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
            ForeColor = [System.Drawing.Color]::DarkSlateGray
        }
        $optionsForm.Controls.Add($lblProgress)
        
        # Buttons
        $btnDownload = New-Object System.Windows.Forms.Button -Property @{
            Text = "Start Download"
            Location = New-Object System.Drawing.Point(450, 410)
            Size = New-Object System.Drawing.Size(120, 35)
            Font = $font
            DialogResult = "OK"
            BackColor = [System.Drawing.Color]::LightGreen
        }
        $optionsForm.Controls.Add($btnDownload)
        
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
            $folderDialog.SelectedPath = $txtDownloadDir.Text
            
            if ($folderDialog.ShowDialog() -eq "OK") {
                $txtDownloadDir.Text = $folderDialog.SelectedPath
            }
        })
        
        $optionsForm.AcceptButton = $btnDownload
        $optionsForm.CancelButton = $btnCancel
        
        $result = $optionsForm.ShowDialog()
        
        if ($result -eq "OK") {
            $downloadType = if ($rbFullDownload.Checked) { "Full" } elseif ($rbScriptsOnly.Checked) { "Scripts" } else { "Custom" }
            
            Write-StartupLog "User selected download type: $downloadType" "INFO"
            
            return @{
                DownloadType = $downloadType
                DownloadDirectory = $txtDownloadDir.Text
                Cancelled = $false
            }
        } else {
            Write-StartupLog "User cancelled download" "INFO"
            return @{
                DownloadType = ""
                DownloadDirectory = ""
                Cancelled = $true
            }
        }
    } else {
        # Console fallback
        Write-Host ""
        Write-Host "=== Download Options ===" -ForegroundColor Cyan
        Write-Host "1. Full Download (Recommended) - All files including PowerCLI modules"
        Write-Host "2. Scripts and Documentation Only - No PowerCLI modules"
        Write-Host "3. Custom Download - Choose components"
        Write-Host ""
        
        $choice = Read-Host "Select download type (1, 2, or 3)"
        $downloadDir = Read-Host "Download directory (default: $env:USERPROFILE\VMware-Tools)"
        
        if ([string]::IsNullOrWhiteSpace($downloadDir)) {
            $downloadDir = Join-Path $env:USERPROFILE "VMware-Tools"
        }
        
        $downloadType = switch ($choice) {
            "1" { "Full" }
            "2" { "Scripts" }
            "3" { "Custom" }
            default { "Full" }
        }
        
        Write-StartupLog "User selected download type: $downloadType" "INFO"
        
        return @{
            DownloadType = $downloadType
            DownloadDirectory = $downloadDir
            Cancelled = $false
        }
    }
}

function Download-GitHubFile {
    param(
        [string]$GitHubRawUrl,
        [string]$FilePath,
        [string]$LocalPath
    )
    
    try {
        $url = "$GitHubRawUrl/$FilePath"
        Write-StartupLog "Downloading: $url" "INFO"
        
        # Create directory if it doesn't exist
        $localDir = Split-Path $LocalPath -Parent
        if (-not (Test-Path $localDir)) {
            New-Item -Path $localDir -ItemType Directory -Force | Out-Null
        }
        
        # Download file with proper encoding
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing -ErrorAction Stop
        
        # Verify file was downloaded and has content
        if ((Test-Path $LocalPath) -and (Get-Item $LocalPath).Length -gt 0) {
            Write-StartupLog "Successfully downloaded: $FilePath" "SUCCESS"
            return $true
        } else {
            Write-StartupLog "Downloaded file is empty or missing: $FilePath" "ERROR"
            return $false
        }
    } catch {
        Write-StartupLog "Failed to download $FilePath`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Note: Combine-SplitZipFiles function removed as PowerCLI modules are now directly available

function Start-Download {
    param(
        [string]$DownloadType,
        [string]$DownloadDirectory
    )
    
    Write-StartupLog "Starting $DownloadType download to $DownloadDirectory" "INFO" -ToConsole
    
    # Create download directory structure
    try {
        if (-not (Test-Path $DownloadDirectory)) {
            New-Item -Path $DownloadDirectory -ItemType Directory -Force | Out-Null
            Write-Host "✅ Created download directory: $DownloadDirectory" -ForegroundColor Green
        }
        
        # Create necessary subdirectories
        $subDirectories = @("Documentation", "Documentation/Security", "Logs", "Modules")
        foreach ($subDir in $subDirectories) {
            $fullPath = Join-Path $DownloadDirectory $subDir
            if (-not (Test-Path $fullPath)) {
                New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
                Write-Host "✅ Created directory: $subDir" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "❌ Failed to create directory structure: $($_.Exception.Message)" -ForegroundColor Red
        Write-StartupLog "Failed to create directory structure: $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    # Show progress form if GUI available
    $progressForm = $null
    $progressBar = $null
    $statusLabel = $null
    
    if ($script:HasGUI) {
        $progressForm = New-Object System.Windows.Forms.Form -Property @{
            Text = "Downloading VMware vCenter Password Management Tool"
            Size = New-Object System.Drawing.Size(600, 200)
            StartPosition = "CenterScreen"
            FormBorderStyle = "FixedDialog"
            MaximizeBox = $false
            MinimizeBox = $false
            ControlBox = $false
        }
        
        $font = New-Object System.Drawing.Font("Segoe UI", 10)
        
        $statusLabel = New-Object System.Windows.Forms.Label -Property @{
            Text = "Preparing download..."
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
            Text = "Please wait while the download completes..."
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
    
    # Define files to download
    $filesToDownload = @()
    
    switch ($DownloadType) {
        "Full" {
            $filesToDownload = @(
                @{ Name = "Main script"; GitHubPath = "VMware-Vcenter-Password-Management.ps1"; LocalPath = "VMware-Vcenter-Password-Management.ps1"; Required = $true },
                @{ Name = "Startup script"; GitHubPath = "Startup-Script.ps1"; LocalPath = "Startup-Script.ps1"; Required = $true },
                @{ Name = "README documentation"; GitHubPath = "README.md"; LocalPath = "README.md"; Required = $true },
                @{ Name = "Getting started guide"; GitHubPath = "Documentation/GETTING-STARTED.md"; LocalPath = "Documentation/GETTING-STARTED.md"; Required = $true },
                @{ Name = "Security documentation"; GitHubPath = "Documentation/Security/SECURITY.md"; LocalPath = "Documentation/Security/SECURITY.md"; Required = $true },
                @{ Name = "Workflow diagrams"; GitHubPath = "Documentation/WORKFLOW-DIAGRAM.md"; LocalPath = "Documentation/WORKFLOW-DIAGRAM.md"; Required = $true },
                @{ Name = "Hosts configuration"; GitHubPath = "hosts.txt"; LocalPath = "hosts.txt"; Required = $true },
                @{ Name = "Users configuration"; GitHubPath = "users.txt"; LocalPath = "users.txt"; Required = $true },
                @{ Name = "License file"; GitHubPath = "LICENSE"; LocalPath = "LICENSE"; Required = $true }
                # Note: PowerCLI modules are now directly included in the repository
            )
        }
        "Scripts" {
            $filesToDownload = @(
                @{ Name = "Main script"; GitHubPath = "VMware-Vcenter-Password-Management.ps1"; LocalPath = "VMware-Vcenter-Password-Management.ps1"; Required = $true },
                @{ Name = "Startup script"; GitHubPath = "Startup-Script.ps1"; LocalPath = "Startup-Script.ps1"; Required = $true },
                @{ Name = "README documentation"; GitHubPath = "README.md"; LocalPath = "README.md"; Required = $true },
                @{ Name = "Getting started guide"; GitHubPath = "Documentation/GETTING-STARTED.md"; LocalPath = "Documentation/GETTING-STARTED.md"; Required = $true },
                @{ Name = "Security documentation"; GitHubPath = "Documentation/Security/SECURITY.md"; LocalPath = "Documentation/Security/SECURITY.md"; Required = $true },
                @{ Name = "Workflow diagrams"; GitHubPath = "Documentation/WORKFLOW-DIAGRAM.md"; LocalPath = "Documentation/WORKFLOW-DIAGRAM.md"; Required = $true },
                @{ Name = "Hosts configuration"; GitHubPath = "hosts.txt"; LocalPath = "hosts.txt"; Required = $true },
                @{ Name = "Users configuration"; GitHubPath = "users.txt"; LocalPath = "users.txt"; Required = $true },
                @{ Name = "License file"; GitHubPath = "LICENSE"; LocalPath = "LICENSE"; Required = $true }
            )
        }
        "Custom" {
            # For demo purposes, use Scripts configuration
            $filesToDownload = @(
                @{ Name = "Main script"; GitHubPath = "VMware-Vcenter-Password-Management.ps1"; LocalPath = "VMware-Vcenter-Password-Management.ps1"; Required = $true },
                @{ Name = "README documentation"; GitHubPath = "README.md"; LocalPath = "README.md"; Required = $true },
                @{ Name = "Hosts configuration"; GitHubPath = "hosts.txt"; LocalPath = "hosts.txt"; Required = $true },
                @{ Name = "Users configuration"; GitHubPath = "users.txt"; LocalPath = "users.txt"; Required = $true }
            )
        }
    }
    
    if ($progressBar) {
        $progressBar.Maximum = $filesToDownload.Count
        $progressBar.Value = 0
    }
    
    $successCount = 0
    $failureCount = 0
    
    # Download files from GitHub
    foreach ($file in $filesToDownload) {
        if ($statusLabel) {
            $statusLabel.Text = "Downloading: $($file.Name)"
            $statusLabel.Refresh()
        }
        
        Write-Host "Downloading: $($file.Name)" -ForegroundColor Cyan
        Write-StartupLog "Downloading file: $($file.Name)" "INFO"
        
        try {
            $localFilePath = Join-Path $DownloadDirectory $file.LocalPath
            $downloadSuccess = Download-GitHubFile -GitHubRawUrl $script:GitHubRawUrl -FilePath $file.GitHubPath -LocalPath $localFilePath
            
            if ($downloadSuccess) {
                Write-Host "✅ $($file.Name) downloaded successfully" -ForegroundColor Green
                Write-StartupLog "File downloaded successfully: $($file.Name)" "SUCCESS"
                $successCount++
            } else {
                if ($file.Required) {
                    Write-Host "❌ Failed to download required file: $($file.Name)" -ForegroundColor Red
                    Write-StartupLog "Failed to download required file: $($file.Name)" "ERROR"
                    $failureCount++
                } else {
                    Write-Host "⚠️ Optional file download failed: $($file.Name)" -ForegroundColor Yellow
                    Write-StartupLog "Optional file download failed: $($file.Name)" "WARN"
                }
            }
        } catch {
            if ($file.Required) {
                Write-Host "❌ Failed to download $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
                Write-StartupLog "Failed to download required file $($file.Name): $($_.Exception.Message)" "ERROR"
                $failureCount++
            } else {
                Write-Host "⚠️ Optional file $($file.Name) failed: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-StartupLog "Optional file failed $($file.Name): $($_.Exception.Message)" "WARN"
            }
        }
        
        if ($progressBar) {
            $progressBar.Value++
            $progressBar.Refresh()
        }
    }
    
    # PowerCLI modules are now directly available in the Modules directory
    if ($DownloadType -eq "Full") {
        $modulesDir = Join-Path $DownloadDirectory "Modules"
        $powerCLIModules = Get-ChildItem -Path $modulesDir -Directory | Where-Object { $_.Name -like "VMware.*" }
        
        if ($powerCLIModules.Count -gt 0) {
            Write-Host "✅ PowerCLI modules are ready: $($powerCLIModules.Count) modules available" -ForegroundColor Green
            Write-StartupLog "PowerCLI modules available: $($powerCLIModules.Count) modules" "SUCCESS"
        } else {
            Write-Host "⚠️ No PowerCLI modules found in Modules directory" -ForegroundColor Yellow
            Write-StartupLog "No PowerCLI modules found" "WARN"
        }
    }
    
    # Create additional configuration files
    if ($statusLabel) {
        $statusLabel.Text = "Creating configuration files..."
        $statusLabel.Refresh()
    }
    
    Write-Host "Creating configuration files..." -ForegroundColor Cyan
    
    # Only create config files if they don't exist (don't overwrite existing ones)
    $hostsFile = Join-Path $DownloadDirectory "hosts.txt"
    $usersFile = Join-Path $DownloadDirectory "users.txt"
    
    if (-not (Test-Path $hostsFile)) {
        Write-Host "Creating hosts.txt configuration template..." -ForegroundColor Cyan
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
        $hostsContent | Set-Content -Path $hostsFile
        Write-Host "✅ Created hosts.txt template" -ForegroundColor Green
    } else {
        Write-Host "✅ hosts.txt already exists - preserving existing configuration" -ForegroundColor Yellow
    }
    
    if (-not (Test-Path $usersFile)) {
        Write-Host "Creating users.txt configuration template..." -ForegroundColor Cyan
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
        $usersContent | Set-Content -Path $usersFile
        Write-Host "✅ Created users.txt template" -ForegroundColor Green
    } else {
        Write-Host "✅ users.txt already exists - preserving existing configuration" -ForegroundColor Yellow
    }
    
    # Create desktop shortcut if on Windows
    if ($script:IsWindowsPlatform) {
        try {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "VMware vCenter Password Management.lnk"
            $targetPath = Join-Path $DownloadDirectory "VMware-Vcenter-Password-Management.ps1"
            
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
            $shortcut.WorkingDirectory = $DownloadDirectory
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
    
    # Download summary
    Write-Host ""
    Write-Host "=== Download Complete ===" -ForegroundColor Green
    Write-Host "Download Directory: $DownloadDirectory" -ForegroundColor Cyan
    Write-Host "Files Downloaded: $successCount" -ForegroundColor Green
    Write-Host "Failed Downloads: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })
    
    if ($DownloadType -eq "Full") {
        Write-Host "PowerCLI Modules: Included (directly available in Modules directory)" -ForegroundColor Green
    } else {
        Write-Host "PowerCLI Modules: Not included (install PowerCLI separately)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Edit hosts.txt with your ESXi host addresses" -ForegroundColor White
    Write-Host "2. Edit users.txt with target usernames (optional)" -ForegroundColor White
    Write-Host "3. Run VMware-Vcenter-Password-Management.ps1 to start" -ForegroundColor White
    
    if ($script:IsWindowsPlatform) {
        Write-Host "4. Use the desktop shortcut for easy access" -ForegroundColor White
    }
    
    Write-StartupLog "Download completed: $successCount successes, $failureCount failures" "INFO"
    
    # Show completion dialog
    if ($script:HasGUI) {
        $completionMessage = "Download completed successfully!`n`nDownload Directory: $DownloadDirectory`nFiles Downloaded: $successCount`n`nNext steps:`n1. Edit hosts.txt with your ESXi hosts`n2. Run the main script to begin`n`nWould you like to open the download directory now?"
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            $completionMessage,
            "Download Complete",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                Invoke-Item $DownloadDirectory
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
    
    # Show download options
    Write-Host ""
    Write-Host "=== Download Options ===" -ForegroundColor Cyan
    $downloadOptions = Show-DownloadOptions
    
    if ($downloadOptions.Cancelled) {
        Write-Host "Download cancelled by user" -ForegroundColor Yellow
        Write-StartupLog "Download cancelled by user" "INFO"
        return
    }
    
    # Start download
    Write-Host ""
    Write-Host "=== Starting Download from GitHub ===" -ForegroundColor Cyan
    $downloadSuccess = Start-Download -DownloadType $downloadOptions.DownloadType -DownloadDirectory $downloadOptions.DownloadDirectory
    
    if ($downloadSuccess) {
        Write-Host ""
        Write-Host "🎉 Download completed successfully!" -ForegroundColor Green
        Write-Host "The VMware vCenter Password Management Tool is ready to use." -ForegroundColor Green
        Write-StartupLog "Startup script completed successfully" "SUCCESS"
    } else {
        Write-Host ""
        Write-Host "⚠️ Download completed with some issues." -ForegroundColor Yellow
        Write-Host "Check the log file for details: $script:LogFilePath" -ForegroundColor Yellow
        Write-StartupLog "Startup script completed with issues" "WARN"
    }
    
    if (-not $script:HasGUI) {
        Read-Host "Press Enter to exit"
    }
}

# Start the startup script
Start-StartupScript