# VMware Repository Agent - Automated Command Execution System
# Version 1.0 - Automated Agent System
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Purpose: Monitor GitHub for .test file and execute commands automatically
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

param(
    [Parameter(Mandatory=$false)]
    [switch]$Install,
    
    [Parameter(Mandatory=$false)]
    [switch]$Uninstall,
    
    [Parameter(Mandatory=$false)]
    [switch]$Status,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunOnce,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "VMware-Agent.log"
)

# Configuration
$script:GitHubTestUrl = "https://raw.githubusercontent.com/alumbrados3579/VMware-Vcenter-Password-Management/main/.test"
$script:ForgejoTestUrl = "https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management/raw/branch/main/.test"
$script:TaskName = "VMware-Agent-Monitor"
$script:ScriptPath = $PSCommandPath
$script:WorkingDirectory = $PSScriptRoot

function Write-AgentLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console if running interactively
    if ([Environment]::UserInteractive) {
        switch ($Level) {
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "COMMAND" { Write-Host $logEntry -ForegroundColor Cyan }
            default { Write-Host $logEntry -ForegroundColor White }
        }
    }
    
    # Always write to log file
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Silent fail for logging
    }
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-TestFileContent {
    param([string]$Url)
    
    try {
        Write-AgentLog "Checking for test file at: $Url"
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        
        if ($response.StatusCode -eq 200 -and $response.Content.Trim() -ne "") {
            Write-AgentLog "Test file found with content" "SUCCESS"
            return $response.Content.Trim()
        } else {
            Write-AgentLog "Test file empty or not found"
            return $null
        }
    } catch {
        if ($_.Exception.Message -like "*404*") {
            Write-AgentLog "Test file not found (404) - normal condition"
        } else {
            Write-AgentLog "Error accessing test file: $($_.Exception.Message)" "WARNING"
        }
        return $null
    }
}

function Execute-Commands {
    param([string]$Commands)
    
    Write-AgentLog "Executing commands from test file" "COMMAND"
    
    # Split commands by lines and process each
    $commandLines = $Commands -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
    
    foreach ($command in $commandLines) {
        Write-AgentLog "Executing: $command" "COMMAND"
        
        try {
            # Parse command type and parameters
            if ($command -match "^UPDATE-REPO\s+(.+)") {
                $repoType = $matches[1].Trim()
                Update-Repository -RepoType $repoType
            }
            elseif ($command -match "^DOWNLOAD-FILE\s+(.+)\s+(.+)") {
                $sourceUrl = $matches[1].Trim()
                $targetPath = $matches[2].Trim()
                Download-File -SourceUrl $sourceUrl -TargetPath $targetPath
            }
            elseif ($command -match "^RUN-SCRIPT\s+(.+)") {
                $scriptPath = $matches[1].Trim()
                Run-Script -ScriptPath $scriptPath
            }
            elseif ($command -match "^DODIFY\s+(.+)") {
                $target = $matches[1].Trim()
                Run-DoDify -Target $target
            }
            elseif ($command -match "^DEBADGE\s+(.+)") {
                $target = $matches[1].Trim()
                Run-Debadge -Target $target
            }
            elseif ($command -match "^GIT-COMMIT\s+(.+)") {
                $message = $matches[1].Trim()
                Git-Commit -Message $message
            }
            elseif ($command -match "^GIT-PUSH\s+(.+)") {
                $remote = $matches[1].Trim()
                Git-Push -Remote $remote
            }
            elseif ($command -match "^POWERSHELL\s+(.+)") {
                $psCommand = $matches[1].Trim()
                Invoke-Expression $psCommand
                Write-AgentLog "PowerShell command executed successfully" "SUCCESS"
            }
            else {
                Write-AgentLog "Unknown command format: $command" "WARNING"
            }
        } catch {
            Write-AgentLog "Error executing command '$command': $($_.Exception.Message)" "ERROR"
        }
    }
}

function Update-Repository {
    param([string]$RepoType)
    
    Write-AgentLog "Updating repository: $RepoType" "COMMAND"
    
    try {
        switch ($RepoType.ToUpper()) {
            "GITHUB" {
                git remote set-url origin "https://github.com/alumbrados3579/VMware-Vcenter-Password-Management.git"
                git pull origin main
                Write-AgentLog "GitHub repository updated" "SUCCESS"
            }
            "FORGEJO" {
                git remote set-url forgejo "https://v12.next.forgejo.org/alumbrados3579/VMware-Vcenter-Password-Management.git"
                git pull forgejo main
                Write-AgentLog "Forgejo repository updated" "SUCCESS"
            }
            default {
                Write-AgentLog "Unknown repository type: $RepoType" "ERROR"
            }
        }
    } catch {
        Write-AgentLog "Error updating repository: $($_.Exception.Message)" "ERROR"
    }
}

function Download-File {
    param([string]$SourceUrl, [string]$TargetPath)
    
    Write-AgentLog "Downloading: $SourceUrl -> $TargetPath" "COMMAND"
    
    try {
        $targetDir = Split-Path $TargetPath -Parent
        if ($targetDir -and -not (Test-Path $targetDir)) {
            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        }
        
        Invoke-WebRequest -Uri $SourceUrl -OutFile $TargetPath -UseBasicParsing
        Write-AgentLog "File downloaded successfully" "SUCCESS"
    } catch {
        Write-AgentLog "Error downloading file: $($_.Exception.Message)" "ERROR"
    }
}

function Run-Script {
    param([string]$ScriptPath)
    
    Write-AgentLog "Running script: $ScriptPath" "COMMAND"
    
    try {
        if (Test-Path $ScriptPath) {
            & $ScriptPath
            Write-AgentLog "Script executed successfully" "SUCCESS"
        } else {
            Write-AgentLog "Script not found: $ScriptPath" "ERROR"
        }
    } catch {
        Write-AgentLog "Error running script: $($_.Exception.Message)" "ERROR"
    }
}

function Run-DoDify {
    param([string]$Target)
    
    Write-AgentLog "Running DoDify on: $Target" "COMMAND"
    
    try {
        if (Test-Path "DoDify.ps1") {
            if ($Target -eq "ALL") {
                & ".\DoDify.ps1" -AllScripts
            } else {
                & ".\DoDify.ps1" -TargetScript $Target
            }
            Write-AgentLog "DoDify completed successfully" "SUCCESS"
        } else {
            Write-AgentLog "DoDify.ps1 not found" "ERROR"
        }
    } catch {
        Write-AgentLog "Error running DoDify: $($_.Exception.Message)" "ERROR"
    }
}

function Run-Debadge {
    param([string]$Target)
    
    Write-AgentLog "Running Debadge on: $Target" "COMMAND"
    
    try {
        if (Test-Path "DoDify.ps1") {
            if ($Target -eq "ALL") {
                & ".\DoDify.ps1" -AllScripts -RemoveWarnings
            } else {
                & ".\DoDify.ps1" -TargetScript $Target -RemoveWarnings
            }
            Write-AgentLog "Debadge completed successfully" "SUCCESS"
        } else {
            Write-AgentLog "DoDify.ps1 not found" "ERROR"
        }
    } catch {
        Write-AgentLog "Error running Debadge: $($_.Exception.Message)" "ERROR"
    }
}

function Git-Commit {
    param([string]$Message)
    
    Write-AgentLog "Git commit with message: $Message" "COMMAND"
    
    try {
        git add .
        git commit -m $Message
        Write-AgentLog "Git commit completed" "SUCCESS"
    } catch {
        Write-AgentLog "Error with git commit: $($_.Exception.Message)" "ERROR"
    }
}

function Git-Push {
    param([string]$Remote)
    
    Write-AgentLog "Git push to: $Remote" "COMMAND"
    
    try {
        git push $Remote main
        Write-AgentLog "Git push completed" "SUCCESS"
    } catch {
        Write-AgentLog "Error with git push: $($_.Exception.Message)" "ERROR"
    }
}

function Clear-TestFile {
    param([string]$Url)
    
    Write-AgentLog "Test file processing complete - commands executed"
    # Note: In a real implementation, you might want to clear the test file
    # This would require write access to the repository
}

function Monitor-TestFile {
    Write-AgentLog "Starting VMware Agent monitoring session"
    Write-AgentLog "Monitoring URLs:"
    Write-AgentLog "  GitHub: $script:GitHubTestUrl"
    Write-AgentLog "  Forgejo: $script:ForgejoTestUrl"
    
    while ($true) {
        try {
            # Check GitHub first
            $commands = Get-TestFileContent -Url $script:GitHubTestUrl
            
            # If GitHub doesn't have commands, check Forgejo
            if (-not $commands) {
                $commands = Get-TestFileContent -Url $script:ForgejoTestUrl
            }
            
            if ($commands) {
                Write-AgentLog "Commands found in test file" "SUCCESS"
                Execute-Commands -Commands $commands
                Write-AgentLog "Command execution cycle completed"
            }
            
            # Wait 15 minutes before next check
            Start-Sleep -Seconds 900
            
        } catch {
            Write-AgentLog "Error in monitoring loop: $($_.Exception.Message)" "ERROR"
            Start-Sleep -Seconds 60  # Wait 1 minute on error before retrying
        }
    }
}

function Install-Agent {
    if (-not (Test-AdminPrivileges)) {
        Write-AgentLog "Administrator privileges required for installation" "ERROR"
        exit 1
    }
    
    Write-AgentLog "Installing VMware Agent as scheduled task"
    
    try {
        # Create scheduled task
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script:ScriptPath`" -RunOnce" -WorkingDirectory $script:WorkingDirectory
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 365)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
        
        Register-ScheduledTask -TaskName $script:TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        
        Write-AgentLog "VMware Agent installed successfully" "SUCCESS"
        Write-AgentLog "Task will run every 15 minutes to check for commands"
        
    } catch {
        Write-AgentLog "Error installing agent: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

function Uninstall-Agent {
    if (-not (Test-AdminPrivileges)) {
        Write-AgentLog "Administrator privileges required for uninstallation" "ERROR"
        exit 1
    }
    
    Write-AgentLog "Uninstalling VMware Agent"
    
    try {
        Unregister-ScheduledTask -TaskName $script:TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-AgentLog "VMware Agent uninstalled successfully" "SUCCESS"
    } catch {
        Write-AgentLog "Error uninstalling agent: $($_.Exception.Message)" "ERROR"
    }
}

function Show-Status {
    Write-AgentLog "VMware Agent Status Check"
    
    try {
        $task = Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
        
        if ($task) {
            Write-AgentLog "Agent Status: INSTALLED" "SUCCESS"
            Write-AgentLog "Task State: $($task.State)"
            Write-AgentLog "Last Run: $($task.LastRunTime)"
            Write-AgentLog "Next Run: $($task.NextRunTime)"
        } else {
            Write-AgentLog "Agent Status: NOT INSTALLED" "WARNING"
        }
        
        # Check log file
        if (Test-Path $LogPath) {
            $logSize = (Get-Item $LogPath).Length
            Write-AgentLog "Log File: $LogPath ($logSize bytes)"
        } else {
            Write-AgentLog "Log File: Not found"
        }
        
    } catch {
        Write-AgentLog "Error checking status: $($_.Exception.Message)" "ERROR"
    }
}

function Show-Usage {
    Write-Host ""
    Write-Host "VMware Repository Agent - Automated Command Execution" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\VMware-Agent.ps1 -Install      # Install agent as scheduled task"
    Write-Host "  .\VMware-Agent.ps1 -Uninstall    # Remove agent scheduled task"
    Write-Host "  .\VMware-Agent.ps1 -Status       # Show agent status"
    Write-Host "  .\VMware-Agent.ps1 -RunOnce      # Run monitoring once (for testing)"
    Write-Host ""
    Write-Host "Supported Commands in .test file:" -ForegroundColor Green
    Write-Host "  UPDATE-REPO GITHUB              # Update from GitHub"
    Write-Host "  UPDATE-REPO FORGEJO             # Update from Forgejo"
    Write-Host "  DOWNLOAD-FILE <url> <path>      # Download file"
    Write-Host "  RUN-SCRIPT <path>               # Execute PowerShell script"
    Write-Host "  DODIFY <script|ALL>             # Add DoD warnings"
    Write-Host "  DEBADGE <script|ALL>            # Remove DoD warnings"
    Write-Host "  GIT-COMMIT <message>            # Git commit with message"
    Write-Host "  GIT-PUSH <remote>               # Git push to remote"
    Write-Host "  POWERSHELL <command>            # Execute PowerShell command"
    Write-Host ""
    Write-Host "Example .test file content:" -ForegroundColor Cyan
    Write-Host "  # Update repository and commit changes"
    Write-Host "  UPDATE-REPO FORGEJO"
    Write-Host "  DODIFY VMware-Setup.ps1"
    Write-Host "  GIT-COMMIT 'agent: Add DoD compliance to setup script'"
    Write-Host "  GIT-PUSH origin"
    Write-Host ""
}

# Main execution
Write-AgentLog "VMware Agent started with parameters: $($PSBoundParameters.Keys -join ', ')"

if ($Install) {
    Install-Agent
} elseif ($Uninstall) {
    Uninstall-Agent
} elseif ($Status) {
    Show-Status
} elseif ($RunOnce) {
    Write-AgentLog "Running single monitoring cycle"
    
    # Check both repositories once
    $commands = Get-TestFileContent -Url $script:GitHubTestUrl
    if (-not $commands) {
        $commands = Get-TestFileContent -Url $script:ForgejoTestUrl
    }
    
    if ($commands) {
        Execute-Commands -Commands $commands
    } else {
        Write-AgentLog "No commands found in test files"
    }
} else {
    Show-Usage
}

Write-AgentLog "VMware Agent session completed"