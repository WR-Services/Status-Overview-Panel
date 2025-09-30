#!/usr/bin/env pwsh
# Script to analyze the structure of a Grafana plugin package

param(
    [Parameter(Mandatory=$true)]
    [string]$ZipPath,
    
    [switch]$Brief
)

# Script-level variables
$scriptName = $MyInvocation.MyCommand.Name

if (-not (Test-Path $ZipPath)) {
    Write-Host "❌ ZIP file not found: $ZipPath" -ForegroundColor Red
    exit 1
}

if (-not $Brief) {
    Write-Host "Analyzing package: $ZipPath" -ForegroundColor Cyan
}

# Create temporary directory for extraction
$tempDir = Join-Path -Path $env:TEMP -ChildPath "grafana-plugin-analyze-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Extract the ZIP file
    if (-not $Brief) {
        Write-Host "Extracting package..." -ForegroundColor Yellow
    }
    Expand-Archive -Path $ZipPath -DestinationPath $tempDir -Force
    
    # Get contents
    $rootItems = Get-ChildItem -Path $tempDir
    $rootFiles = $rootItems | Where-Object { -not $_.PSIsContainer }
    $rootDirs = $rootItems | Where-Object { $_.PSIsContainer }
    
    # Analysis
    if (-not $Brief) {
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
    }
    
    if (-not $Brief) {
        Write-Host "`nGrafana Package Requirements:" -ForegroundColor Cyan
        Write-Host "---------------------------" -ForegroundColor Cyan
    }
    
    # Check if structure matches Grafana requirements
    if ($rootDirs.Count -eq 1 -and $rootFiles.Count -eq 0) {
        $mainDir = $rootDirs[0]
        
        if (-not $Brief) {
            Write-Host "✅ Package has a single root directory: $($mainDir.Name)" -ForegroundColor Green
        }
        
        # Check if plugin.json exists
        $pluginJsonPath = Join-Path -Path $mainDir.FullName -ChildPath "plugin.json"
        if (Test-Path $pluginJsonPath) {
            if (-not $Brief) {
                Write-Host "✅ Found plugin.json file" -ForegroundColor Green
            }
            
            # Read plugin.json to check ID
            try {
                $pluginJson = Get-Content -Path $pluginJsonPath -Raw | ConvertFrom-Json
                if (-not $Brief) {
                    Write-Host "  - Plugin ID: $($pluginJson.id)" -ForegroundColor Gray
                }
                
                if ($pluginJson.id -ne $mainDir.Name) {
                    Write-Host "❌ Plugin ID ($($pluginJson.id)) does not match directory name ($($mainDir.Name))" -ForegroundColor Red
                } else {
                    if (-not $Brief) {
                        Write-Host "✅ Plugin ID matches directory name" -ForegroundColor Green
                    }
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
            if (-not $Brief) {
                Write-Host "✅ Found module.js file" -ForegroundColor Green
            }
        }
        else {
            Write-Host "❌ Missing required module.js file" -ForegroundColor Red
        }
        
        if ($Brief) {
            Write-Host "✅ Package structure is valid for Grafana submission" -ForegroundColor Green
        } else {
            # List files in the plugin directory (first level)
            $pluginFiles = Get-ChildItem -Path $mainDir.FullName -File
            Write-Host "`nPlugin directory contents (first level):" -ForegroundColor Yellow
            $pluginFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
        }
    }
    else {
        Write-Host "❌ Package structure does not meet Grafana requirements!" -ForegroundColor Red
        Write-Host "   Requirement: ZIP must contain only one directory named after the plugin ID" -ForegroundColor Red
        
        if ($rootDirs.Count -eq 0) {
            Write-Host "   Problem: No directories found at the root level" -ForegroundColor Red
        } elseif ($rootDirs.Count -gt 1) {
            Write-Host "   Problem: Multiple directories found at root level" -ForegroundColor Red
        }
        
        if ($rootFiles.Count -gt 0) {
            Write-Host "   Problem: Found files at the root level (should be inside a directory)" -ForegroundColor Red
        }
    }
    
    if (-not $Brief) {
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
    }
    
    # Recommendation if needed
    if ($rootDirs.Count -ne 1 -or $rootFiles.Count -gt 0) {
        Write-Host "`nRecommendation:" -ForegroundColor Cyan
        Write-Host "Run the fix script to repair this package:" -ForegroundColor Yellow
        Write-Host "  ./plugin.ps1 fix -Version ""$(Split-Path -Leaf $ZipPath | ForEach-Object { $_ -replace '.*-(.*)\.zip', '$1' })""" -ForegroundColor Yellow
    }
    
} finally {
    # Clean up temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}