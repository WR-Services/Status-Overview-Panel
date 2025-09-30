#!/usr/bin/env pwsh
# Script to perform a complete clean and rebuild of the plugin

Write-Host "Starting complete clean and rebuild process..." -ForegroundColor Cyan

# Step 1: Remove all generated/build files
Write-Host "Removing all build artifacts and caches..." -ForegroundColor Yellow

# Clean dist directory
if (Test-Path "dist") {
    Remove-Item -Path "dist" -Recurse -Force
    Write-Host "✓ Removed dist directory" -ForegroundColor Gray
}

# Clean node_modules cache
if (Test-Path "node_modules\.cache") {
    Remove-Item -Path "node_modules\.cache" -Recurse -Force
    Write-Host "✓ Cleared node_modules cache" -ForegroundColor Gray
}

# Clean package directory
if (Test-Path "package") {
    Remove-Item -Path "package" -Recurse -Force
    Write-Host "✓ Removed package directory" -ForegroundColor Gray
}

# Step 2: Reinstall dependencies if requested
param(
    [switch]$ReinstallDeps
)

if ($ReinstallDeps) {
    Write-Host "Reinstalling dependencies..." -ForegroundColor Yellow
    
    # Remove node_modules
    if (Test-Path "node_modules") {
        Remove-Item -Path "node_modules" -Recurse -Force
        Write-Host "✓ Removed node_modules" -ForegroundColor Gray
    }
    
    # Reinstall dependencies
    npm install
    
    if (-Not $?) {
        Write-Host "Failed to reinstall dependencies. Aborting." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Dependencies reinstalled" -ForegroundColor Green
}

# Step 3: Build the plugin
Write-Host "Building plugin in production mode..." -ForegroundColor Yellow
npm run build

if (-Not $?) {
    Write-Host "Build failed. See errors above." -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Clean build completed successfully!" -ForegroundColor Green
Write-Host "Now you can run .\package-plugin.ps1 to package the plugin" -ForegroundColor Cyan