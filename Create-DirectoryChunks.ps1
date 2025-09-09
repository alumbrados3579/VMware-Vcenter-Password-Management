# VMware vCenter Password Management Tool - Directory Chunking Script
# Purpose: Create GitHub-compliant chunks of the entire Modules directory
# Version: 2.0 - Directory-level chunking approach

param(
    [string]$SourceDirectory = "Modules",
    [string]$OutputDirectory = ".",
    [int]$MaxChunkSizeMB = 95,
    [string]$ChunkPrefix = "modules-chunk-",
    [switch]$Force
)

# Global error handling
$ErrorActionPreference = "Stop"

# Ensure we're in the correct directory
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptRoot

Write-Host "=== VMware Modules Directory Chunking Script ===" -ForegroundColor Cyan
Write-Host "Creating GitHub-compliant chunks of the entire Modules directory" -ForegroundColor Cyan
Write-Host ""

# Validate source directory
if (-not (Test-Path $SourceDirectory)) {
    Write-Host "ERROR: Source directory '$SourceDirectory' not found!" -ForegroundColor Red
    exit 1
}

# Get source directory info
$sourceInfo = Get-Item $SourceDirectory
$sourceSizeMB = [math]::Round((Get-ChildItem $SourceDirectory -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

Write-Host "Source Directory: $($sourceInfo.FullName)" -ForegroundColor Green
Write-Host "Total Size: $sourceSizeMB MB" -ForegroundColor Green
Write-Host "Max Chunk Size: $MaxChunkSizeMB MB" -ForegroundColor Green
Write-Host ""

# Calculate estimated number of chunks
$estimatedChunks = [math]::Ceiling($sourceSizeMB / $MaxChunkSizeMB)
Write-Host "Estimated chunks needed: $estimatedChunks" -ForegroundColor Yellow
Write-Host ""

# Check for existing chunks
$existingChunks = Get-ChildItem -Path $OutputDirectory -Name "$ChunkPrefix*.zip" -ErrorAction SilentlyContinue
if ($existingChunks.Count -gt 0 -and -not $Force) {
    Write-Host "WARNING: Found existing chunk files:" -ForegroundColor Yellow
    $existingChunks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
    $response = Read-Host "Do you want to overwrite existing chunks? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# Remove existing chunks if they exist
if ($existingChunks.Count -gt 0) {
    Write-Host "Removing existing chunk files..." -ForegroundColor Yellow
    $existingChunks | ForEach-Object {
        $chunkPath = Join-Path $OutputDirectory $_
        Remove-Item $chunkPath -Force
        Write-Host "  Removed: $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Create temporary working directory
$tempBase = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
$tempDir = Join-Path $tempBase "VMware-Modules-Chunking-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Creating temporary directory: $tempDir" -ForegroundColor Cyan

try {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # Copy the entire Modules directory to temp location
    Write-Host "Copying Modules directory to temporary location..." -ForegroundColor Cyan
    $tempModulesDir = Join-Path $tempDir "Modules"
    Copy-Item -Path $SourceDirectory -Destination $tempModulesDir -Recurse -Force
    
    # Create the first zip file with the entire directory
    Write-Host "Creating initial zip file..." -ForegroundColor Cyan
    $initialZipPath = Join-Path $tempDir "modules-complete.zip"
    
    # Use PowerShell's Compress-Archive for better compatibility
    Compress-Archive -Path $tempModulesDir -DestinationPath $initialZipPath -CompressionLevel Optimal
    
    # Check the size of the initial zip
    $zipInfo = Get-Item $initialZipPath
    $zipSizeMB = [math]::Round($zipInfo.Length / 1MB, 2)
    
    Write-Host "Initial zip size: $zipSizeMB MB" -ForegroundColor Green
    
    if ($zipSizeMB -le $MaxChunkSizeMB) {
        # Single chunk is sufficient
        Write-Host "Single chunk is sufficient!" -ForegroundColor Green
        $finalChunkPath = Join-Path $OutputDirectory "$ChunkPrefix" + "01.zip"
        Move-Item $initialZipPath $finalChunkPath
        
        Write-Host ""
        Write-Host "=== Chunking Complete ===" -ForegroundColor Green
        Write-Host "Created 1 chunk:" -ForegroundColor Green
        Write-Host "  - $ChunkPrefix" + "01.zip ($zipSizeMB MB)" -ForegroundColor Green
        
        # Create manifest
        $manifestContent = @"
# VMware Modules Directory Chunks Manifest
# Generated: $(Get-Date)
# Source Directory: $SourceDirectory
# Total Source Size: $sourceSizeMB MB
# Compression Method: Directory-level chunking

# Chunk Information:
# Chunk 01: $ChunkPrefix" + "01.zip ($zipSizeMB MB)

# Extraction Instructions:
# 1. Ensure all chunk files are in the same directory
# 2. Run the startup script or extraction script
# 3. Chunks will be automatically extracted and cleaned up
# 4. The complete Modules directory will be recreated

Total-Chunks: 1
Total-Compressed-Size: $zipSizeMB MB
Compression-Ratio: $([math]::Round(($zipSizeMB / $sourceSizeMB) * 100, 1))%
"@
        
        $manifestPath = Join-Path $OutputDirectory "modules-chunks-manifest.txt"
        $manifestContent | Set-Content -Path $manifestPath
        Write-Host "  - modules-chunks-manifest.txt (manifest file)" -ForegroundColor Green
        
    } else {
        # Need to split into multiple chunks
        Write-Host "Multiple chunks required. Splitting zip file..." -ForegroundColor Yellow
        
        # For simplicity, we'll use a different approach: split by file size using 7-Zip if available
        # or create multiple smaller zips
        
        # Check if 7-Zip is available
        $sevenZipPath = $null
        $possiblePaths = @(
            "${env:ProgramFiles}\7-Zip\7z.exe",
            "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
            "7z.exe"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path -ErrorAction SilentlyContinue) {
                $sevenZipPath = $path
                break
            }
        }
        
        if ($sevenZipPath) {
            Write-Host "Using 7-Zip for volume splitting..." -ForegroundColor Green
            
            # Create split archives using 7-Zip
            $volumeSize = "$($MaxChunkSizeMB)m"
            $outputPattern = Join-Path $OutputDirectory "$ChunkPrefix" + "01.zip"
            
            $sevenZipArgs = @(
                "a",
                "-tzip",
                "-v$volumeSize",
                $outputPattern,
                $tempModulesDir
            )
            
            Write-Host "Running 7-Zip with volume size: $volumeSize" -ForegroundColor Cyan
            & $sevenZipPath $sevenZipArgs
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "7-Zip splitting completed successfully!" -ForegroundColor Green
                
                # List created chunks
                $createdChunks = Get-ChildItem -Path $OutputDirectory -Name "$ChunkPrefix*.zip" | Sort-Object
                Write-Host ""
                Write-Host "=== Chunking Complete ===" -ForegroundColor Green
                Write-Host "Created $($createdChunks.Count) chunks:" -ForegroundColor Green
                
                $totalCompressedSize = 0
                foreach ($chunk in $createdChunks) {
                    $chunkPath = Join-Path $OutputDirectory $chunk
                    $chunkSize = [math]::Round((Get-Item $chunkPath).Length / 1MB, 2)
                    $totalCompressedSize += $chunkSize
                    Write-Host "  - $chunk ($chunkSize MB)" -ForegroundColor Green
                }
                
                # Create manifest
                $chunkList = $createdChunks | ForEach-Object { 
                    $chunkPath = Join-Path $OutputDirectory $_
                    $chunkSize = [math]::Round((Get-Item $chunkPath).Length / 1MB, 2)
                    "# Chunk: $_ ($chunkSize MB)"
                } | Out-String
                
                $manifestContent = @"
# VMware Modules Directory Chunks Manifest
# Generated: $(Get-Date)
# Source Directory: $SourceDirectory
# Total Source Size: $sourceSizeMB MB
# Compression Method: 7-Zip volume splitting

# Chunk Information:
$chunkList

# Extraction Instructions:
# 1. Ensure all chunk files are in the same directory
# 2. Run the startup script or extraction script
# 3. Chunks will be automatically extracted and cleaned up
# 4. The complete Modules directory will be recreated

Total-Chunks: $($createdChunks.Count)
Total-Compressed-Size: $([math]::Round($totalCompressedSize, 2)) MB
Compression-Ratio: $([math]::Round(($totalCompressedSize / $sourceSizeMB) * 100, 1))%
"@
                
                $manifestPath = Join-Path $OutputDirectory "modules-chunks-manifest.txt"
                $manifestContent | Set-Content -Path $manifestPath
                Write-Host "  - modules-chunks-manifest.txt (manifest file)" -ForegroundColor Green
                
            } else {
                Write-Host "ERROR: 7-Zip failed with exit code: $LASTEXITCODE" -ForegroundColor Red
                throw "7-Zip operation failed"
            }
            
        } else {
            Write-Host "7-Zip not found. Using alternative chunking method..." -ForegroundColor Yellow
            
            # Alternative: Create multiple smaller zips by grouping subdirectories
            $moduleSubdirs = Get-ChildItem -Path $tempModulesDir -Directory
            $chunkNumber = 1
            $currentChunkSize = 0
            $currentChunkItems = @()
            $createdChunks = @()
            
            foreach ($subdir in $moduleSubdirs) {
                $subdirSize = (Get-ChildItem $subdir.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
                
                if (($currentChunkSize + $subdirSize) -gt $MaxChunkSizeMB -and $currentChunkItems.Count -gt 0) {
                    # Create current chunk
                    $chunkName = "$ChunkPrefix" + "{0:D2}.zip" -f $chunkNumber
                    $chunkPath = Join-Path $OutputDirectory $chunkName
                    
                    Write-Host "Creating chunk $chunkNumber with $($currentChunkItems.Count) modules ($([math]::Round($currentChunkSize, 2)) MB)..." -ForegroundColor Cyan
                    
                    # Create temporary directory for this chunk
                    $chunkTempDir = Join-Path $tempDir "chunk-$chunkNumber"
                    $chunkModulesDir = Join-Path $chunkTempDir "Modules"
                    New-Item -Path $chunkModulesDir -ItemType Directory -Force | Out-Null
                    
                    # Copy items to chunk directory
                    foreach ($item in $currentChunkItems) {
                        $destPath = Join-Path $chunkModulesDir $item.Name
                        Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force
                    }
                    
                    # Create zip
                    Compress-Archive -Path $chunkModulesDir -DestinationPath $chunkPath -CompressionLevel Optimal
                    $createdChunks += $chunkName
                    
                    # Reset for next chunk
                    $chunkNumber++
                    $currentChunkSize = $subdirSize
                    $currentChunkItems = @($subdir)
                } else {
                    $currentChunkSize += $subdirSize
                    $currentChunkItems += $subdir
                }
            }
            
            # Create final chunk if there are remaining items
            if ($currentChunkItems.Count -gt 0) {
                $chunkName = "$ChunkPrefix" + "{0:D2}.zip" -f $chunkNumber
                $chunkPath = Join-Path $OutputDirectory $chunkName
                
                Write-Host "Creating final chunk $chunkNumber with $($currentChunkItems.Count) modules ($([math]::Round($currentChunkSize, 2)) MB)..." -ForegroundColor Cyan
                
                # Create temporary directory for this chunk
                $chunkTempDir = Join-Path $tempDir "chunk-$chunkNumber"
                $chunkModulesDir = Join-Path $chunkTempDir "Modules"
                New-Item -Path $chunkModulesDir -ItemType Directory -Force | Out-Null
                
                # Copy items to chunk directory
                foreach ($item in $currentChunkItems) {
                    $destPath = Join-Path $chunkModulesDir $item.Name
                    Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force
                }
                
                # Create zip
                Compress-Archive -Path $chunkModulesDir -DestinationPath $chunkPath -CompressionLevel Optimal
                $createdChunks += $chunkName
            }
            
            Write-Host ""
            Write-Host "=== Chunking Complete ===" -ForegroundColor Green
            Write-Host "Created $($createdChunks.Count) chunks:" -ForegroundColor Green
            
            $totalCompressedSize = 0
            foreach ($chunk in $createdChunks) {
                $chunkPath = Join-Path $OutputDirectory $chunk
                $chunkSize = [math]::Round((Get-Item $chunkPath).Length / 1MB, 2)
                $totalCompressedSize += $chunkSize
                Write-Host "  - $chunk ($chunkSize MB)" -ForegroundColor Green
            }
            
            # Create manifest
            $chunkList = $createdChunks | ForEach-Object { 
                $chunkPath = Join-Path $OutputDirectory $_
                $chunkSize = [math]::Round((Get-Item $chunkPath).Length / 1MB, 2)
                "# Chunk: $_ ($chunkSize MB)"
            } | Out-String
            
            $manifestContent = @"
# VMware Modules Directory Chunks Manifest
# Generated: $(Get-Date)
# Source Directory: $SourceDirectory
# Total Source Size: $sourceSizeMB MB
# Compression Method: PowerShell subdirectory grouping

# Chunk Information:
$chunkList

# Extraction Instructions:
# 1. Ensure all chunk files are in the same directory
# 2. Run the startup script or extraction script
# 3. Chunks will be automatically extracted and cleaned up
# 4. The complete Modules directory will be recreated

Total-Chunks: $($createdChunks.Count)
Total-Compressed-Size: $([math]::Round($totalCompressedSize, 2)) MB
Compression-Ratio: $([math]::Round(($totalCompressedSize / $sourceSizeMB) * 100, 1))%
"@
            
            $manifestPath = Join-Path $OutputDirectory "modules-chunks-manifest.txt"
            $manifestContent | Set-Content -Path $manifestPath
            Write-Host "  - modules-chunks-manifest.txt (manifest file)" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "Compression ratio: $([math]::Round(($totalCompressedSize / $sourceSizeMB) * 100, 1))%" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Commit the chunk files to your repository" -ForegroundColor White
    Write-Host "2. Update the startup script to download and extract chunks" -ForegroundColor White
    Write-Host "3. Test the extraction process" -ForegroundColor White
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Write-Host "Cleaning up temporary directory..." -ForegroundColor Cyan
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Directory chunking completed successfully!" -ForegroundColor Green