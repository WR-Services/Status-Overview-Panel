#!/usr/bin/env pwsh
# Script to rebuild the plugin and restart the Docker containers

param(
    [switch]$Production
)

if ($Production) {
    Write-Host "Building plugin in production mode..." -ForegroundColor Cyan
    npm run build -- --production
} else {
    Write-Host "Building plugin in development mode..." -ForegroundColor Cyan
    npm run build
}

Write-Host "Restarting Docker containers..." -ForegroundColor Yellow
docker-compose down
docker-compose up -d

Write-Host "Done! Access Grafana at http://localhost:3000" -ForegroundColor Green
