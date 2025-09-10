# SRoutines/Common.psm1
# Shared utility functions for VMware-Vcenter-Password-Management
# Keep this file light and focused on small, reusable utilities.

using namespace System.Management.Automation

function Test-RequiredModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ModuleNames
    )
    $missing = @()
    foreach ($m in $ModuleNames) {
        if (-not (Get-Module -ListAvailable -Name $m -ErrorAction SilentlyContinue)) {
            Write-Verbose "Module missing: $m"
            $missing += $m
        }
    }
    if ($missing.Count -gt 0) {
        return @{ Success = $false; MissingModules = $missing }
    }
    return @{ Success = $true }
}

function Ensure-PSGalleryAndNuGet {
    [CmdletBinding()]
    param()

    # Check PSGallery availability
    try {
        $psRepos = Get-PSRepository -ErrorAction Stop
    } catch {
        return @{ Success = $false; Missing = 'PSRepositoryUnavailable'; Details = $_.Exception.Message }
    }

    $psGallery = $psRepos | Where-Object { ($_.SourceLocation -match 'powershellgallery') -or ($_.Name -match 'PSGallery') }
    if (-not $psGallery) {
        return @{ Success = $false; Missing = 'PSGallery'; Details = 'PowerShell Gallery repository not found' }
    }

    # Check NuGet provider
    $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    if (-not $nuget) {
        return @{ Success = $false; Missing = 'NuGet'; Details = 'NuGet package provider not available' }
    }

    return @{ Success = $true }
}

function Check-EnvironmentAndModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$RequiredModules = @('VCF.PowerCLI')  # default preference; includes fallback logic elsewhere
    )
    # Returns: @{ Success = bool; MissingProviders = @(); MissingModules = @(); Message = string }

    $result = @{ Success = $true; MissingProviders = @(); MissingModules = @(); Message = '' }

    $psCheck = Ensure-PSGalleryAndNuGet
    if (-not $psCheck.Success) {
        $result.Success = $false
        $result.MissingProviders += $psCheck.Missing
        $result.Message = $psCheck.Details
        return $result
    }

    # Test modules: prefer VCF.PowerCLI and/or VMware.PowerCLI
    $found = @()
    foreach ($m in $RequiredModules) {
        if (Get-Module -ListAvailable -Name $m -ErrorAction SilentlyContinue) {
            $found += $m
        }
    }

    # Also accept VMware.PowerCLI as fallback
    if ($found.Count -eq 0 -and (Get-Module -ListAvailable -Name 'VMware.PowerCLI' -ErrorAction SilentlyContinue)) {
        $found += 'VMware.PowerCLI'
    }

    if ($found.Count -eq 0) {
        $result.Success = $false
        $result.MissingModules += 'VCF.PowerCLI or VMware.PowerCLI'
        $result.Message = 'No supported PowerCLI module found'
        return $result
    }

    $result.Success = $true
    $result.Message = "Detected modules: $($found -join ', ')"
    return $result
}

function Resolve-PowerCLIModule {
    [CmdletBinding()]
    param()
    if (Get-Module -ListAvailable -Name 'VCF.PowerCLI' -ErrorAction SilentlyContinue) {
        return 'VCF.PowerCLI'
    } elseif (Get-Module -ListAvailable -Name 'VMware.PowerCLI' -ErrorAction SilentlyContinue) {
        return 'VMware.PowerCLI'
    } else {
        return $null
    }
}

# Lazy import with in-memory cache to avoid reloading modules repeatedly
if (-not $script:SRoutinesLoadedModules) { $script:SRoutinesLoadedModules = @{} }
function LazyImport-Module {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    if ($script:SRoutinesLoadedModules.ContainsKey($ModuleName)) {
        return $true
    }
    try {
        Import-Module -Name $ModuleName -ErrorAction Stop
        $script:SRoutinesLoadedModules[$ModuleName] = (Get-Module -Name $ModuleName)
        return $true
    } catch {
        Write-Verbose "Failed to import $ModuleName: $_"
        return $false
    }
}

function Get-LoadedModule {
    param([string]$Name)
    if ($script:SRoutinesLoadedModules.ContainsKey($Name)) { return $script:SRoutinesLoadedModules[$Name] }
    return $null
}

function Get-VCCredentials {
    [CmdletBinding()]
    param(
        [string]$Message = 'Enter vCenter credentials'
    )
    try {
        $cred = Get-Credential -Message $Message
        return $cred
    } catch {
        throw "Credential prompt cancelled or failed: $_"
    }
}

function New-TempSecureCredentialFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )
    $tmp = [System.IO.Path]::GetTempFileName()
    $secureString = $Credential.Password | ConvertFrom-SecureString
    $obj = @{ UserName = $Credential.UserName; Password = $secureString; CreatedOn = (Get-Date).ToString('o') } | ConvertTo-Json
    Set-Content -Path $tmp -Value $obj -Encoding UTF8
    return $tmp
}

function Remove-TempSecureCredentialFile {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)
    if (Test-Path $Path) { try { Remove-Item -Path $Path -Force -ErrorAction Stop; return $true } catch { Write-Verbose "Failed to remove temp cred file: $_"; return $false } }
    return $true
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG','SUCCESS')][string]$Level = 'INFO'
    )
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Output "$ts [$Level] $Message"
}

function Show-EnvironmentLockedMessage {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string[]]$MissingItems)
    $msg = "Your environment appears to be locked down or missing components required to run this tool.`n"
    $msg += "Missing or unavailable components:`n - " + ($MissingItems -join "`n - ") + "`n`n"
    $msg += "Remediation suggestions:`n"
    $msg += " - Ensure you have permission to install PowerShell modules and providers.`n"
    $msg += " - To install NuGet provider: https://learn.microsoft.com/powershell/scripting/gallery/installing-psget?view=powershell-7.0`n"
    $msg += " - PowerCLI: https://developer.vmware.com/docs/powercli/latest/installation/`n"
    $msg += "If your environment is centrally locked down, contact your system administrator with the above details."
    return $msg
}

# UI helper: append a line to the operation status textbox (keeps it bounded)
function Append-OperationStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$TextBox,
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS','DEBUG')][string]$Level = 'INFO',
        [int]$MaxLines = 500
    )
    try {
        $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        $line = "$ts [$Level] $Message"
        if ($null -eq $TextBox) { Write-Log $line -Level $Level; return }
        $existing = $TextBox.Text -split "`r?`n"
        if ($existing.Count -ge $MaxLines) { $existing = $existing[($existing.Count - $MaxLines + 1)..($existing.Count -1)] }
        $new = $existing + $line
        $TextBox.Text = ($new -join "`r`n")
        $TextBox.SelectionStart = $TextBox.Text.Length
        $TextBox.ScrollToCaret()
    } catch {
        Write-Verbose "Append-OperationStatus failed: $_"
    }
}

function Update-ProgressBar {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$ProgressBar, [int]$Value)
    try {
        if ($null -eq $ProgressBar) { return }
        $v = [int]([math]::Max(0, [math]::Min(100, $Value)))
        $ProgressBar.Value = $v
    } catch {
        Write-Verbose "Update-ProgressBar failed: $_"
    }
}

function Populate-CredentialFields {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$UserNameTextBox,
        [Parameter(Mandatory=$true)]$PasswordTextBox,
        [Parameter(Mandatory=$true)][PSCredential]$Credential
    )
    try {
        $UserNameTextBox.Text = $Credential.UserName
        $PasswordTextBox.Text = $Credential.GetNetworkCredential().Password
    } catch {
        Write-Verbose "Populate-CredentialFields failed: $_"
    }
}

function Show-MessageBox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter()][string]$Title = 'Message',
        [ValidateSet('OK','OKCancel','YesNo')][string]$Buttons = 'OK',
        [ValidateSet('Information','Warning','Error')][string]$Icon = 'Information'
    )
    try {
        switch ($Buttons) {
            'OK' { $btn = [System.Windows.Forms.MessageBoxButtons]::OK }
            'OKCancel' { $btn = [System.Windows.Forms.MessageBoxButtons]::OKCancel }
            'YesNo' { $btn = [System.Windows.Forms.MessageBoxButtons]::YesNo }
        }
        switch ($Icon) {
            'Information' { $ic = [System.Windows.Forms.MessageBoxIcon]::Information }
            'Warning' { $ic = [System.Windows.Forms.MessageBoxIcon]::Warning }
            'Error' { $ic = [System.Windows.Forms.MessageBoxIcon]::Error }
        }
        return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $btn, $ic)
    } catch {
        Write-Host $Message -ForegroundColor Yellow
    }
}

Export-ModuleMember -Function Test-RequiredModules, Ensure-PSGalleryAndNuGet, Check-EnvironmentAndModules, Resolve-PowerCLIModule, LazyImport-Module, Get-LoadedModule, Get-VCCredentials, New-TempSecureCredentialFile, Remove-TempSecureCredentialFile, Write-Log, Show-EnvironmentLockedMessage, Append-OperationStatus, Update-ProgressBar, Populate-CredentialFields, Show-MessageBox