# VMware vCenter Password Management Tool - Modular Launcher
# Version 1.0 - Professional DoD-Compliant Edition
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Developed with assistance from Qodo AI
# Purpose: Launch individual tools or full GUI with lazy loading
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

param(
    [string]$Tool,           # Launch specific tool: CLI, Config, Password, GitHub, Logs
    [switch]$LazyLoad,       # Enable lazy loading for full GUI
    [switch]$List            # List available tools
)

# Import common functions
. "$PSScriptRoot\Tools\Common.ps1"

function Show-AvailableTools {
    Write-Host ""
    Write-Host "VMware vCenter Password Management Tool - Modular Edition" -ForegroundColor Green
    Write-Host "Available Tools:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Individual Tools (Fast Startup):" -ForegroundColor Yellow
    Write-Host "  CLI        - PowerCLI Command Workspace (Interactive Terminal)" -ForegroundColor White
    Write-Host "  Config     - Configuration Manager (Hosts & Users Editor)" -ForegroundColor White
    Write-Host "  Host       - Host Manager (Create/List/Delete Hosts)" -ForegroundColor White
    Write-Host "  Password   - Password Management Operations" -ForegroundColor White
    Write-Host "  GitHub     - GitHub Repository Manager" -ForegroundColor White
    Write-Host "  Logs       - Log Viewer and Export" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  .\VMware-Password-Manager-Modular.ps1 -Tool CLI" -ForegroundColor Gray
    Write-Host "  .\VMware-Password-Manager-Modular.ps1 -Tool Config" -ForegroundColor Gray
    Write-Host "  .\VMware-Password-Manager-Modular.ps1 -Tool Host" -ForegroundColor Gray
    Write-Host "  .\VMware-Password-Manager-Modular.ps1 -LazyLoad" -ForegroundColor Gray
    Write-Host "  .\VMware-Password-Manager-Modular.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Direct Tool Access:" -ForegroundColor Yellow
    Write-Host "  .\Tools\CLIWorkspace.ps1" -ForegroundColor Gray
    Write-Host "  .\Tools\Configuration.ps1" -ForegroundColor Gray
    Write-Host "  .\Tools\HostManager.ps1" -ForegroundColor Gray
    Write-Host ""
}

function Start-IndividualTool {
    param([string]$ToolName)
    
    $toolPath = ""
    $toolDescription = ""
    
    switch ($ToolName.ToLower()) {
        "cli" { 
            $toolPath = Join-Path $PSScriptRoot "Tools\CLIWorkspace.ps1"
            $toolDescription = "PowerCLI Command Workspace"
        }
        "config" { 
            $toolPath = Join-Path $PSScriptRoot "Tools\Configuration.ps1"
            $toolDescription = "Configuration Manager"
        }
        "host" { 
            $toolPath = Join-Path $PSScriptRoot "Tools\HostManager.ps1"
            $toolDescription = "Host Manager"
        }
        "password" { 
            Write-Host "Password Management tool not yet modularized. Use full GUI for now." -ForegroundColor Yellow
            Start-FullGUI
            return
        }
        "github" { 
            Write-Host "GitHub Manager tool not yet modularized. Use full GUI for now." -ForegroundColor Yellow
            Start-FullGUI
            return
        }
        "logs" { 
            Write-Host "Logs tool not yet modularized. Use full GUI for now." -ForegroundColor Yellow
            Start-FullGUI
            return
        }
        default {
            Write-Host "Unknown tool: $ToolName" -ForegroundColor Red
            Show-AvailableTools
            return
        }
    }
    
    if ($toolPath -and (Test-Path $toolPath)) {
        Write-Host "Starting $toolDescription..." -ForegroundColor Green
        & $toolPath
    } else {
        Write-Host "Tool not found: $toolPath" -ForegroundColor Red
    }
}

function Start-FullGUI {
    Write-Host "Starting Full GUI Application..." -ForegroundColor Green
    $fullGUIPath = Join-Path $PSScriptRoot "VMware-Password-Manager.ps1"
    
    if (Test-Path $fullGUIPath) {
        & $fullGUIPath
    } else {
        Write-Host "Full GUI application not found: $fullGUIPath" -ForegroundColor Red
        Write-Host "Please ensure VMware-Password-Manager.ps1 exists in the same directory." -ForegroundColor Yellow
    }
}

function Start-LazyLoadGUI {
    Write-Host "Lazy Load GUI not yet implemented. Starting Full GUI..." -ForegroundColor Yellow
    Start-FullGUI
}

# Main execution logic
try {
    if ($List) {
        Show-AvailableTools
        return
    }
    
    if ($Tool) {
        Start-IndividualTool -ToolName $Tool
    } elseif ($LazyLoad) {
        Start-LazyLoadGUI
    } else {
        # Default behavior - show options
        Write-Host ""
        Write-Host "VMware vCenter Password Management Tool - Modular Launcher" -ForegroundColor Green
        Write-Host ""
        Write-Host "Choose an option:" -ForegroundColor Cyan
        Write-Host "1. CLI Workspace (Fast)" -ForegroundColor White
        Write-Host "2. Configuration Manager (Fast)" -ForegroundColor White
        Write-Host "3. Host Manager (Fast)" -ForegroundColor White
        Write-Host "4. Full GUI Application" -ForegroundColor White
        Write-Host "5. List all available tools" -ForegroundColor White
        Write-Host "6. Exit" -ForegroundColor White
        Write-Host ""
        
        do {
            $choice = Read-Host "Enter your choice (1-6)"
            
            switch ($choice) {
                "1" { Start-IndividualTool -ToolName "CLI"; break }
                "2" { Start-IndividualTool -ToolName "Config"; break }
                "3" { Start-IndividualTool -ToolName "Host"; break }
                "4" { Start-FullGUI; break }
                "5" { Show-AvailableTools; break }
                "6" { Write-Host "Goodbye!" -ForegroundColor Green; break }
                default { Write-Host "Invalid choice. Please enter 1-6." -ForegroundColor Red }
            }
        } while ($choice -notin @("1", "2", "3", "4", "5", "6"))
    }
} catch {
    $errorMessage = "Critical error in modular launcher: $($_.Exception.Message)"
    Write-Host $errorMessage -ForegroundColor Red
    
    # Try to show error dialog if Windows Forms is available
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Modular Launcher Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } catch {
        Write-Host "Could not display error dialog: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    exit 1
}