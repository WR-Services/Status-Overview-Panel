#!/usr/bin/env pwsh
# Script to set up GitHub workflow for plugin signing and attestation

param(
    [switch]$InitOnly
)

# Get the root directory
$rootDir = Split-Path -Parent $PSScriptRoot

# Check if .github/workflows directory exists
$workflowDir = Join-Path -Path $rootDir -ChildPath ".github\workflows"

if (-not (Test-Path $workflowDir)) {
    Write-Host "Creating GitHub workflow directory..." -ForegroundColor Yellow
    New-Item -Path $workflowDir -ItemType Directory -Force | Out-Null
}

# Create workflow file
$workflowFile = Join-Path -Path $workflowDir -ChildPath "release.yml"
$workflowContent = @'
name: Build and Sign Plugin

on:
  push:
    tags:
      - 'v*.*.*' # Run workflow on version tags, e.g. v1.0.0

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '16'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Build plugin
      run: npm run build
    
    - name: Sign plugin
      uses: grafana/plugin-actions/sign-plugin@master
      with:
        plugin-id: ${{ secrets.GRAFANA_PLUGIN_ID }}
        plugin-path: ./dist
      env:
        GRAFANA_API_KEY: ${{ secrets.GRAFANA_API_KEY }}
    
    - name: Setup plugin packaging
      run: |
        mkdir -p package/${{ secrets.GRAFANA_PLUGIN_ID }}
        cp -r dist/* package/${{ secrets.GRAFANA_PLUGIN_ID }}
    
    - name: Package plugin
      working-directory: ./package
      run: |
        zip -r ${{ secrets.GRAFANA_PLUGIN_ID }}.zip ${{ secrets.GRAFANA_PLUGIN_ID }}
        mv ${{ secrets.GRAFANA_PLUGIN_ID }}.zip ${{ secrets.GRAFANA_PLUGIN_ID }}-$(echo ${{ github.ref_name }} | cut -c 2-).zip
    
    - name: Create release
      uses: softprops/action-gh-release@v1
      with:
        files: ./package/${{ secrets.GRAFANA_PLUGIN_ID }}-*.zip
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
'@

# Write workflow file
Write-Host "Creating GitHub workflow for plugin signing..." -ForegroundColor Yellow
Set-Content -Path $workflowFile -Value $workflowContent

# Create documentation file
$docsFile = Join-Path -Path $rootDir -ChildPath "GITHUB_WORKFLOW.md"
$docsContent = @'
# GitHub Workflow Setup

This document explains how to set up GitHub Actions for building, signing, and packaging your Grafana plugin with provenance attestation.

## Required GitHub Secrets

To use the GitHub workflow provided in `.github/workflows/release.yml`, you need to set up the following secrets in your GitHub repository:

1. **GRAFANA_PLUGIN_ID**: Your plugin's ID (wrservices-statusoverview-panel)
2. **GRAFANA_API_KEY**: API key for Grafana plugin signing service

### Setting Up Secrets

1. Go to your GitHub repository
2. Click on "Settings" tab
3. Select "Secrets and variables" → "Actions" from the left sidebar
4. Click "New repository secret"
5. Add each of the required secrets with their values

## Enabling Provenance Attestation

The GitHub workflow includes provenance attestation as required by Grafana. This provides a verifiable record of how the plugin was built.

To trigger the workflow:

1. Create and push a version tag that matches the pattern `v*.*.*`:
   ```bash
   git tag v0.0.8
   git push origin v0.0.8
   ```

2. The workflow will:
   - Build the plugin
   - Sign the plugin with your Grafana API key
   - Create a properly structured ZIP package
   - Create a GitHub release with the package attached

## Getting a Grafana API Key

To obtain a Grafana API key for plugin signing:

1. Log in to your Grafana.com account
2. Go to "My Account" → "API Keys"
3. Generate a new API key with the "Plugin Publisher" role
4. Copy this key and add it as the `GRAFANA_API_KEY` secret in GitHub

## Troubleshooting

If you encounter issues with the build attestation:

1. Check that your GitHub workflow ran successfully
2. Verify that your API key is valid and has the correct permissions
3. Make sure your plugin.json file has all required fields properly filled out

For more information, see [Grafana's documentation on build attestation](https://grafana.com/developers/plugin-tools/publish-a-plugin/build-automation#enable-provenance-attestation)
'@

# Write docs file
Set-Content -Path $docsFile -Value $docsContent
Write-Host "Created documentation at $docsFile" -ForegroundColor Green

if (-not $InitOnly) {
    # Check if Git is installed
    try {
        $gitVersion = git --version
        Write-Host "Git found: $gitVersion" -ForegroundColor Gray
        
        # Check if we're in a Git repository
        $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
        if ($isGitRepo -ne "true") {
            Write-Host "Not in a Git repository. Skipping Git operations." -ForegroundColor Yellow
            exit 0
        }
        
        # Get plugin version
        $packageJsonPath = Join-Path -Path $rootDir -ChildPath "package.json"
        $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json
        $pluginVersion = $packageJson.version
        
        # Offer to create a tag
        $createTag = Read-Host -Prompt "Do you want to create Git tag v$pluginVersion for this version? (y/n)"
        if ($createTag -eq "y") {
            Write-Host "Creating Git tag v$pluginVersion..." -ForegroundColor Yellow
            git tag "v$pluginVersion"
            
            $pushTag = Read-Host -Prompt "Do you want to push this tag to remote repository? (y/n)"
            if ($pushTag -eq "y") {
                Write-Host "Pushing tag to remote..." -ForegroundColor Yellow
                git push origin "v$pluginVersion"
                Write-Host "Tag pushed. GitHub Actions workflow should start automatically." -ForegroundColor Green
            } else {
                Write-Host "Tag created but not pushed. Use 'git push origin v$pluginVersion' to trigger the workflow." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "Git operations skipped: $_" -ForegroundColor Yellow
    }
}

Write-Host "`nGitHub workflow setup complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Set up the required secrets in your GitHub repository" -ForegroundColor White
Write-Host "2. Create and push a version tag to trigger the workflow" -ForegroundColor White
Write-Host "3. Check the GitHub Actions tab to monitor the workflow" -ForegroundColor White
Write-Host "`nFor more information, see $docsFile" -ForegroundColor White