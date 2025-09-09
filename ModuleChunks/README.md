# VMware PowerCLI Modules - GitHub Chunks

This directory contains the VMware PowerCLI modules split into GitHub-compliant chunks.

## Overview

- **Total Modules**: 69
- **Total Size**: 794.41 MB
- **Chunk Count**: 7
- **Max Chunk Size**: 95 MB

## Important Files

- **VMware.PowerCLI.psd1**: Main PowerShell module manifest file
- **Location**: VMware.PowerCLI\VMware.PowerCLI.psd1

## Files in this Directory

- **VMware-PowerCLI-Modules-Chunk-XX.zip**: Module chunk files
- **VMware-PowerCLI-Modules-Manifest.txt**: Detailed manifest of all chunks
- **Extract-ModuleChunks.ps1**: PowerShell script to extract all chunks
- **README.md**: This file

## Extraction Instructions

### Method 1: Using PowerShell Script (Recommended)
```powershell
.\Extract-ModuleChunks.ps1
```

### Method 2: Manual Extraction
1. Create a Modules directory
2. Extract each chunk zip file to the Modules directory
3. Ensure all files maintain their directory structure

## Usage After Extraction

After extracting the modules, you can import VMware PowerCLI using:

```powershell
# Navigate to the extracted modules directory
cd .\Modules\VMware.PowerCLI

# Import the module
Import-Module .\VMware.PowerCLI.psd1
```

## Chunk Details
### Chunk 1: VMware-PowerCLI-Modules-Chunk-01.zip
- **Modules**: 1
- **Uncompressed Size**: 238.18 MB
- **Compressed Size**: 38.90 MB
### Chunk 2: VMware-PowerCLI-Modules-Chunk-02.zip
- **Modules**: 1
- **Uncompressed Size**: 118.16 MB
- **Compressed Size**: 43.54 MB
### Chunk 3: VMware-PowerCLI-Modules-Chunk-03.zip
- **Modules**: 1
- **Uncompressed Size**: 113.74 MB
- **Compressed Size**: 18.76 MB
### Chunk 4: VMware-PowerCLI-Modules-Chunk-04.zip
- **Modules**: 1
- **Uncompressed Size**: 109.73 MB
- **Compressed Size**: 23.79 MB
### Chunk 5: VMware-PowerCLI-Modules-Chunk-05.zip
- **Modules**: 2
- **Uncompressed Size**: 78.36 MB
- **Compressed Size**: 7.17 MB
### Chunk 6: VMware-PowerCLI-Modules-Chunk-06.zip
- **Modules**: 8
- **Uncompressed Size**: 94.48 MB
- **Compressed Size**: 3.87 MB
### Chunk 7: VMware-PowerCLI-Modules-Chunk-07.zip
- **Modules**: 55
- **Uncompressed Size**: 41.77 MB
- **Compressed Size**: 741.63 KB

## GitHub Compliance

These chunks are created to comply with GitHub's file size limits:
- Individual file size limit: 100MB
- Each chunk is under 95MB to provide a safety margin

## Generated Information

- **Created**: 2025-09-09 16:37:43
- **Source**: /home/alumbrados/Downloads/qudo/VMware-Vcenter-Password-Management/Modules
- **Tool**: VMware vCenter Password Management - Module Chunking Tool
