# VMware vCenter Password Management Tool - Test Startup Script
# Version 0.5 BETA - Quick Test Launch
# Purpose: Quick test launch without full setup for development/testing

# Global error handling
$ErrorActionPreference = "Continue"
trap {
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

function Show-TestWarning {
    Clear-Host
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host "*** TEST MODE - VMware Password Management Tool ***" -ForegroundColor Cyan
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This is a TEST STARTUP SCRIPT for development and testing purposes." -ForegroundColor White
    Write-Host "It bypasses the full setup process and launches the GUI directly." -ForegroundColor White
    Write-Host ""
    Write-Host "Requirements:" -ForegroundColor Yellow
    Write-Host "- VMware PowerCLI must already be installed" -ForegroundColor Cyan
    Write-Host "- Configuration files (hosts.txt, users.txt) should exist" -ForegroundColor Cyan
    Write-Host "- This is for testing only - use VMware-Setup.ps1 for production" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "VMware vCenter Password Management Tool - Version 0.5 BETA Test Mode" -ForegroundColor Green
    Write-Host ('=' * 80) -ForegroundColor Yellow
    Write-Host ""
    $acknowledge = Read-Host "Type 'TEST' to continue with test launch"
    if ($acknowledge -ne "TEST") {
        Write-Host "Test launch cancelled by user" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

function Test-QuickPowerCLI {
    Write-Host "Checking PowerCLI availability..." -ForegroundColor Cyan
    
    try {
        # Quick check for PowerCLI
        $powerCLI = Get-Module -Name "VMware.PowerCLI" -ListAvailable -ErrorAction SilentlyContinue
        if (-not $powerCLI) {
            Write-Host "[WARNING] VMware PowerCLI not found" -ForegroundColor Yellow
            Write-Host "Please run VMware-Setup.ps1 first to install PowerCLI" -ForegroundColor Yellow
            $continue = Read-Host "Continue anyway? (Y/N)"
            if ($continue -ne "Y" -and $continue -ne "y") {
                exit 1
            }
        } else {
            Write-Host "[SUCCESS] PowerCLI found - Version: $($powerCLI.Version)" -ForegroundColor Green
        }
        
        return $true
    } catch {
        Write-Host "[ERROR] Error checking PowerCLI: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Launch-TestApplication {
    Write-Host "Launching VMware Password Manager in TEST MODE..." -ForegroundColor Green
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $mainTool = Join-Path $scriptRoot "VMware-Password-Manager.ps1"
    
    if (Test-Path $mainTool) {
        Write-Host "Starting application..." -ForegroundColor Green
        & $mainTool
    } else {
        Write-Host "[ERROR] Main application file not found: $mainTool" -ForegroundColor Red
        Write-Host "Please ensure VMware-Password-Manager.ps1 is in the same directory" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Main execution
Show-TestWarning
Test-QuickPowerCLI
Launch-TestApplication