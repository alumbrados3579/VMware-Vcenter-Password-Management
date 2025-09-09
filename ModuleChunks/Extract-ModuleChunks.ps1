#Requires -Version 5.1

<#
.SYNOPSIS
    Extracts VMware PowerCLI module chunks back to the original directory structure.

.DESCRIPTION
    This script extracts all VMware PowerCLI module chunk zip files and recreates
    the original Modules directory structure.

.PARAMETER ChunksPath
    Path containing the chunk zip files. Defaults to current directory.

.PARAMETER OutputPath
    Path where modules will be extracted. Defaults to ".\Modules"

.EXAMPLE
    .\Extract-ModuleChunks.ps1
    
.EXAMPLE
    .\Extract-ModuleChunks.ps1 -ChunksPath ".\Downloads" -OutputPath ".\ExtractedModules"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ChunksPath = ".",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Modules"
)

Write-Host "VMware PowerCLI Modules Extraction Tool" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Find all chunk files
$chunkFiles = Get-ChildItem -Path $ChunksPath -Filter "VMware-PowerCLI-Modules-Chunk-*.zip" | Sort-Object Name

if ($chunkFiles.Count -eq 0) {
    throw "No chunk files found in: $ChunksPath"
}

Write-Host "Found $($chunkFiles.Count) chunk files" -ForegroundColor Green

# Create output directory
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Extract each chunk
foreach ($chunkFile in $chunkFiles) {
    Write-Host "Extracting $($chunkFile.Name)..." -ForegroundColor Yellow
    
    try {
        Expand-Archive -Path $chunkFile.FullName -DestinationPath $OutputPath -Force
        Write-Host "  Extracted successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to extract $($chunkFile.Name): $($_.Exception.Message)"
    }
}

Write-Host "
Extraction complete!" -ForegroundColor Green
Write-Host "Modules extracted to: $OutputPath" -ForegroundColor Green

# Verify VMware.PowerCLI.psd1 exists
$psd1Path = Join-Path $OutputPath "VMware.PowerCLI\VMware.PowerCLI.psd1"
if (Test-Path $psd1Path) {
    Write-Host "VMware.PowerCLI.psd1 found at: $psd1Path" -ForegroundColor Green
}
else {
    Write-Warning "VMware.PowerCLI.psd1 not found at expected location: $psd1Path"
}
