#!/usr/bin/env pwsh
# Quick script to build and deploy the plugin

Write-Host "🚀 Building and Deploying Grafana Plugin..." -ForegroundColor Cyan

# Build the plugin
Write-Host "📦 Building plugin..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "✅ Build successful!" -ForegroundColor Green

# Restart Docker
Write-Host "🐳 Restarting Docker containers..." -ForegroundColor Yellow
docker-compose down
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker down failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker up failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "✅ Docker containers restarted!" -ForegroundColor Green

Write-Host "🎉 Done! Access Grafana at http://localhost:3000" -ForegroundColor Cyan
