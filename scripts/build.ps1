#!/usr/bin/env pwsh
# Build script for Grafana plugin

param(
    [switch]$Production,
    [switch]$Clean
)

# Get the root directory
$rootDir = Split-Path -Parent $PSScriptRoot

Write-Host "Starting plugin build process..." -ForegroundColor Cyan

if ($Clean) {
    # Clean up previous builds
    Write-Host "Performing clean build..." -ForegroundColor Yellow
    
    # Clean node_modules cache
    if (Test-Path -Path "$rootDir\node_modules\.cache") {
        Remove-Item -Path "$rootDir\node_modules\.cache" -Recurse -Force
        Write-Host "✓ Cleared node_modules cache" -ForegroundColor Gray
    }
    
    # Clean dist directory
    if (Test-Path -Path "$rootDir\dist") {
        Remove-Item -Path "$rootDir\dist\*" -Recurse -Force
        Write-Host "✓ Cleaned dist directory" -ForegroundColor Gray
    }
}

# Set build mode
if ($Production) {
    Write-Host "Building plugin in production mode..." -ForegroundColor Yellow
    Set-Location -Path $rootDir
    npm run build -- --production
} else {
    Write-Host "Building plugin in development mode..." -ForegroundColor Yellow
    Set-Location -Path $rootDir
    npm run build
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed. Check the errors above." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green

# Check if Docker is running
$isDockerRunning = $false
try {
    docker info 2>$null | Out-Null
    $isDockerRunning = $true
} catch {
    $isDockerRunning = $false
}

# Ask to restart Docker containers
if ($isDockerRunning) {
    $restart = Read-Host -Prompt "Do you want to restart Docker containers? (y/n)"
    if ($restart -eq "y") {
        Write-Host "Restarting Docker containers..." -ForegroundColor Yellow
        Set-Location -Path $rootDir
        docker-compose down
        docker-compose up -d
        Write-Host "✅ Docker containers restarted. Access Grafana at http://localhost:3000" -ForegroundColor Green
    }
}