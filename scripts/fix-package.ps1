#!/usr/bin/env pwsh
# Script to fix package structure for Grafana plugin submission

param(
    [Parameter(Mandatory = $false)]
    [string]$PluginId = "wrservices-statusoverview-panel",
    
    [Parameter(Mandatory = $false)]
    [string]$Version,
    
    [Parameter(Mandatory = $false)]
    [string]$PackagePath = "package"
)

# If no version specified, read from package.json
if (-not $Version) {
    $packageJsonContent = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
    $Version = $packageJsonContent.version
}

Write-Host "Fixing package structure for $PluginId v$Version" -ForegroundColor Cyan

$zipPath = "$PackagePath\$PluginId-$Version.zip"

# Check if the package exists
if (-not (Test-Path $zipPath)) {
    Write-Host "❌ Package not found: $zipPath" -ForegroundColor Red
    Write-Host "Please run package-plugin.ps1 first or specify the correct version." -ForegroundColor Red
    exit 1
}

# Create temporary directories
$tempDir = Join-Path -Path $env:TEMP -ChildPath "grafana-plugin-fix-$(Get-Random)"
$tempExtractDir = Join-Path -Path $tempDir -ChildPath "extract"
$tempFixedDir = Join-Path -Path $tempDir -ChildPath "fixed"
$tempPluginDir = Join-Path -Path $tempFixedDir -ChildPath $PluginId

# Create directories
New-Item -ItemType Directory -Path $tempExtractDir -Force | Out-Null
New-Item -ItemType Directory -Path $tempPluginDir -Force | Out-Null

try {
    # Extract the ZIP file
    Write-Host "Extracting package for analysis..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $tempExtractDir -Force
    
    # Check the structure
    $extractedItems = Get-ChildItem -Path $tempExtractDir -Recurse
    
    Write-Host "Found $(($extractedItems | Where-Object { -not $_.PSIsContainer }).Count) files in the package" -ForegroundColor Gray
    
    # Determine if we have files at the root or in subdirectories
    $rootFiles = Get-ChildItem -Path $tempExtractDir -File
    $rootDirs = Get-ChildItem -Path $tempExtractDir -Directory
    
    Write-Host "Package structure:" -ForegroundColor Yellow
    Write-Host "- $($rootFiles.Count) files at root level" -ForegroundColor Gray
    Write-Host "- $($rootDirs.Count) directories at root level" -ForegroundColor Gray
    
    if ($rootDirs.Count -eq 1 -and $rootDirs[0].Name -eq $PluginId) {
        Write-Host "✓ Package already has correct structure with single top-level directory: $PluginId" -ForegroundColor Green
        # Copy files maintaining the structure
        Copy-Item -Path "$tempExtractDir\$PluginId\*" -Destination $tempPluginDir -Recurse
    }
    else {
        Write-Host "⚠️ Incorrect package structure. Fixing..." -ForegroundColor Yellow
        
        if ($rootDirs.Count -gt 0) {
            # Case 1: Multiple directories - need to merge all content into one
            foreach ($dir in $rootDirs) {
                Write-Host "  Moving content from directory: $($dir.Name)" -ForegroundColor Gray
                Copy-Item -Path "$($dir.FullName)\*" -Destination $tempPluginDir -Recurse
            }
        }
        
        # Also move any root files
        if ($rootFiles.Count -gt 0) {
            Write-Host "  Moving files from root level" -ForegroundColor Gray
            foreach ($file in $rootFiles) {
                Copy-Item -Path $file.FullName -Destination $tempPluginDir
            }
        }
    }
    
    # Check if required files exist in the corrected structure
    $requiredFiles = @("plugin.json", "module.js")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path "$tempPluginDir\$file")) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "❌ Warning: Missing required files in fixed package: $($missingFiles -join ', ')" -ForegroundColor Red
        Write-Host "This might indicate a deeper issue with your build process." -ForegroundColor Red
    }
    else {
        Write-Host "✓ All required files present in fixed structure" -ForegroundColor Green
    }
    
    # Create fixed ZIP file
    $fixedZipPath = "$PackagePath\$PluginId-$Version-fixed.zip"
    if (Test-Path $fixedZipPath) {
        Remove-Item -Path $fixedZipPath -Force
    }
    
    Write-Host "Creating properly structured ZIP file..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempFixedDir, $fixedZipPath)
    
    # Calculate checksums for the fixed package
    $sha1 = Get-FileHash -Path $fixedZipPath -Algorithm SHA1
    $md5 = Get-FileHash -Path $fixedZipPath -Algorithm MD5
    
    # Write checksums to files
    $sha1.Hash | Out-File -FilePath "$fixedZipPath.sha1" -NoNewline
    $md5.Hash | Out-File -FilePath "$fixedZipPath.md5" -NoNewline
    
    Write-Host "`n✅ Fixed package created successfully!" -ForegroundColor Green
    Write-Host "  - Location: $fixedZipPath" -ForegroundColor Green
    Write-Host "  - Size: $([Math]::Round((Get-Item $fixedZipPath).Length / 1MB, 2)) MB" -ForegroundColor Green
    Write-Host "  - MD5: $($md5.Hash)" -ForegroundColor Green
    Write-Host "  - SHA1: $($sha1.Hash)" -ForegroundColor Green
    
    Write-Host "`n📢 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Test the fixed package in a clean Grafana environment" -ForegroundColor Cyan
    Write-Host "2. Submit the FIXED package to Grafana Plugin Catalog" -ForegroundColor Cyan
    
}
finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}