#Requires -Version 5.1

<#
.SYNOPSIS
    Tests and analyzes the VMware PowerCLI Modules directory structure.

.DESCRIPTION
    This script performs a comprehensive analysis of the Modules directory to ensure
    it's properly structured for the chunking process. It verifies the presence of
    key files and provides detailed information about the module structure.

.PARAMETER ModulesPath
    Path to the Modules directory. Defaults to "./Modules"

.EXAMPLE
    .\Test-ModulesStructure.ps1
    
.EXAMPLE
    .\Test-ModulesStructure.ps1 -ModulesPath ".\Modules"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ModulesPath = ".\Modules"
)

# Function to format file sizes
function Format-FileSize {
    param([long]$Size)
    
    if ($Size -gt 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    }
    elseif ($Size -gt 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    }
    elseif ($Size -gt 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
    else {
        return "$Size bytes"
    }
}

# Function to safely get directory size
function Get-SafeDirectorySize {
    param([string]$Path)
    
    try {
        $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        return @{
            Size = [long]$size
            FileCount = $files.Count
            Success = $true
        }
    }
    catch {
        return @{
            Size = 0
            FileCount = 0
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

Write-Host "VMware PowerCLI Modules Structure Analysis" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Validate input path
if (!(Test-Path $ModulesPath)) {
    Write-Error "Modules path not found: $ModulesPath"
    exit 1
}

$ModulesPath = Resolve-Path $ModulesPath
Write-Host "Analyzing: $ModulesPath" -ForegroundColor Green

# Check for VMware.PowerCLI directory directly in Modules
$vmwarePowerCLIPath = Join-Path $ModulesPath "VMware.PowerCLI"
if (!(Test-Path $vmwarePowerCLIPath)) {
    Write-Error "VMware.PowerCLI directory not found at: $vmwarePowerCLIPath"
    exit 1
}

Write-Host "✓ Found VMware.PowerCLI directory" -ForegroundColor Green

# Look for the main PowerCLI manifest file
Write-Host "`nSearching for VMware.PowerCLI.psd1..." -ForegroundColor Yellow

$psd1Files = @()
try {
    $psd1Files = Get-ChildItem -Path $vmwarePowerCLIPath -Filter "*.psd1" -Recurse -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Error searching for .psd1 files: $($_.Exception.Message)"
}

$mainPsd1 = $psd1Files | Where-Object { $_.Name -eq "VMware.PowerCLI.psd1" } | Select-Object -First 1

if ($mainPsd1) {
    Write-Host "✓ Found VMware.PowerCLI.psd1 at:" -ForegroundColor Green
    Write-Host "  $($mainPsd1.FullName)" -ForegroundColor Gray
    
    # Try to read the manifest file
    try {
        $manifestContent = Get-Content -Path $mainPsd1.FullName -Raw -ErrorAction SilentlyContinue
        if ($manifestContent) {
            Write-Host "✓ Manifest file is readable" -ForegroundColor Green
            
            # Extract version information if possible
            if ($manifestContent -match 'ModuleVersion.*?=.*?[''""](.*?)[''""]\') {
                Write-Host "  Version: $($matches[1])" -ForegroundColor Gray
            }
            
            if ($manifestContent -match 'Author.*?=.*?[''""](.*?)[''""]\')
            {
                Write-Host "  Author: $($matches[1])" -ForegroundColor Gray
            }
        }
        else {
            Write-Warning "Manifest file exists but could not be read"
        }
    }
    catch {
        Write-Warning "Could not read manifest file: $($_.Exception.Message)"
    }
}
else {
    Write-Warning "VMware.PowerCLI.psd1 not found or not accessible"
    
    # List all .psd1 files found
    if ($psd1Files.Count -gt 0) {
        Write-Host "Found other .psd1 files:" -ForegroundColor Yellow
        foreach ($psd1 in $psd1Files) {
            Write-Host "  $($psd1.Name) - $($psd1.DirectoryName)" -ForegroundColor Gray
        }
    }
}

# Analyze module directories
Write-Host "`nAnalyzing module directories..." -ForegroundColor Yellow

try {
    $moduleDirectories = Get-ChildItem -Path $ModulesPath -Directory -ErrorAction SilentlyContinue | 
                        Sort-Object Name
    
    Write-Host "Found $($moduleDirectories.Count) module directories:" -ForegroundColor Green
    
    $totalSize = 0
    $totalFiles = 0
    $accessibleModules = 0
    $inaccessibleModules = 0
    
    foreach ($moduleDir in $moduleDirectories) {
        $sizeInfo = Get-SafeDirectorySize -Path $moduleDir.FullName
        
        if ($sizeInfo.Success) {
            $totalSize += $sizeInfo.Size
            $totalFiles += $sizeInfo.FileCount
            $accessibleModules++
            
            Write-Host "  ✓ $($moduleDir.Name)" -ForegroundColor Green
            Write-Host "    Size: $(Format-FileSize $sizeInfo.Size), Files: $($sizeInfo.FileCount)" -ForegroundColor Gray
        }
        else {
            $inaccessibleModules++
            Write-Host "  ✗ $($moduleDir.Name)" -ForegroundColor Red
            Write-Host "    Error: $($sizeInfo.Error)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total Directories: $($moduleDirectories.Count)" -ForegroundColor Gray
    Write-Host "  Accessible: $accessibleModules" -ForegroundColor Green
    Write-Host "  Inaccessible: $inaccessibleModules" -ForegroundColor $(if ($inaccessibleModules -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "  Total Size: $(Format-FileSize $totalSize)" -ForegroundColor Gray
    Write-Host "  Total Files: $totalFiles" -ForegroundColor Gray
    
    # Estimate number of chunks needed
    $maxChunkSizeMB = 95
    $maxChunkSizeBytes = $maxChunkSizeMB * 1MB
    $estimatedChunks = [Math]::Ceiling($totalSize / $maxChunkSizeBytes)
    
    Write-Host "`nChunking Estimates:" -ForegroundColor Cyan
    Write-Host "  Max Chunk Size: $maxChunkSizeMB MB" -ForegroundColor Gray
    Write-Host "  Estimated Chunks: $estimatedChunks" -ForegroundColor Gray
    Write-Host "  Avg Chunk Size: $(Format-FileSize ($totalSize / $estimatedChunks))" -ForegroundColor Gray
}
catch {
    Write-Error "Error analyzing module directories: $($_.Exception.Message)"
}

# Check for common PowerShell module files
Write-Host "`nChecking for common PowerShell module files..." -ForegroundColor Yellow

$commonFiles = @(
    "*.psd1",  # Module manifest
    "*.psm1",  # Module script
    "*.ps1",   # PowerShell scripts
    "*.dll",   # Compiled assemblies
    "*.xml",   # Help files
    "*.txt"    # Documentation
)

foreach ($pattern in $commonFiles) {
    try {
        $files = Get-ChildItem -Path $ModulesPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) {
            Write-Host "  ✓ $pattern files: $($files.Count)" -ForegroundColor Green
        }
        else {
            Write-Host "  - $pattern files: 0" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  ✗ $pattern files: Error accessing" -ForegroundColor Red
    }
}

# Check directory permissions
Write-Host "`nChecking directory permissions..." -ForegroundColor Yellow

try {
    $acl = Get-Acl -Path $ModulesPath -ErrorAction SilentlyContinue
    if ($acl) {
        Write-Host "✓ Can read directory permissions" -ForegroundColor Green
        
        # Check if we can list contents
        $canList = $true
        try {
            Get-ChildItem -Path $ModulesPath -ErrorAction Stop | Out-Null
        }
        catch {
            $canList = $false
        }
        
        Write-Host "  Can list contents: $canList" -ForegroundColor $(if ($canList) { 'Green' } else { 'Red' })
    }
    else {
        Write-Warning "Cannot read directory permissions"
    }
}
catch {
    Write-Warning "Error checking permissions: $($_.Exception.Message)"
}

# Final recommendations
Write-Host "`nRecommendations:" -ForegroundColor Cyan

if ($mainPsd1) {
    Write-Host "✓ Ready for chunking - VMware.PowerCLI.psd1 found" -ForegroundColor Green
}
else {
    Write-Host "⚠ VMware.PowerCLI.psd1 not found - verify module structure" -ForegroundColor Yellow
}

if ($inaccessibleModules -gt 0) {
    Write-Host "⚠ Some modules are inaccessible - check file permissions" -ForegroundColor Yellow
    Write-Host "  Consider running as administrator or fixing permissions" -ForegroundColor Gray
}

if ($totalSize -gt 0) {
    Write-Host "✓ Modules directory contains data - ready for chunking" -ForegroundColor Green
    Write-Host "  Run Create-ModuleChunks.ps1 to create GitHub-compliant chunks" -ForegroundColor Gray
}
else {
    Write-Host "✗ No accessible module data found" -ForegroundColor Red
}

Write-Host "`nAnalysis complete!" -ForegroundColor Green