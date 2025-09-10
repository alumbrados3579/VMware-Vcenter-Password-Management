# VMware vCenter Password Management Tool - File Integrity Verification
# Version 1.0 - Professional Security Edition
# Author: Stace Mitchell <stace.mitchell27@gmail.com>
# Purpose: Generate and verify SHA-256 and MD5 checksums for code integrity
# Copyright (c) 2025 Stace Mitchell. All rights reserved.

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Generate", "Verify", "Both")]
    [string]$Action = "Both",
    
    [Parameter(Mandatory=$false)]
    [string]$ChecksumFile = "file-integrity.txt",
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

# Critical files to monitor for integrity
$CriticalFiles = @(
    "VMware-Setup.ps1",
    "VMware-Password-Manager.ps1", 
    "VMware-Password-Manager-Modular.ps1",
    "VMware-Host-Manager.ps1",
    "Tools/Common.ps1",
    "Tools/CLIWorkspace.ps1",
    "Tools/Configuration.ps1",
    "Tools/HostManager.ps1",
    "README.md",
    "HOWTO.txt",
    "Installation.txt",
    "AUTHORS.txt"
)

function Write-VerboseOutput {
    param([string]$Message)
    if ($ShowDetails) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

function Get-FileIntegrityData {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $fileInfo = Get-Item $FilePath
    $sha256Hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    $md5Hash = Get-FileHash -Path $FilePath -Algorithm MD5
    
    return @{
        Path = $FilePath
        Size = $fileInfo.Length
        LastModified = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        SHA256 = $sha256Hash.Hash
        MD5 = $md5Hash.Hash
    }
}

function Generate-IntegrityFile {
    Write-Host "=== GENERATING FILE INTEGRITY CHECKSUMS ===" -ForegroundColor Green
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = @()
    $output += "# VMware vCenter Password Management Tool - File Integrity Verification"
    $output += "# Generated: $timestamp"
    $output += "# Format: FilePath|Size|LastModified|SHA256|MD5"
    $output += ""
    
    $totalFiles = 0
    $processedFiles = 0
    
    foreach ($file in $CriticalFiles) {
        $totalFiles++
        Write-VerboseOutput "Processing: $file"
        
        $integrity = Get-FileIntegrityData -FilePath $file
        if ($integrity) {
            $line = "$($integrity.Path)|$($integrity.Size)|$($integrity.LastModified)|$($integrity.SHA256)|$($integrity.MD5)"
            $output += $line
            $processedFiles++
            
            Write-Host "[✓] $file" -ForegroundColor Green
            Write-Host "    SHA256: $($integrity.SHA256)" -ForegroundColor Gray
            Write-Host "    MD5:    $($integrity.MD5)" -ForegroundColor Gray
            Write-Host "    Size:   $($integrity.Size) bytes" -ForegroundColor Gray
            Write-Host ""
        } else {
            Write-Host "[!] $file - FILE NOT FOUND" -ForegroundColor Yellow
        }
    }
    
    $output | Set-Content -Path $ChecksumFile -Encoding UTF8
    
    Write-Host "=== GENERATION COMPLETE ===" -ForegroundColor Green
    Write-Host "Files processed: $processedFiles / $totalFiles" -ForegroundColor White
    Write-Host "Checksums saved to: $ChecksumFile" -ForegroundColor White
    Write-Host ""
}

function Verify-IntegrityFile {
    Write-Host "=== VERIFYING FILE INTEGRITY ===" -ForegroundColor Blue
    Write-Host ""
    
    if (-not (Test-Path $ChecksumFile)) {
        Write-Host "[ERROR] Checksum file not found: $ChecksumFile" -ForegroundColor Red
        Write-Host "Run with -Action Generate first to create checksums." -ForegroundColor Yellow
        return $false
    }
    
    $checksumData = Get-Content $ChecksumFile | Where-Object { $_ -notmatch "^#" -and $_.Trim() -ne "" }
    $verificationResults = @()
    $totalChecks = 0
    $passedChecks = 0
    $failedChecks = 0
    $missingFiles = 0
    
    foreach ($line in $checksumData) {
        $parts = $line -split '\|'
        if ($parts.Count -eq 5) {
            $totalChecks++
            $filePath = $parts[0]
            $originalSize = $parts[1]
            $originalModified = $parts[2]
            $originalSHA256 = $parts[3]
            $originalMD5 = $parts[4]
            
            Write-VerboseOutput "Verifying: $filePath"
            
            $currentIntegrity = Get-FileIntegrityData -FilePath $filePath
            
            if (-not $currentIntegrity) {
                Write-Host "[✗] $filePath - FILE MISSING" -ForegroundColor Red
                $missingFiles++
                $verificationResults += @{
                    File = $filePath
                    Status = "MISSING"
                    Details = "File not found"
                }
                continue
            }
            
            $sizeMatch = $currentIntegrity.Size -eq $originalSize
            $sha256Match = $currentIntegrity.SHA256 -eq $originalSHA256
            $md5Match = $currentIntegrity.MD5 -eq $originalMD5
            
            if ($sizeMatch -and $sha256Match -and $md5Match) {
                Write-Host "[✓] $filePath - INTEGRITY VERIFIED" -ForegroundColor Green
                $passedChecks++
                $verificationResults += @{
                    File = $filePath
                    Status = "VERIFIED"
                    Details = "All checksums match"
                }
            } else {
                Write-Host "[✗] $filePath - INTEGRITY FAILED" -ForegroundColor Red
                $failedChecks++
                
                $issues = @()
                if (-not $sizeMatch) { $issues += "Size mismatch (was: $originalSize, now: $($currentIntegrity.Size))" }
                if (-not $sha256Match) { $issues += "SHA256 mismatch" }
                if (-not $md5Match) { $issues += "MD5 mismatch" }
                
                Write-Host "    Issues: $($issues -join ', ')" -ForegroundColor Red
                Write-Host "    Original SHA256: $originalSHA256" -ForegroundColor Gray
                Write-Host "    Current SHA256:  $($currentIntegrity.SHA256)" -ForegroundColor Gray
                Write-Host "    Original MD5:    $originalMD5" -ForegroundColor Gray
                Write-Host "    Current MD5:     $($currentIntegrity.MD5)" -ForegroundColor Gray
                
                $verificationResults += @{
                    File = $filePath
                    Status = "FAILED"
                    Details = $issues -join ', '
                }
            }
            Write-Host ""
        }
    }
    
    Write-Host "=== VERIFICATION SUMMARY ===" -ForegroundColor Blue
    Write-Host "Total files checked: $totalChecks" -ForegroundColor White
    Write-Host "Passed: $passedChecks" -ForegroundColor Green
    Write-Host "Failed: $failedChecks" -ForegroundColor Red
    Write-Host "Missing: $missingFiles" -ForegroundColor Yellow
    Write-Host ""
    
    if ($failedChecks -gt 0 -or $missingFiles -gt 0) {
        Write-Host "⚠️  SECURITY ALERT: File integrity issues detected!" -ForegroundColor Red
        Write-Host "Review the failed files above for potential unauthorized modifications." -ForegroundColor Yellow
        return $false
    } else {
        Write-Host "✅ All files passed integrity verification." -ForegroundColor Green
        return $true
    }
}

function Show-SecurityRecommendations {
    Write-Host ""
    Write-Host "=== SECURITY RECOMMENDATIONS ===" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "1. GitLab Migration:" -ForegroundColor Yellow
    Write-Host "   - Consider migrating to GitLab for better security control" -ForegroundColor White
    Write-Host "   - Use self-hosted GitLab instance for maximum security" -ForegroundColor White
    Write-Host "   - Enable built-in security scanning features" -ForegroundColor White
    Write-Host ""
    Write-Host "2. File Integrity Monitoring:" -ForegroundColor Yellow
    Write-Host "   - Run this script before each commit: .\Verify-FileIntegrity.ps1" -ForegroundColor White
    Write-Host "   - Store checksums in a secure location" -ForegroundColor White
    Write-Host "   - Verify integrity after any collaboration" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Repository Security:" -ForegroundColor Yellow
    Write-Host "   - Enable signed commits (git config commit.gpgsign true)" -ForegroundColor White
    Write-Host "   - Use branch protection rules" -ForegroundColor White
    Write-Host "   - Enable two-factor authentication" -ForegroundColor White
    Write-Host "   - Regular security audits" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Air-Gapped Deployment:" -ForegroundColor Yellow
    Write-Host "   - Use the ZIP package feature for secure networks" -ForegroundColor White
    Write-Host "   - Verify checksums before deployment" -ForegroundColor White
    Write-Host "   - Maintain offline backup of verified code" -ForegroundColor White
    Write-Host ""
}

# Main execution
try {
    Write-Host ""
    Write-Host "VMware vCenter Password Management Tool - File Integrity Verification" -ForegroundColor Cyan
    Write-Host "Version 1.0 - Professional Security Edition" -ForegroundColor Cyan
    Write-Host ""
    
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    Set-Location $scriptRoot
    
    switch ($Action) {
        "Generate" {
            Generate-IntegrityFile
            Show-SecurityRecommendations
        }
        "Verify" {
            $verificationPassed = Verify-IntegrityFile
            if (-not $verificationPassed) {
                Show-SecurityRecommendations
                exit 1
            }
        }
        "Both" {
            Generate-IntegrityFile
            Write-Host ""
            $verificationPassed = Verify-IntegrityFile
            Show-SecurityRecommendations
            if (-not $verificationPassed) {
                exit 1
            }
        }
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}