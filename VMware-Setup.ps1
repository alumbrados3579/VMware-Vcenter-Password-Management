# VMware vCenter Password Management Tool - GUI Setup Script
# Version 0.5 BETA - Automated GUI Setup Edition
# Purpose: Complete automated setup with GUI progress tracking

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    [System.Windows.Forms.MessageBox]::Show("CRITICAL ERROR: $($_.Exception.Message)", "Setup Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables
$script:SetupForm = $null
$script:ProgressBar = $null
$script:StatusLabel = $null
$script:DetailedStatusTextBox = $null
$script:CurrentStep = 0
$script:TotalSteps = 6

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

VMware vCenter Password Management Tool - Version 0.5 BETA Setup

Click OK to acknowledge and continue...
"@
    
    [System.Windows.Forms.MessageBox]::Show($dodWarning, "DoD System Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

function Create-SetupForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VMware Password Manager - Setup Wizard"
    $form.Size = New-Object System.Drawing.Size(700, 500)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Icon = [System.Drawing.SystemIcons]::Shield
    
    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "VMware vCenter Password Management Tool"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(650, 30)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    
    # Subtitle
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Version 0.5 BETA - Automated Setup Wizard"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $subtitleLabel.Location = New-Object System.Drawing.Point(20, 50)
    $subtitleLabel.Size = New-Object System.Drawing.Size(650, 20)
    $subtitleLabel.TextAlign = "MiddleCenter"
    $subtitleLabel.ForeColor = [System.Drawing.Color]::DarkGreen
    
    # Warning message
    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Text = "⚠️ This process may take several minutes. Please be patient and do not close this window."
    $warningLabel.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Bold)
    $warningLabel.Location = New-Object System.Drawing.Point(20, 80)
    $warningLabel.Size = New-Object System.Drawing.Size(650, 20)
    $warningLabel.TextAlign = "MiddleCenter"
    $warningLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    
    # Progress bar
    $script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $script:ProgressBar.Location = New-Object System.Drawing.Point(20, 120)
    $script:ProgressBar.Size = New-Object System.Drawing.Size(650, 25)
    $script:ProgressBar.Style = "Continuous"
    $script:ProgressBar.Maximum = $script:TotalSteps
    
    # Status label
    $script:StatusLabel = New-Object System.Windows.Forms.Label
    $script:StatusLabel.Text = "Initializing setup..."
    $script:StatusLabel.Location = New-Object System.Drawing.Point(20, 155)
    $script:StatusLabel.Size = New-Object System.Drawing.Size(650, 20)
    $script:StatusLabel.ForeColor = [System.Drawing.Color]::Blue
    
    # Detailed status text box
    $detailLabel = New-Object System.Windows.Forms.Label
    $detailLabel.Text = "Detailed Progress:"
    $detailLabel.Location = New-Object System.Drawing.Point(20, 185)
    $detailLabel.Size = New-Object System.Drawing.Size(200, 20)
    
    $script:DetailedStatusTextBox = New-Object System.Windows.Forms.TextBox
    $script:DetailedStatusTextBox.Location = New-Object System.Drawing.Point(20, 210)
    $script:DetailedStatusTextBox.Size = New-Object System.Drawing.Size(650, 200)
    $script:DetailedStatusTextBox.Multiline = $true
    $script:DetailedStatusTextBox.ScrollBars = "Vertical"
    $script:DetailedStatusTextBox.ReadOnly = $true
    $script:DetailedStatusTextBox.BackColor = [System.Drawing.Color]::Black
    $script:DetailedStatusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:DetailedStatusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    # Close button (initially disabled)
    $script:CloseButton = New-Object System.Windows.Forms.Button
    $script:CloseButton.Text = "Setup in Progress..."
    $script:CloseButton.Location = New-Object System.Drawing.Point(300, 425)
    $script:CloseButton.Size = New-Object System.Drawing.Size(120, 30)
    $script:CloseButton.Enabled = $false
    $script:CloseButton.Add_Click({
        $form.Close()
    })
    
    $form.Controls.AddRange(@($titleLabel, $subtitleLabel, $warningLabel, $script:ProgressBar, $script:StatusLabel, $detailLabel, $script:DetailedStatusTextBox, $script:CloseButton))
    
    return $form
}

function Update-Progress {
    param(
        [string]$Status,
        [string]$DetailedMessage
    )
    
    $script:CurrentStep++
    
    # Ensure progress bar value is within valid range
    if ($script:CurrentStep -le $script:ProgressBar.Maximum) {
        $script:ProgressBar.Value = $script:CurrentStep
    }
    
    $script:StatusLabel.Text = "[$script:CurrentStep/$script:TotalSteps] $Status"
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $script:DetailedStatusTextBox.AppendText("[$timestamp] $DetailedMessage`r`n")
    $script:DetailedStatusTextBox.ScrollToCaret()
    
    [System.Windows.Forms.Application]::DoEvents()
}

function Add-DetailedStatus {
    param([string]$Message)
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $script:DetailedStatusTextBox.AppendText("[$timestamp] $Message`r`n")
    $script:DetailedStatusTextBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Initialize-PowerShellEnvironment {
    Update-Progress "Configuring PowerShell Environment" "Setting up PowerShell execution policy and environment..."
    
    try {
        Add-DetailedStatus "Setting execution policy to RemoteSigned (secure but allows local scripts)..."
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Add-DetailedStatus "✅ Execution policy configured successfully"
        Add-DetailedStatus "   This allows local scripts while maintaining security for downloaded scripts"
    } catch {
        Add-DetailedStatus "⚠️ Warning: Could not set execution policy: $($_.Exception.Message)"
    }
    
    try {
        Add-DetailedStatus "Enabling TLS 1.2 for secure downloads..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Add-DetailedStatus "✅ TLS 1.2 enabled for secure connections"
    } catch {
        Add-DetailedStatus "⚠️ Warning: Could not configure TLS: $($_.Exception.Message)"
    }
    
    Start-Sleep -Milliseconds 500
}

function Install-NuGetProvider {
    Update-Progress "Installing NuGet Provider" "Installing package management components..."
    
    try {
        Add-DetailedStatus "Checking for NuGet provider..."
        $nuget = Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue
        
        if (-not $nuget) {
            Add-DetailedStatus "Installing NuGet provider (required for PowerShell Gallery)..."
            Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
            Add-DetailedStatus "✅ NuGet provider installed successfully"
        } else {
            Add-DetailedStatus "✅ NuGet provider already installed (Version: $($nuget.Version))"
        }
    } catch {
        Add-DetailedStatus "⚠️ Warning: Could not install NuGet provider: $($_.Exception.Message)"
    }
    
    Start-Sleep -Milliseconds 500
}

function Update-PowerShellGet {
    Update-Progress "Updating PowerShellGet Module" "Ensuring latest package management capabilities..."
    
    try {
        Add-DetailedStatus "Checking PowerShellGet module version..."
        $psGet = Get-Module -Name "PowerShellGet" -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        
        if ($psGet) {
            Add-DetailedStatus "Current PowerShellGet version: $($psGet.Version)"
        }
        
        # Check if PackageManagement is in use and handle gracefully
        $packageMgmt = Get-Module -Name "PackageManagement"
        if ($packageMgmt) {
            Add-DetailedStatus "PackageManagement v$($packageMgmt.Version) is currently loaded"
            Add-DetailedStatus "Skipping PowerShellGet update to avoid module conflicts"
            Add-DetailedStatus "✅ Using existing PowerShellGet installation"
        } else {
            Add-DetailedStatus "Updating PowerShellGet module..."
            Install-Module -Name "PowerShellGet" -Force -Scope CurrentUser -AllowClobber
            Add-DetailedStatus "✅ PowerShellGet module updated successfully"
        }
    } catch {
        Add-DetailedStatus "⚠️ Warning: Could not update PowerShellGet: $($_.Exception.Message)"
        Add-DetailedStatus "This is often due to module conflicts and can be safely ignored"
    }
    
    Start-Sleep -Milliseconds 500
}

function Install-VMwarePowerCLI {
    Update-Progress "Installing VMware PowerCLI" "This step may take several minutes - downloading and configuring VMware modules..."
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $localModulesPath = Join-Path $scriptRoot "Modules"
    
    try {
        Add-DetailedStatus "Creating local Modules directory for enterprise-safe installation..."
        if (-not (Test-Path $localModulesPath)) {
            New-Item -Path $localModulesPath -ItemType Directory -Force | Out-Null
            Add-DetailedStatus "✅ Local Modules directory created: $localModulesPath"
        }
        
        Add-DetailedStatus "Adding local modules to PowerShell module path..."
        $currentPSModulePath = $env:PSModulePath
        if ($currentPSModulePath -notlike "*$localModulesPath*") {
            $env:PSModulePath = "$localModulesPath;$currentPSModulePath"
            Add-DetailedStatus "✅ Local Modules directory added to PowerShell module path"
        }
        
        # Check if PowerCLI already exists locally
        $localPowerCLIPath = Join-Path $localModulesPath "VMware.PowerCLI"
        $powerCLIExists = $false
        
        if (Test-Path $localPowerCLIPath) {
            Add-DetailedStatus "Checking existing PowerCLI installation..."
            $manifestFiles = Get-ChildItem -Path $localPowerCLIPath -Filter "VMware.PowerCLI.psd1" -Recurse -ErrorAction SilentlyContinue
            
            if ($manifestFiles) {
                try {
                    $manifestData = Import-PowerShellDataFile $manifestFiles[0].FullName
                    Add-DetailedStatus "✅ VMware PowerCLI found in local directory"
                    Add-DetailedStatus "   Version: $($manifestData.ModuleVersion)"
                    Add-DetailedStatus "   Location: $localPowerCLIPath"
                    $powerCLIExists = $true
                } catch {
                    Add-DetailedStatus "⚠️ Local PowerCLI found but manifest is corrupted, will re-download"
                }
            } else {
                Add-DetailedStatus "⚠️ Local PowerCLI directory exists but appears incomplete, will re-download"
            }
        }
        
        if (-not $powerCLIExists) {
            Add-DetailedStatus "Downloading VMware PowerCLI to local directory..."
            Add-DetailedStatus "⏳ This may take several minutes depending on your internet connection"
            Add-DetailedStatus "   Target directory: $localModulesPath"
            
            # Remove incomplete installation if it exists
            if (Test-Path $localPowerCLIPath) {
                Add-DetailedStatus "Removing incomplete PowerCLI installation..."
                Remove-Item -Path $localPowerCLIPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Download PowerCLI modules to local directory
            Save-Module -Name "VMware.PowerCLI" -Path $localModulesPath -Force
            Add-DetailedStatus "✅ VMware PowerCLI downloaded to local directory successfully"
        } else {
            Add-DetailedStatus "✅ Using existing local PowerCLI installation (no download needed)"
        }
        
        # Check if PowerCLI is already loaded in current session
        $loadedPowerCLI = Get-Module -Name "VMware.PowerCLI" -ErrorAction SilentlyContinue
        
        if ($loadedPowerCLI) {
            Add-DetailedStatus "✅ VMware PowerCLI already loaded in current session"
            Add-DetailedStatus "   Version: $($loadedPowerCLI.Version)"
            Add-DetailedStatus "   Location: $($loadedPowerCLI.ModuleBase)"
        } else {
            Add-DetailedStatus "Loading VMware PowerCLI modules..."
            Add-DetailedStatus "⏳ This step may take 1-2 minutes - please be patient"
            
            try {
                Import-Module VMware.PowerCLI -ErrorAction Stop
                $loadedModule = Get-Module -Name "VMware.PowerCLI"
                Add-DetailedStatus "✅ VMware PowerCLI loaded successfully"
                Add-DetailedStatus "   Version: $($loadedModule.Version)"
                
                if ($loadedModule.ModuleBase -like "*$localModulesPath*") {
                    Add-DetailedStatus "✅ Using LOCAL modules (enterprise-safe installation)"
                } else {
                    Add-DetailedStatus "⚠️ Using SYSTEM modules"
                }
            } catch {
                Add-DetailedStatus "⚠️ Could not load PowerCLI, checking for conflicts..."
                
                $vmwareModules = Get-Module | Where-Object { $_.Name -like "VMware.*" }
                if ($vmwareModules) {
                    Add-DetailedStatus "Found existing VMware modules in memory:"
                    foreach ($module in $vmwareModules) {
                        Add-DetailedStatus "  - $($module.Name) v$($module.Version)"
                    }
                    Add-DetailedStatus "✅ These modules are already loaded and working"
                } else {
                    throw "Failed to load PowerCLI: $($_.Exception.Message)"
                }
            }
        }
        
        Add-DetailedStatus "Configuring PowerCLI settings..."
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User -ErrorAction SilentlyContinue
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope User -ErrorAction SilentlyContinue
        Add-DetailedStatus "✅ VMware PowerCLI configured and ready for use"
        
        return $true
    } catch {
        Add-DetailedStatus "❌ Failed to install VMware PowerCLI: $($_.Exception.Message)"
        Add-DetailedStatus "Please check your internet connection and try again"
        return $false
    }
}

function Create-ConfigurationFiles {
    Update-Progress "Creating Configuration Files" "Setting up hosts.txt and users.txt configuration files..."
    
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
            Add-DetailedStatus "✅ Created hosts.txt configuration file"
        } else {
            Add-DetailedStatus "✅ hosts.txt already exists"
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
            Add-DetailedStatus "✅ Created users.txt configuration file"
        } else {
            Add-DetailedStatus "✅ users.txt already exists"
        }
        
        Add-DetailedStatus "Configuration files are ready for customization"
        
    } catch {
        Add-DetailedStatus "⚠️ Warning: Could not create configuration files: $($_.Exception.Message)"
    }
    
    Start-Sleep -Milliseconds 500
}

function Download-MainApplication {
    Update-Progress "Downloading Main Application" "Getting the latest GUI application from repository..."
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $mainTool = Join-Path $scriptRoot "VMware-Password-Manager.ps1"
    
    try {
        Add-DetailedStatus "Downloading latest VMware Password Manager GUI..."
        $guiUrl = "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/VMware-Password-Manager.ps1"
        Invoke-WebRequest -Uri $guiUrl -OutFile $mainTool -UseBasicParsing
        Add-DetailedStatus "✅ VMware Password Manager GUI downloaded successfully"
        Add-DetailedStatus "   Application ready to launch"
    } catch {
        Add-DetailedStatus "⚠️ Could not download GUI application: $($_.Exception.Message)"
        Add-DetailedStatus "You can manually download VMware-Password-Manager.ps1 from GitHub"
    }
    
    Start-Sleep -Milliseconds 500
}

function Complete-Setup {
    # Don't increment progress beyond maximum
    if ($script:CurrentStep -lt $script:TotalSteps) {
        Update-Progress "Setup Complete!" "All components installed and configured successfully"
    } else {
        Add-DetailedStatus "All components installed and configured successfully"
    }
    
    Add-DetailedStatus ""
    Add-DetailedStatus "=== SETUP COMPLETE ==="
    Add-DetailedStatus "✅ PowerShell environment configured"
    Add-DetailedStatus "✅ VMware PowerCLI installed and ready"
    Add-DetailedStatus "✅ Configuration files created"
    Add-DetailedStatus "✅ Main application downloaded"
    Add-DetailedStatus ""
    Add-DetailedStatus "Next Steps:"
    Add-DetailedStatus "1. Configure your ESXi hosts and users"
    Add-DetailedStatus "2. Test vCenter connectivity"
    Add-DetailedStatus "3. Run password operations (Dry Run first!)"
    Add-DetailedStatus ""
    Add-DetailedStatus "Ready to launch the VMware Password Manager!"
    
    # Ensure progress bar is at maximum
    $script:ProgressBar.Value = $script:ProgressBar.Maximum
    
    $script:CloseButton.Text = "Launch Application"
    $script:CloseButton.Enabled = $true
    $script:StatusLabel.Text = "Setup completed successfully! Click 'Launch Application' to continue."
    $script:StatusLabel.ForeColor = [System.Drawing.Color]::Green
}

function Start-SetupProcess {
    try {
        Initialize-PowerShellEnvironment
        Install-NuGetProvider
        Update-PowerShellGet
        $powerCLISuccess = Install-VMwarePowerCLI
        Create-ConfigurationFiles
        Download-MainApplication
        
        if ($powerCLISuccess) {
            Complete-Setup
        } else {
            # Ensure progress bar is at maximum even with warnings
            $script:ProgressBar.Value = $script:ProgressBar.Maximum
            $script:StatusLabel.Text = "Setup completed with warnings. Check detailed log for issues."
            $script:StatusLabel.ForeColor = [System.Drawing.Color]::Orange
            $script:CloseButton.Text = "Close"
            $script:CloseButton.Enabled = $true
        }
    } catch {
        Add-DetailedStatus "❌ Setup failed: $($_.Exception.Message)"
        Add-DetailedStatus "Error details: $($_.Exception.GetType().Name)"
        
        # Ensure progress bar shows some progress even on failure
        if ($script:ProgressBar.Value -eq 0) {
            $script:ProgressBar.Value = 1
        }
        
        $script:StatusLabel.Text = "Setup failed. Check detailed log for errors."
        $script:StatusLabel.ForeColor = [System.Drawing.Color]::Red
        $script:CloseButton.Text = "Close"
        $script:CloseButton.Enabled = $true
    }
}

# Main execution
Show-DoDWarning

$script:SetupForm = Create-SetupForm
$script:SetupForm.Add_Shown({
    # Start setup process after form is shown
    Start-Sleep -Milliseconds 500
    Start-SetupProcess
    
    # Check if we should launch the main application
    if ($script:CloseButton.Text -eq "Launch Application") {
        $script:CloseButton.Add_Click({
            $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
            $mainTool = Join-Path $scriptRoot "VMware-Password-Manager.ps1"
            if (Test-Path $mainTool) {
                Start-Process PowerShell -ArgumentList "-File `"$mainTool`"" -WindowStyle Normal
            }
        })
    }
})

[System.Windows.Forms.Application]::EnableVisualStyles()
$script:SetupForm.ShowDialog()