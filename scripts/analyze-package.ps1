#!/usr/bin/env pwsh
# Script to analyze the structure of a Grafana plugin package

param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath
)

if (-not (Test-Path $ZipPath)) {
    Write-Host "❌ ZIP file not found: $ZipPath" -ForegroundColor Red
    exit 1
}

Write-Host "Analyzing package: $ZipPath" -ForegroundColor Cyan

# Create temporary directory for extraction
$tempDir = Join-Path -Path $env:TEMP -ChildPath "grafana-plugin-analyze-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Extract the ZIP file
    Write-Host "Extracting package..." -ForegroundColor Yellow
    Expand-Archive -Path $ZipPath -DestinationPath $tempDir -Force
    
    # Get contents
    $rootItems = Get-ChildItem -Path $tempDir
    $rootFiles = $rootItems | Where-Object { -not $_.PSIsContainer }
    $rootDirs = $rootItems | Where-Object { $_.PSIsContainer }
    
    # Analysis
    Write-Host "`nPackage Structure Analysis:" -ForegroundColor Cyan
    Write-Host "---------------------------" -ForegroundColor Cyan
    Write-Host "Root files: $($rootFiles.Count)" -ForegroundColor Yellow
    if ($rootFiles.Count -gt 0) {
        $rootFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    }
    
    Write-Host "Root directories: $($rootDirs.Count)" -ForegroundColor Yellow
    if ($rootDirs.Count -gt 0) {
        $rootDirs | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    }
    
    Write-Host "`nGrafana Package Requirements:" -ForegroundColor Cyan
    Write-Host "---------------------------" -ForegroundColor Cyan
    
    # Check if structure matches Grafana requirements
    if ($rootDirs.Count -eq 1 -and $rootFiles.Count -eq 0) {
        $mainDir = $rootDirs[0]
        Write-Host "✅ Package has a single root directory: $($mainDir.Name)" -ForegroundColor Green
        
        # Check if plugin.json exists
        $pluginJsonPath = Join-Path -Path $mainDir.FullName -ChildPath "plugin.json"
        if (Test-Path $pluginJsonPath) {
            Write-Host "✅ Found plugin.json file" -ForegroundColor Green
            
            # Read plugin.json to check ID
            try {
                $pluginJson = Get-Content -Path $pluginJsonPath -Raw | ConvertFrom-Json
                Write-Host "  - Plugin ID: $($pluginJson.id)" -ForegroundColor Gray
                
                if ($pluginJson.id -ne $mainDir.Name) {
                    Write-Host "❌ Plugin ID ($($pluginJson.id)) does not match directory name ($($mainDir.Name))" -ForegroundColor Red
                }
                else {
                    Write-Host "✅ Plugin ID matches directory name" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "❌ Failed to parse plugin.json: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "❌ Missing required plugin.json file" -ForegroundColor Red
        }
        
        # Check for module.js
        $moduleJsPath = Join-Path -Path $mainDir.FullName -ChildPath "module.js"
        if (Test-Path $moduleJsPath) {
            Write-Host "✅ Found module.js file" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Missing required module.js file" -ForegroundColor Red
        }
        
        # List files in the plugin directory (first level)
        $pluginFiles = Get-ChildItem -Path $mainDir.FullName -File
        Write-Host "`nPlugin directory contents (first level):" -ForegroundColor Yellow
        $pluginFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    }
    else {
        Write-Host "❌ Package structure does not meet Grafana requirements!" -ForegroundColor Red
        Write-Host "   Requirement: ZIP must contain only one directory named after the plugin ID" -ForegroundColor Red
        
        if ($rootDirs.Count -eq 0) {
            Write-Host "   Problem: No directories found at the root level" -ForegroundColor Red
        }
        elseif ($rootDirs.Count -gt 1) {
            Write-Host "   Problem: Multiple directories found at root level" -ForegroundColor Red
        }
        
        if ($rootFiles.Count -gt 0) {
            Write-Host "   Problem: Found files at the root level (should be inside a directory)" -ForegroundColor Red
        }
    }
    
    # Show full directory structure (limited depth)
    Write-Host "`nFull Directory Structure:" -ForegroundColor Cyan
    Write-Host "---------------------------" -ForegroundColor Cyan
    
    function Show-DirectoryTree {
        param (
            [string]$Path,
            [int]$Depth = 0,
            [int]$MaxDepth = 3,
            [int]$MaxFiles = 10
        )
        
        if ($Depth -gt $MaxDepth) { return }
        
        $indent = "  " * $Depth
        
        $items = Get-ChildItem -Path $Path
        $dirs = $items | Where-Object { $_.PSIsContainer }
        $files = $items | Where-Object { -not $_.PSIsContainer }
        
        foreach ($dir in $dirs) {
            Write-Host "$indent📁 $($dir.Name)" -ForegroundColor Yellow
            Show-DirectoryTree -Path $dir.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth -MaxFiles $MaxFiles
        }
        
        $fileCount = $files.Count
        $displayFiles = $files | Select-Object -First $MaxFiles
        
        foreach ($file in $displayFiles) {
            Write-Host "$indent📄 $($file.Name)" -ForegroundColor Gray
        }
        
        if ($fileCount -gt $MaxFiles) {
            Write-Host "$indent   ... and $($fileCount - $MaxFiles) more files" -ForegroundColor DarkGray
        }
    }
    
    Show-DirectoryTree -Path $tempDir
    
    # Recommendation
    Write-Host "`nRecommendation:" -ForegroundColor Cyan
    Write-Host "---------------------------" -ForegroundColor Cyan
    
    if ($rootDirs.Count -ne 1 -or $rootFiles.Count -gt 0) {
        Write-Host "Use the fix-package.ps1 script to repair this package:" -ForegroundColor Yellow
        Write-Host ".\fix-package.ps1 -Version ""$(Split-Path -Leaf $ZipPath | ForEach-Object { $_ -replace '.*-(.*)\.zip', '$1' })""" -ForegroundColor Yellow
    }
    else {
        Write-Host "This package appears to have the correct structure. If you're still receiving errors," -ForegroundColor Yellow
        Write-Host "check that the plugin ID in plugin.json exactly matches the directory name." -ForegroundColor Yellow
    }
    
}
finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}