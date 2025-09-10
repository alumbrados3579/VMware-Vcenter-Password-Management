# VMware vCenter Password Management Tool - Modular Architecture Test
# Version 0.5 BETA - Test Script for Modular Components
# Purpose: Test individual tools and modular launcher

Write-Host ""
Write-Host "=== VMware Password Manager - Modular Architecture Test ===" -ForegroundColor Green
Write-Host ""

# Test 1: Check if Tools directory exists
Write-Host "Test 1: Checking Tools directory structure..." -ForegroundColor Cyan
if (Test-Path "Tools") {
    Write-Host "[SUCCESS] Tools directory exists" -ForegroundColor Green
    
    $expectedFiles = @("Common.ps1", "CLIWorkspace.ps1", "Configuration.ps1")
    foreach ($file in $expectedFiles) {
        $filePath = Join-Path "Tools" $file
        if (Test-Path $filePath) {
            $size = (Get-Item $filePath).Length
            Write-Host "[SUCCESS] $file exists ($([math]::Round($size/1KB, 1))KB)" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] $file missing" -ForegroundColor Red
        }
    }
} else {
    Write-Host "[ERROR] Tools directory not found" -ForegroundColor Red
}

Write-Host ""

# Test 2: Check modular launcher
Write-Host "Test 2: Checking modular launcher..." -ForegroundColor Cyan
if (Test-Path "VMware-Password-Manager-Modular.ps1") {
    $size = (Get-Item "VMware-Password-Manager-Modular.ps1").Length
    Write-Host "[SUCCESS] Modular launcher exists ($([math]::Round($size/1KB, 1))KB)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Modular launcher missing" -ForegroundColor Red
}

Write-Host ""

# Test 3: Check original files preserved
Write-Host "Test 3: Checking original files preserved..." -ForegroundColor Cyan
$originalFiles = @("VMware-Setup.ps1", "VMware-Password-Manager.ps1", "Test-Startup.ps1")
foreach ($file in $originalFiles) {
    if (Test-Path $file) {
        Write-Host "[SUCCESS] $file preserved" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] $file missing" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 4: Performance comparison estimate
Write-Host "Test 4: Performance estimates..." -ForegroundColor Cyan
$originalSize = if (Test-Path "VMware-Password-Manager.ps1") { (Get-Item "VMware-Password-Manager.ps1").Length } else { 0 }
$cliSize = if (Test-Path "Tools\CLIWorkspace.ps1") { (Get-Item "Tools\CLIWorkspace.ps1").Length } else { 0 }
$commonSize = if (Test-Path "Tools\Common.ps1") { (Get-Item "Tools\Common.ps1").Length } else { 0 }
$configSize = if (Test-Path "Tools\Configuration.ps1") { (Get-Item "Tools\Configuration.ps1").Length } else { 0 }

Write-Host "Original monolithic app: $([math]::Round($originalSize/1KB, 1))KB" -ForegroundColor White
Write-Host "CLI Workspace standalone: $([math]::Round(($cliSize + $commonSize)/1KB, 1))KB ($([math]::Round((1 - ($cliSize + $commonSize)/$originalSize) * 100, 0))% smaller)" -ForegroundColor Green
Write-Host "Configuration standalone: $([math]::Round(($configSize + $commonSize)/1KB, 1))KB ($([math]::Round((1 - ($configSize + $commonSize)/$originalSize) * 100, 0))% smaller)" -ForegroundColor Green

Write-Host ""

# Test 5: Usage examples
Write-Host "Test 5: Usage examples..." -ForegroundColor Cyan
Write-Host "Individual tool usage (FASTEST):" -ForegroundColor Yellow
Write-Host "  .\Tools\CLIWorkspace.ps1" -ForegroundColor Gray
Write-Host "  .\Tools\Configuration.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Modular launcher usage:" -ForegroundColor Yellow
Write-Host "  .\VMware-Password-Manager-Modular.ps1 -Tool CLI" -ForegroundColor Gray
Write-Host "  .\VMware-Password-Manager-Modular.ps1 -Tool Config" -ForegroundColor Gray
Write-Host "  .\VMware-Password-Manager-Modular.ps1 -List" -ForegroundColor Gray
Write-Host ""
Write-Host "Original usage (preserved):" -ForegroundColor Yellow
Write-Host "  .\VMware-Password-Manager.ps1" -ForegroundColor Gray
Write-Host "  .\Test-Startup.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green
Write-Host ""

$choice = Read-Host "Would you like to test the modular launcher now? (Y/N)"
if ($choice -eq "Y" -or $choice -eq "y") {
    Write-Host "Starting modular launcher..." -ForegroundColor Green
    .\VMware-Password-Manager-Modular.ps1
}