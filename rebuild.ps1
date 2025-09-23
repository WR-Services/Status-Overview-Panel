#!/usr/bin/env pwsh
# Script to rebuild the plugin and restart the Docker containers

Write-Host "Building plugin..."
npm run build

Write-Host "Restarting Docker containers..."
docker-compose down
docker-compose up -d

Write-Host "Done! Access Grafana at http://localhost:3000"
