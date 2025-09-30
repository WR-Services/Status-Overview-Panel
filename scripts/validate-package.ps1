#!/usr/bin/env pwsh
# Script to validate that the plugin package meets Grafana's requirements
# Based on the error messages from Grafana Plugin Catalog

param(
    [Parameter(Mandatory = $false)]
    [string]$PackagePath = "package",
    
    [Parameter(Mandatory = $false)]
    [string]$PluginId = "wrservices-statusoverview-panel"
)

# Find the latest zip file in the package directory
$zipFile = Get-ChildItem -Path $PackagePath -Filter "$PluginId-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $zipFile) {
    Write-Host "❌ No plugin package found in $PackagePath directory." -ForegroundColor Red
    Write-Host "Please run package-plugin.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Validating plugin package: $($zipFile.Name)" -ForegroundColor Cyan

# Create a temporary directory for extraction
$tempDir = Join-Path -Path $env:TEMP -ChildPath "plugin-validate-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Extract the ZIP file to the temp directory
    Write-Host "Extracting plugin archive to analyze structure..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFile.FullName -DestinationPath $tempDir -Force
    
    # Check the directory structure
    $topLevelDirs = Get-ChildItem -Path $tempDir -Directory
    $numTopLevelDirs = $topLevelDirs.Count
    
    if ($numTopLevelDirs -eq 0) {
        Write-Host "❌ No directories found in the archive." -ForegroundColor Red
        Write-Host "The archive should contain a single directory named '$PluginId'." -ForegroundColor Red
    }
    elseif ($numTopLevelDirs -gt 1) {
        Write-Host "❌ Archive contains more than one directory at the top level." -ForegroundColor Red
        Write-Host "Found $numTopLevelDirs directories: $($topLevelDirs.Name -join ', ')" -ForegroundColor Red
        Write-Host "The archive should contain a single directory named '$PluginId'." -ForegroundColor Red
    }
    else {
        $topLevelDir = $topLevelDirs[0]
        if ($topLevelDir.Name -ne $PluginId) {
            Write-Host "❌ Top-level directory is named incorrectly." -ForegroundColor Red
            Write-Host "Expected: $PluginId" -ForegroundColor Red
            Write-Host "Found: $($topLevelDir.Name)" -ForegroundColor Red
        }
        else {
            Write-Host "✅ Archive contains a single top-level directory named '$PluginId'." -ForegroundColor Green
            
            # Check for required files
            $requiredFiles = @("plugin.json", "module.js")
            $missingFiles = @()
            
            foreach ($file in $requiredFiles) {
                $path = Join-Path -Path $topLevelDir.FullName -ChildPath $file
                if (-not (Test-Path $path)) {
                    $missingFiles += $file
                }
            }
            
            if ($missingFiles.Count -gt 0) {
                Write-Host "❌ Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
            }
            else {
                Write-Host "✅ All required files are present." -ForegroundColor Green
            }
            
            # Verify plugin.json in the package
            $pluginJsonPath = Join-Path -Path $topLevelDir.FullName -ChildPath "plugin.json"
            if (Test-Path $pluginJsonPath) {
                $packagedPluginJson = Get-Content -Path $pluginJsonPath -Raw | ConvertFrom-Json
                Write-Host "Plugin ID in package: $($packagedPluginJson.id)" -ForegroundColor Yellow
                Write-Host "Plugin version in package: $($packagedPluginJson.info.version)" -ForegroundColor Yellow
                
                if ($packagedPluginJson.id -ne $PluginId) {
                    Write-Host "❌ Plugin ID mismatch. Expected '$PluginId', found '$($packagedPluginJson.id)'" -ForegroundColor Red
                }
                else {
                    Write-Host "✅ Plugin ID matches expected value." -ForegroundColor Green
                }
            }
        }
    }

    Write-Host "`nReminder: The package should have a structure like this:" -ForegroundColor Cyan
    Write-Host "📁 $PluginId-[version].zip" -ForegroundColor Gray
    Write-Host "  └─📁 $PluginId" -ForegroundColor Gray
    Write-Host "     ├─📄 plugin.json" -ForegroundColor Gray
    Write-Host "     ├─📄 module.js" -ForegroundColor Gray
    Write-Host "     └─📄 other plugin files..." -ForegroundColor Gray

}
finally {
    # Clean up the temporary directory
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}

Write-Host "`nTo fix structure issues, make sure:" -ForegroundColor Yellow
Write-Host "1. The package-plugin.ps1 script is creating the ZIP file correctly" -ForegroundColor Yellow
Write-Host "2. The dist folder contains files at the root level (not in subdirectories)" -ForegroundColor Yellow
Write-Host "3. The plugin ID matches exactly in all files" -ForegroundColor Yellow