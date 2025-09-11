# DoDify Script - Add DoD Compliance Warnings to VMware Tools
# Version 1.0 - DoD Compliance Enhancement
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Purpose: Add DoD compliance warnings and banners to existing scripts
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

param(
    [Parameter(Mandatory=$false)]
    [string]$TargetScript,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllScripts,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveWarnings,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListScripts
)

# DoD Warning Banner Function
$DoDWarningFunction = @'
function Show-DoDWarning {
    Clear-Host
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host "*** U.S. GOVERNMENT COMPUTER SYSTEM WARNING ***" -ForegroundColor Red
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You are accessing a U.S. Government (USG) Information System (IS) that is" -ForegroundColor White
    Write-Host "provided for USG-authorized use only." -ForegroundColor White
    Write-Host ""
    Write-Host "By using this IS (which includes any device attached to this IS), you consent" -ForegroundColor White
    Write-Host "to the following conditions:" -ForegroundColor White
    Write-Host ""
    Write-Host "- The USG routinely intercepts and monitors communications on this IS" -ForegroundColor Cyan
    Write-Host "- At any time, the USG may inspect and seize data stored on this IS" -ForegroundColor Cyan
    Write-Host "- Communications using, or data stored on, this IS are not private" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "VMware vCenter Password Management Tool - DoD Compliant Version" -ForegroundColor Green
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host ""
    $acknowledge = Read-Host "Type 'AGREE' to acknowledge and continue"
    if ($acknowledge -ne "AGREE") {
        Write-Host "Operation cancelled by user" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}
'@

# DoD Logging Function
$DoDLoggingFunction = @'
function Write-DoDLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$User = $env:USERNAME,
        [string]$Computer = $env:COMPUTERNAME
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$User@$Computer] $Message"
    
    # Write to console
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor White }
    }
    
    # Write to DoD audit log
    $logPath = Join-Path $PSScriptRoot "DoD-Audit.log"
    try {
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Silent fail for logging
    }
}
'@

function Show-Usage {
    Write-Host ""
    Write-Host "DoDify Script - Add DoD Compliance to VMware Tools" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\DoDify.ps1 -TargetScript <script.ps1>     # Add DoD warnings to specific script"
    Write-Host "  .\DoDify.ps1 -AllScripts                    # Add DoD warnings to all PowerShell scripts"
    Write-Host "  .\DoDify.ps1 -RemoveWarnings -TargetScript <script.ps1>  # Remove DoD warnings"
    Write-Host "  .\DoDify.ps1 -ListScripts                   # List all PowerShell scripts in directory"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  .\DoDify.ps1 -TargetScript VMware-Setup.ps1"
    Write-Host "  .\DoDify.ps1 -AllScripts"
    Write-Host "  .\DoDify.ps1 -RemoveWarnings -TargetScript VMware-Setup.ps1"
    Write-Host ""
}

function Get-PowerShellScripts {
    $scripts = Get-ChildItem -Path . -Filter "*.ps1" -Recurse | Where-Object { 
        $_.Name -ne "DoDify.ps1" -and $_.Name -notlike "*-DoDified.ps1" 
    }
    return $scripts
}

function Test-HasDoDWarnings {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath -Raw
    return $content -match "Show-DoDWarning" -or $content -match "U\.S\. GOVERNMENT COMPUTER SYSTEM WARNING"
}

function Add-DoDWarnings {
    param([string]$FilePath)
    
    Write-Host "Processing: $FilePath" -ForegroundColor Cyan
    
    # Check if already has DoD warnings
    if (Test-HasDoDWarnings -FilePath $FilePath) {
        Write-Host "  [SKIP] Already has DoD warnings" -ForegroundColor Yellow
        return
    }
    
    try {
        # Read original content
        $content = Get-Content -Path $FilePath
        
        # Create backup
        $backupPath = $FilePath -replace "\.ps1$", "-Original.ps1"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "  [BACKUP] Created: $backupPath" -ForegroundColor Gray
        
        # Find insertion points
        $headerEnd = -1
        $mainExecutionStart = -1
        
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]
            
            # Find end of header comments
            if ($line -match "^#" -or $line.Trim() -eq "") {
                $headerEnd = $i
            }
            
            # Find main execution (not inside functions)
            if ($line -match "^[^#\s]" -and $line -notmatch "^function" -and $line -notmatch "^param" -and $mainExecutionStart -eq -1) {
                $mainExecutionStart = $i
                break
            }
        }
        
        # Insert DoD functions after header
        $newContent = @()
        
        # Add original header
        if ($headerEnd -ge 0) {
            $newContent += $content[0..$headerEnd]
        }
        
        # Add DoD functions
        $newContent += ""
        $newContent += "# === DoD COMPLIANCE FUNCTIONS ==="
        $newContent += $DoDWarningFunction.Split("`n")
        $newContent += ""
        $newContent += $DoDLoggingFunction.Split("`n")
        $newContent += "# === END DoD COMPLIANCE FUNCTIONS ==="
        $newContent += ""
        
        # Add DoD warning call before main execution
        if ($mainExecutionStart -ge 0) {
            # Add content before main execution
            if ($mainExecutionStart -1 -gt $headerEnd) {
                $newContent += $content[($headerEnd + 1)..($mainExecutionStart - 1)]
            }
            
            # Add DoD warning call
            $newContent += "# DoD Compliance Warning"
            $newContent += "Show-DoDWarning"
            $newContent += ""
            
            # Add rest of content
            $newContent += $content[$mainExecutionStart..($content.Count - 1)]
        } else {
            # No clear main execution found, add at end
            if ($headerEnd + 1 -lt $content.Count) {
                $newContent += $content[($headerEnd + 1)..($content.Count - 1)]
            }
            $newContent += ""
            $newContent += "# DoD Compliance Warning"
            $newContent += "Show-DoDWarning"
        }
        
        # Write modified content
        $newContent | Set-Content -Path $FilePath
        Write-Host "  [SUCCESS] DoD warnings added" -ForegroundColor Green
        
        # Update version info if present
        $updatedContent = Get-Content -Path $FilePath
        for ($i = 0; $i -lt $updatedContent.Count; $i++) {
            if ($updatedContent[$i] -match "# Version.*Professional.*Edition") {
                $updatedContent[$i] = $updatedContent[$i] -replace "Professional.*Edition", "Professional DoD-Compliant Edition"
                break
            }
        }
        $updatedContent | Set-Content -Path $FilePath
        
    } catch {
        Write-Host "  [ERROR] Failed to add DoD warnings: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-DoDWarnings {
    param([string]$FilePath)
    
    Write-Host "Removing DoD warnings from: $FilePath" -ForegroundColor Cyan
    
    if (-not (Test-HasDoDWarnings -FilePath $FilePath)) {
        Write-Host "  [SKIP] No DoD warnings found" -ForegroundColor Yellow
        return
    }
    
    try {
        $content = Get-Content -Path $FilePath
        $newContent = @()
        $skipMode = $false
        
        foreach ($line in $content) {
            # Skip DoD function blocks
            if ($line -match "=== DoD COMPLIANCE FUNCTIONS ===") {
                $skipMode = $true
                continue
            }
            if ($line -match "=== END DoD COMPLIANCE FUNCTIONS ===") {
                $skipMode = $false
                continue
            }
            
            # Skip DoD warning calls
            if ($line -match "Show-DoDWarning" -or $line -match "# DoD Compliance Warning") {
                continue
            }
            
            if (-not $skipMode) {
                $newContent += $line
            }
        }
        
        # Write cleaned content
        $newContent | Set-Content -Path $FilePath
        Write-Host "  [SUCCESS] DoD warnings removed" -ForegroundColor Green
        
        # Restore original version info
        $updatedContent = Get-Content -Path $FilePath
        for ($i = 0; $i -lt $updatedContent.Count; $i++) {
            if ($updatedContent[$i] -match "# Version.*DoD-Compliant.*Edition") {
                $updatedContent[$i] = $updatedContent[$i] -replace "DoD-Compliant.*Edition", "Professional Enterprise Edition"
                break
            }
        }
        $updatedContent | Set-Content -Path $FilePath
        
    } catch {
        Write-Host "  [ERROR] Failed to remove DoD warnings: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function List-Scripts {
    Write-Host ""
    Write-Host "PowerShell Scripts in Current Directory:" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    
    $scripts = Get-PowerShellScripts
    
    if ($scripts.Count -eq 0) {
        Write-Host "No PowerShell scripts found." -ForegroundColor Yellow
        return
    }
    
    foreach ($script in $scripts) {
        $hasDoD = Test-HasDoDWarnings -FilePath $script.FullName
        $status = if ($hasDoD) { "[DoD]" } else { "[STD]" }
        $statusColor = if ($hasDoD) { "Green" } else { "White" }
        
        Write-Host "  $status " -ForegroundColor $statusColor -NoNewline
        Write-Host "$($script.Name)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Legend:" -ForegroundColor Gray
    Write-Host "  [DoD] - Has DoD compliance warnings" -ForegroundColor Green
    Write-Host "  [STD] - Standard version without DoD warnings" -ForegroundColor White
    Write-Host ""
}

# Main execution
if ($ListScripts) {
    List-Scripts
    exit 0
}

if (-not $TargetScript -and -not $AllScripts) {
    Show-Usage
    exit 1
}

Write-Host ""
Write-Host "DoDify Script - DoD Compliance Enhancement" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($AllScripts) {
    $scripts = Get-PowerShellScripts
    
    if ($scripts.Count -eq 0) {
        Write-Host "No PowerShell scripts found to process." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Found $($scripts.Count) PowerShell scripts to process:" -ForegroundColor Yellow
    foreach ($script in $scripts) {
        Write-Host "  - $($script.Name)" -ForegroundColor White
    }
    Write-Host ""
    
    $confirm = Read-Host "Continue with processing all scripts? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    foreach ($script in $scripts) {
        if ($RemoveWarnings) {
            Remove-DoDWarnings -FilePath $script.FullName
        } else {
            Add-DoDWarnings -FilePath $script.FullName
        }
    }
} else {
    if (-not (Test-Path $TargetScript)) {
        Write-Host "Error: Script '$TargetScript' not found." -ForegroundColor Red
        exit 1
    }
    
    if ($RemoveWarnings) {
        Remove-DoDWarnings -FilePath $TargetScript
    } else {
        Add-DoDWarnings -FilePath $TargetScript
    }
}

Write-Host ""
Write-Host "DoDify operation completed!" -ForegroundColor Green
Write-Host ""