#Requires -Version 5.1

<#
.SYNOPSIS
    Creates GitHub-compliant zip chunks from the VMware PowerCLI Modules directory.

.DESCRIPTION
    This script analyzes the VMware-Vcenter-Password-Management Modules directory and creates
    multiple zip files that comply with GitHub's 100MB file size limit. It ensures that
    the VMware.PowerCLI.psd1 file and all related PowerShell modules are properly packaged
    and documented.

.PARAMETER ModulesPath
    Path to the Modules directory. Defaults to "./Modules"

.PARAMETER OutputPath
    Path where zip chunks will be created. Defaults to "./ModuleChunks"

.PARAMETER MaxChunkSizeMB
    Maximum size for each zip chunk in MB. Defaults to 95MB to stay under GitHub's 100MB limit.

.PARAMETER Force
    Overwrite existing output directory if it exists.

.EXAMPLE
    .\Create-ModuleChunks.ps1
    
.EXAMPLE
    .\Create-ModuleChunks.ps1 -ModulesPath ".\Modules" -OutputPath ".\GitHubChunks" -MaxChunkSizeMB 90

.NOTES
    Author: VMware vCenter Password Management Assistant
    Version: 1.0
    Created: $(Get-Date -Format 'yyyy-MM-dd')
    
    GitHub Limits:
    - Individual file size limit: 100MB
    - Repository size soft limit: 1GB
    - Repository size hard limit: 100GB
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ModulesPath = ".\Modules",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\ModuleChunks",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxChunkSizeMB = 95,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

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

# Function to get directory size
function Get-DirectorySize {
    param([string]$Path)
    
    try {
        $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum
        return [long]$size
    }
    catch {
        Write-Warning "Could not calculate size for: $Path - $($_.Exception.Message)"
        return 0
    }
}

# Function to create zip file
function New-ZipFile {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string[]]$Items
    )
    
    try {
        Write-Host "    Creating zip with $($Items.Count) items..." -ForegroundColor Gray
        
        # Remove existing zip if it exists
        if (Test-Path $DestinationPath) {
            Remove-Item $DestinationPath -Force
        }
        
        # Create temporary directory for this chunk
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "ModuleChunk_$(Get-Random)"
        Write-Host "    Using temp directory: $tempDir" -ForegroundColor Gray
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        # Copy items to temp directory maintaining structure
        $copiedItems = 0
        foreach ($item in $Items) {
            $sourcePath = Join-Path $SourcePath $item
            $destPath = Join-Path $tempDir $item
            
            Write-Host "    Copying: $item" -ForegroundColor Gray
            
            if (Test-Path $sourcePath) {
                try {
                    if (Test-Path $sourcePath -PathType Container) {
                        Copy-Item -Path $sourcePath -Destination $tempDir -Recurse -Force -ErrorAction Stop
                        $copiedItems++
                    }
                    else {
                        $destParent = Split-Path $destPath -Parent
                        if (!(Test-Path $destParent)) {
                            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
                        }
                        Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction Stop
                        $copiedItems++
                    }
                }
                catch {
                    Write-Warning "Failed to copy $item`: $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning "Source path not found: $sourcePath"
            }
        }
        
        Write-Host "    Copied $copiedItems items to temp directory" -ForegroundColor Gray
        
        # Check if temp directory has content
        $tempContents = Get-ChildItem -Path $tempDir -ErrorAction SilentlyContinue
        if ($tempContents.Count -eq 0) {
            throw "No items were copied to temp directory"
        }
        
        # Create zip from temp directory
        Write-Host "    Creating zip file..." -ForegroundColor Gray
        $zipItems = Get-ChildItem -Path $tempDir -ErrorAction Stop
        if ($zipItems.Count -gt 0) {
            Compress-Archive -Path ($zipItems | ForEach-Object { $_.FullName }) -DestinationPath $DestinationPath -CompressionLevel Optimal -ErrorAction Stop
        }
        else {
            throw "No items found in temp directory to zip"
        }
        
        # Verify zip was created
        if (!(Test-Path $DestinationPath)) {
            throw "Zip file was not created: $DestinationPath"
        }
        
        # Clean up temp directory
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        return $true
    }
    catch {
        Write-Error "Failed to create zip file $DestinationPath`: $($_.Exception.Message)"
        # Clean up temp directory on error
        if ($tempDir -and (Test-Path $tempDir)) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
}

# Main script execution
try {
    Write-Host "VMware PowerCLI Modules GitHub Chunking Tool" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    # Validate input path
    if (!(Test-Path $ModulesPath)) {
        throw "Modules path not found: $ModulesPath"
    }
    
    $ModulesPath = Resolve-Path $ModulesPath
    Write-Host "Source Modules Path: $ModulesPath" -ForegroundColor Green
    
    # Create output directory
    if (Test-Path $OutputPath) {
        if ($Force) {
            Remove-Item $OutputPath -Recurse -Force
            Write-Host "Removed existing output directory" -ForegroundColor Yellow
        }
        else {
            throw "Output directory already exists: $OutputPath. Use -Force to overwrite."
        }
    }
    
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    $OutputPath = Resolve-Path $OutputPath
    Write-Host "Output Path: $OutputPath" -ForegroundColor Green
    
    # Analyze the modules directory structure
    Write-Host "`nAnalyzing Modules directory structure..." -ForegroundColor Yellow
    
    $powerCLIPath = Join-Path $ModulesPath "VMware.PowerCLI"
    if (!(Test-Path $powerCLIPath)) {
        throw "VMware.PowerCLI directory not found at expected location: $powerCLIPath"
    }
    
    # Find the main PowerCLI manifest file
    $psd1Files = Get-ChildItem -Path $powerCLIPath -Filter "*.psd1" -Recurse -ErrorAction SilentlyContinue
    $mainPsd1 = $psd1Files | Where-Object { $_.Name -eq "VMware.PowerCLI.psd1" } | Select-Object -First 1
    
    if ($mainPsd1) {
        Write-Host "Found VMware.PowerCLI.psd1 at: $($mainPsd1.FullName)" -ForegroundColor Green
    }
    else {
        Write-Warning "VMware.PowerCLI.psd1 not found or not accessible"
    }
    
    # Get all module directories in the Modules folder
    $moduleDirectories = Get-ChildItem -Path $ModulesPath -Directory -ErrorAction SilentlyContinue | 
                        Sort-Object Name
    
    Write-Host "Found $($moduleDirectories.Count) module directories" -ForegroundColor Green
    
    # Calculate sizes for each module directory
    $moduleSizes = @()
    $totalSize = 0
    
    Write-Host "`nCalculating module sizes..." -ForegroundColor Yellow
    
    foreach ($moduleDir in $moduleDirectories) {
        $size = Get-DirectorySize -Path $moduleDir.FullName
        $totalSize += $size
        
        $moduleInfo = [PSCustomObject]@{
            Name = $moduleDir.Name
            Path = $moduleDir.FullName
            SizeBytes = $size
            SizeFormatted = Format-FileSize $size
            RelativePath = $moduleDir.Name
        }
        
        $moduleSizes += $moduleInfo
        Write-Host "  $($moduleDir.Name): $(Format-FileSize $size)" -ForegroundColor Gray
    }
    
    # Sort modules by size (largest first) for better packing
    $moduleSizes = $moduleSizes | Sort-Object SizeBytes -Descending
    
    Write-Host "`nTotal modules size: $(Format-FileSize $totalSize)" -ForegroundColor Green
    Write-Host "Maximum chunk size: $MaxChunkSizeMB MB" -ForegroundColor Green
    
    # Create chunks using a bin-packing approach
    $maxChunkSizeBytes = $MaxChunkSizeMB * 1MB
    $chunks = @()
    $currentChunk = @{
        Modules = @()
        SizeBytes = 0
        Number = 1
    }
    
    Write-Host "`nCreating chunks..." -ForegroundColor Yellow
    
    foreach ($module in $moduleSizes) {
        # If adding this module would exceed the chunk size, start a new chunk
        if (($currentChunk.SizeBytes + $module.SizeBytes) -gt $maxChunkSizeBytes -and $currentChunk.Modules.Count -gt 0) {
            $chunks += $currentChunk
            $currentChunk = @{
                Modules = @()
                SizeBytes = 0
                Number = $chunks.Count + 1
            }
        }
        
        # Add module to current chunk
        $currentChunk.Modules += $module
        $currentChunk.SizeBytes += $module.SizeBytes
    }
    
    # Add the last chunk if it has modules
    if ($currentChunk.Modules.Count -gt 0) {
        $chunks += $currentChunk
    }
    
    Write-Host "Created $($chunks.Count) chunks" -ForegroundColor Green
    
    # Display chunk information
    Write-Host "`nChunk Summary:" -ForegroundColor Cyan
    foreach ($chunk in $chunks) {
        Write-Host "  Chunk $($chunk.Number): $($chunk.Modules.Count) modules, $(Format-FileSize $chunk.SizeBytes)" -ForegroundColor Gray
    }
    
    # Create zip files for each chunk
    Write-Host "`nCreating zip files..." -ForegroundColor Yellow
    
    $manifest = @()
    $chunkFiles = @()
    
    foreach ($chunk in $chunks) {
        $chunkFileName = "VMware-PowerCLI-Modules-Chunk-{0:D2}.zip" -f $chunk.Number
        $chunkFilePath = Join-Path $OutputPath $chunkFileName
        
        Write-Host "Creating $chunkFileName..." -ForegroundColor Gray
        
        # Prepare items for this chunk (relative paths from Modules directory)
        $chunkItems = $chunk.Modules | ForEach-Object { $_.RelativePath }
        
        # Create the zip file
        $success = New-ZipFile -SourcePath $ModulesPath -DestinationPath $chunkFilePath -Items $chunkItems
        
        if ($success -and (Test-Path $chunkFilePath)) {
            $zipSize = (Get-Item $chunkFilePath).Length
            Write-Host "  Created: $chunkFileName ($(Format-FileSize $zipSize))" -ForegroundColor Green
            
            # Add to manifest
            $chunkInfo = [PSCustomObject]@{
                ChunkNumber = $chunk.Number
                FileName = $chunkFileName
                ModuleCount = $chunk.Modules.Count
                UncompressedSize = Format-FileSize $chunk.SizeBytes
                CompressedSize = Format-FileSize $zipSize
                Modules = ($chunk.Modules | ForEach-Object { $_.Name }) -join ", "
            }
            
            $manifest += $chunkInfo
            $chunkFiles += $chunkFilePath
        }
        else {
            Write-Error "Failed to create chunk: $chunkFileName"
        }
    }
    
    # Create manifest file
    Write-Host "`nCreating manifest file..." -ForegroundColor Yellow
    
    $manifestPath = Join-Path $OutputPath "VMware-PowerCLI-Modules-Manifest.txt"
    $manifestContent = @"
VMware PowerCLI Modules - GitHub Chunk Manifest
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source Path: $ModulesPath
Total Modules: $($moduleSizes.Count)
Total Uncompressed Size: $(Format-FileSize $totalSize)
Chunk Count: $($chunks.Count)
Max Chunk Size: $MaxChunkSizeMB MB

IMPORTANT FILES:
- VMware.PowerCLI.psd1: Main PowerShell module manifest file
- Located in: VMware.PowerCLI\VMware.PowerCLI.psd1

EXTRACTION INSTRUCTIONS:
1. Download all chunk files to the same directory
2. Extract each chunk to recreate the original Modules directory structure
3. Ensure the VMware.PowerCLI.psd1 file is accessible for PowerShell module loading

CHUNK DETAILS:
"@

    foreach ($chunk in $manifest) {
        $manifestContent += @"

Chunk $($chunk.ChunkNumber): $($chunk.FileName)
  Modules: $($chunk.ModuleCount)
  Uncompressed: $($chunk.UncompressedSize)
  Compressed: $($chunk.CompressedSize)
  Contains: $($chunk.Modules)
"@
    }
    
    $manifestContent += @"

MODULE DIRECTORY LISTING:
"@
    
    foreach ($module in ($moduleSizes | Sort-Object Name)) {
        $manifestContent += "`n  $($module.Name) - $($module.SizeFormatted)"
    }
    
    $manifestContent | Out-File -FilePath $manifestPath -Encoding UTF8
    Write-Host "Manifest created: $manifestPath" -ForegroundColor Green
    
    # Create PowerShell extraction script
    Write-Host "Creating extraction script..." -ForegroundColor Yellow
    
    $extractScriptPath = Join-Path $OutputPath "Extract-ModuleChunks.ps1"
    $extractScript = @"
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
    [Parameter(Mandatory = `$false)]
    [string]`$ChunksPath = ".",
    
    [Parameter(Mandatory = `$false)]
    [string]`$OutputPath = ".\Modules"
)

Write-Host "VMware PowerCLI Modules Extraction Tool" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Find all chunk files
`$chunkFiles = Get-ChildItem -Path `$ChunksPath -Filter "VMware-PowerCLI-Modules-Chunk-*.zip" | Sort-Object Name

if (`$chunkFiles.Count -eq 0) {
    throw "No chunk files found in: `$ChunksPath"
}

Write-Host "Found `$(`$chunkFiles.Count) chunk files" -ForegroundColor Green

# Create output directory
if (!(Test-Path `$OutputPath)) {
    New-Item -ItemType Directory -Path `$OutputPath -Force | Out-Null
}

# Extract each chunk
foreach (`$chunkFile in `$chunkFiles) {
    Write-Host "Extracting `$(`$chunkFile.Name)..." -ForegroundColor Yellow
    
    try {
        Expand-Archive -Path `$chunkFile.FullName -DestinationPath `$OutputPath -Force
        Write-Host "  Extracted successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to extract `$(`$chunkFile.Name): `$(`$_.Exception.Message)"
    }
}

Write-Host "`nExtraction complete!" -ForegroundColor Green
Write-Host "Modules extracted to: `$OutputPath" -ForegroundColor Green

# Verify VMware.PowerCLI.psd1 exists
`$psd1Path = Join-Path `$OutputPath "VMware.PowerCLI\VMware.PowerCLI.psd1"
if (Test-Path `$psd1Path) {
    Write-Host "VMware.PowerCLI.psd1 found at: `$psd1Path" -ForegroundColor Green
}
else {
    Write-Warning "VMware.PowerCLI.psd1 not found at expected location: `$psd1Path"
}
"@
    
    $extractScript | Out-File -FilePath $extractScriptPath -Encoding UTF8
    Write-Host "Extraction script created: $extractScriptPath" -ForegroundColor Green
    
    # Create README file
    Write-Host "Creating README file..." -ForegroundColor Yellow
    
    $readmePath = Join-Path $OutputPath "README.md"
    $readmeContent = @"
# VMware PowerCLI Modules - GitHub Chunks

This directory contains the VMware PowerCLI modules split into GitHub-compliant chunks.

## Overview

- **Total Modules**: $($moduleSizes.Count)
- **Total Size**: $(Format-FileSize $totalSize)
- **Chunk Count**: $($chunks.Count)
- **Max Chunk Size**: $MaxChunkSizeMB MB

## Important Files

- **VMware.PowerCLI.psd1**: Main PowerShell module manifest file
- **Location**: `VMware.PowerCLI\VMware.PowerCLI.psd1`

## Files in this Directory

- **VMware-PowerCLI-Modules-Chunk-XX.zip**: Module chunk files
- **VMware-PowerCLI-Modules-Manifest.txt**: Detailed manifest of all chunks
- **Extract-ModuleChunks.ps1**: PowerShell script to extract all chunks
- **README.md**: This file

## Extraction Instructions

### Method 1: Using PowerShell Script (Recommended)
``````powershell
.\Extract-ModuleChunks.ps1
``````

### Method 2: Manual Extraction
1. Create a `Modules` directory
2. Extract each chunk zip file to the `Modules` directory
3. Ensure all files maintain their directory structure

## Usage After Extraction

After extracting the modules, you can import VMware PowerCLI using:

``````powershell
# Navigate to the extracted modules directory
cd .\Modules\VMware.PowerCLI

# Import the module
Import-Module .\VMware.PowerCLI.psd1
``````

## Chunk Details

"@
    
    foreach ($chunk in $manifest) {
        $readmeContent += @"
### Chunk $($chunk.ChunkNumber): $($chunk.FileName)
- **Modules**: $($chunk.ModuleCount)
- **Uncompressed Size**: $($chunk.UncompressedSize)
- **Compressed Size**: $($chunk.CompressedSize)

"@
    }
    
    $readmeContent += @"

## GitHub Compliance

These chunks are created to comply with GitHub's file size limits:
- Individual file size limit: 100MB
- Each chunk is under 95MB to provide a safety margin

## Generated Information

- **Created**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Source**: $ModulesPath
- **Tool**: VMware vCenter Password Management - Module Chunking Tool
"@
    
    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
    Write-Host "README created: $readmePath" -ForegroundColor Green
    
    # Final summary
    Write-Host "`n" + "=" * 50 -ForegroundColor Cyan
    Write-Host "CHUNKING COMPLETE!" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    Write-Host "`nSummary:" -ForegroundColor Yellow
    Write-Host "  Source: $ModulesPath" -ForegroundColor Gray
    Write-Host "  Output: $OutputPath" -ForegroundColor Gray
    Write-Host "  Modules: $($moduleSizes.Count)" -ForegroundColor Gray
    Write-Host "  Chunks: $($chunks.Count)" -ForegroundColor Gray
    Write-Host "  Total Size: $(Format-FileSize $totalSize)" -ForegroundColor Gray
    
    Write-Host "`nFiles Created:" -ForegroundColor Yellow
    foreach ($chunkFile in $chunkFiles) {
        $size = (Get-Item $chunkFile).Length
        Write-Host "  $(Split-Path $chunkFile -Leaf) - $(Format-FileSize $size)" -ForegroundColor Gray
    }
    
    Write-Host "`nAdditional Files:" -ForegroundColor Yellow
    Write-Host "  VMware-PowerCLI-Modules-Manifest.txt" -ForegroundColor Gray
    Write-Host "  Extract-ModuleChunks.ps1" -ForegroundColor Gray
    Write-Host "  README.md" -ForegroundColor Gray
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "1. Upload all chunk files to your GitHub repository" -ForegroundColor Gray
    Write-Host "2. Include the manifest, extraction script, and README" -ForegroundColor Gray
    Write-Host "3. Users can download and extract using Extract-ModuleChunks.ps1" -ForegroundColor Gray
    
    Write-Host "`nIMPORTANT: VMware.PowerCLI.psd1 location:" -ForegroundColor Red
    if ($mainPsd1) {
        $relativePsd1Path = $mainPsd1.FullName.Replace($ModulesPath, "").TrimStart('\', '/')
        Write-Host "  $relativePsd1Path" -ForegroundColor Yellow
    }
    else {
        Write-Host "  VMware.PowerCLI\VMware.PowerCLI.psd1" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Host "Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}