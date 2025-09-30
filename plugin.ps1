#!/usr/bin/env pwsh
# Grafana Plugin Management Script
# Main entry point for plugin management tasks

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("build", "package", "analyze", "fix", "update-version", "github-setup", "clean-build", "help", "menu")]
    [string]$Command = "menu",
    
    [Parameter(ValueFromRemainingArguments=$true)]
    $RemainingArgs
)

# Configuration
$scriptDir = Join-Path -Path $PSScriptRoot -ChildPath "scripts"
$pluginName = "wrservices-statusoverview-panel"

# Ensure scripts directory exists
if (-not (Test-Path $scriptDir)) {
    Write-Host "Scripts directory not found: $scriptDir" -ForegroundColor Red
    exit 1
}

function Show-Help {
    Write-Host "Grafana Plugin Management Tool" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: ./plugin.ps1 [command] [options]" -ForegroundColor Yellow
    Write-Host "       ./plugin.ps1              (launches interactive menu)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  menu             - Show interactive menu (default)" -ForegroundColor White
    Write-Host "  build            - Build the plugin in development or production mode" -ForegroundColor White
    Write-Host "    -Production    - Build in production mode" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  package          - Package the plugin for distribution" -ForegroundColor White
    Write-Host ""
    Write-Host "  analyze          - Analyze an existing package structure" -ForegroundColor White
    Write-Host "    -ZipPath       - Path to the ZIP file to analyze" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  fix              - Fix an existing package structure" -ForegroundColor White
    Write-Host "    -Version       - Version to fix (defaults to current version)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  update-version   - Update plugin version across all files" -ForegroundColor White
    Write-Host "    -NewVersion    - New version number (e.g., '0.0.8')" -ForegroundColor Gray
    Write-Host "    -ReleaseType   - Release type ('dev-release' or 'production-release')" -ForegroundColor Gray
    Write-Host "    -ReleaseDate   - Release date (defaults to today)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  github-setup     - Set up GitHub workflow for plugin attestation" -ForegroundColor White
    Write-Host "    -InitOnly      - Only create files, skip Git operations" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  clean-build      - Perform a complete clean and rebuild" -ForegroundColor White
    Write-Host "    -ReinstallDeps - Also reinstall dependencies" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  help             - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  ./plugin.ps1 build -Production" -ForegroundColor White
    Write-Host "  ./plugin.ps1 package" -ForegroundColor White
    Write-Host "  ./plugin.ps1 update-version -NewVersion '0.0.8' -ReleaseType 'production-release'" -ForegroundColor White
    Write-Host "  ./plugin.ps1 analyze -ZipPath 'package/wrservices-statusoverview-panel-0.0.8.zip'" -ForegroundColor White
}

# Check for scripts directory
if (-not (Test-Path $scriptDir)) {
    Write-Host "Creating scripts directory..." -ForegroundColor Yellow
    New-Item -Path $scriptDir -ItemType Directory | Out-Null
}

# Handle commands
if ($Command -eq "menu") {
    # Show interactive menu
    $menuResult = Show-InteractiveMenu
    
    # If result is a command, execute it
    if ($menuResult -and $menuResult.Command) {
        $Command = $menuResult.Command
        $RemainingArgs = $menuResult.Args
    } else {
        exit 0
    }
}

switch ($Command) {
    "build" {
        $scriptPath = Join-Path -Path $scriptDir -ChildPath "build.ps1"
        & $scriptPath @RemainingArgs
    }
    "package" {
        $scriptPath = Join-Path -Path $scriptDir -ChildPath "package.ps1"
        & $scriptPath @RemainingArgs
    }
    "analyze" {
        $scriptPath = Join-Path -Path $scriptDir -ChildPath "analyze.ps1"
        
        # If no args provided, try to find the latest package
        if ($RemainingArgs.Count -eq 0) {
            $latestPackage = Get-ChildItem -Path "package" -Filter "$pluginName-*.zip" | 
                             Sort-Object LastWriteTime -Descending | 
                             Select-Object -First 1
            
            if ($latestPackage) {
                Write-Host "Found latest package: $($latestPackage.FullName)" -ForegroundColor Yellow
                & $scriptPath -ZipPath $latestPackage.FullName
            }
            else {
                Write-Host "No package found. Please specify a ZIP file with -ZipPath." -ForegroundColor Red
                exit 1
            }
        }
        else {
            & $scriptPath @RemainingArgs
        }
    }
    "fix" {
        $scriptPath = Join-Path -Path $scriptDir -ChildPath "fix.ps1"
        & $scriptPath @RemainingArgs
    }
    "update-version" {
        $scriptPath = Join-Path -Path $scriptDir -ChildPath "update-version.ps1"
        & $scriptPath @RemainingArgs
    }
    "github-setup" {
        $scriptPath = Join-Path -Path $scriptDir -ChildPath "github-setup.ps1"
        & $scriptPath @RemainingArgs
    }
    "clean-build" {
        $scriptPath = Join-Path -Path $scriptDir -ChildPath "clean-build.ps1"
        & $scriptPath @RemainingArgs
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Show-Help
        exit 1
    }
}

function Show-InteractiveMenu {
    Clear-Host
    
    $menuTitle = @"
   ____           __                  ____  _             _       
  / ___| _ __ __ _/ _| __ _ _ __     |  _ \| |_   _  __ _(_)_ __  
 | |  _ | '__/ _` | |_ / _` | '_ \    | |_) | | | | |/ _` | | '_ \ 
 | |_| || | | (_| |  _| (_| | | | |   |  __/| | |_| | (_| | | | | |
  \____|_|  \__,_|_|  \__,_|_| |_|   |_|   |_|\__,_|\__, |_|_| |_|
                                                     |___/         
  __  __                                                   _   
 |  \/  | __ _ _ __   __ _  __ _  ___ _ __ ___   ___ _ __ | |_ 
 | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '_ ` _ \ / _ \ '_ \| __|
 | |  | | (_| | | | | (_| | (_| |  __/ | | | | |  __/ | | | |_ 
 |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_| |_| |_|\___|_| |_|\__|
                           |___/                               
"@
    
    Write-Host $menuTitle -ForegroundColor Cyan
    Write-Host "Plugin: wrservices-statusoverview-panel" -ForegroundColor Yellow
    
    # Get the current version
    try {
        $packageJsonPath = Join-Path -Path $PSScriptRoot -ChildPath "package.json"
        $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json
        Write-Host "Current Version: v$($packageJson.version)" -ForegroundColor Yellow
    } catch {
        Write-Host "Version information unavailable" -ForegroundColor DarkGray
    }
    
    Write-Host "`nSelect an option:`n" -ForegroundColor White
    
    Write-Host "  [1] Build Plugin" -ForegroundColor Green
    Write-Host "      Build the plugin (development or production mode)" -ForegroundColor DarkGray
    
    Write-Host "  [2] Clean Build" -ForegroundColor Green
    Write-Host "      Perform complete clean and rebuild" -ForegroundColor DarkGray
    
    Write-Host "  [3] Package Plugin" -ForegroundColor Green
    Write-Host "      Create a distributable package for Grafana" -ForegroundColor DarkGray
    
    Write-Host "  [4] Update Version" -ForegroundColor Green
    Write-Host "      Update version numbers across project files" -ForegroundColor DarkGray
    
    Write-Host "  [5] Analyze Package" -ForegroundColor Green
    Write-Host "      Check if a package meets Grafana's requirements" -ForegroundColor DarkGray
    
    Write-Host "  [6] Fix Package" -ForegroundColor Green
    Write-Host "      Repair package structure issues" -ForegroundColor DarkGray
    
    Write-Host "  [7] GitHub Workflow Setup" -ForegroundColor Green
    Write-Host "      Configure GitHub Actions for plugin attestation" -ForegroundColor DarkGray
    
    Write-Host "  [8] Help" -ForegroundColor Green
    Write-Host "      Show detailed help for all commands" -ForegroundColor DarkGray
    
    Write-Host "  [0] Exit" -ForegroundColor Red
    
    $choice = Read-Host "`nEnter your choice (0-8)"
    
    switch ($choice) {
        "0" { 
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit 0
        }
        "1" { 
            $buildMode = Show-BuildOptions
            if ($buildMode -eq "back") {
                Show-InteractiveMenu
                return
            }
            return @{ Command = "build"; Args = $buildMode }
        }
        "2" { 
            $cleanBuildOptions = Show-CleanBuildOptions
            if ($cleanBuildOptions -eq "back") {
                Show-InteractiveMenu
                return
            }
            return @{ Command = "clean-build"; Args = $cleanBuildOptions }
        }
        "3" { 
            return @{ Command = "package"; Args = $null }
        }
        "4" { 
            $versionOptions = Show-VersionOptions
            if ($versionOptions -eq "back") {
                Show-InteractiveMenu
                return
            }
            return @{ Command = "update-version"; Args = $versionOptions }
        }
        "5" { 
            $analyzeOptions = Show-AnalyzeOptions
            if ($analyzeOptions -eq "back") {
                Show-InteractiveMenu
                return
            }
            return @{ Command = "analyze"; Args = $analyzeOptions }
        }
        "6" { 
            $fixOptions = Show-FixOptions
            if ($fixOptions -eq "back") {
                Show-InteractiveMenu
                return
            }
            return @{ Command = "fix"; Args = $fixOptions }
        }
        "7" { 
            return @{ Command = "github-setup"; Args = $null }
        }
        "8" { 
            return @{ Command = "help"; Args = $null }
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Show-InteractiveMenu
        }
    }
}

function Show-BuildOptions {
    Clear-Host
    Write-Host "Build Options" -ForegroundColor Cyan
    Write-Host "=============" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Development Build" -ForegroundColor Green
    Write-Host "      Standard development build" -ForegroundColor DarkGray
    
    Write-Host "  [2] Production Build" -ForegroundColor Green
    Write-Host "      Optimized production build" -ForegroundColor DarkGray
    
    Write-Host "  [3] Clean Production Build" -ForegroundColor Green
    Write-Host "      Clean and rebuild for production" -ForegroundColor DarkGray
    
    Write-Host "  [0] Back to Main Menu" -ForegroundColor Yellow
    
    $choice = Read-Host "`nEnter your choice (0-3)"
    
    switch ($choice) {
        "0" { return "back" }
        "1" { return @() }
        "2" { return @("-Production") }
        "3" { return @("-Production", "-Clean") }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            return Show-BuildOptions
        }
    }
}

function Show-CleanBuildOptions {
    Clear-Host
    Write-Host "Clean Build Options" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Standard Clean Build" -ForegroundColor Green
    Write-Host "      Remove build artifacts and rebuild" -ForegroundColor DarkGray
    
    Write-Host "  [2] Complete Clean Build" -ForegroundColor Green
    Write-Host "      Also reinstall dependencies (longer)" -ForegroundColor DarkGray
    
    Write-Host "  [0] Back to Main Menu" -ForegroundColor Yellow
    
    $choice = Read-Host "`nEnter your choice (0-2)"
    
    switch ($choice) {
        "0" { return "back" }
        "1" { return @() }
        "2" { return @("-ReinstallDeps") }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            return Show-CleanBuildOptions
        }
    }
}

function Show-VersionOptions {
    Clear-Host
    Write-Host "Version Update Options" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get current version
    try {
        $packageJsonPath = Join-Path -Path $PSScriptRoot -ChildPath "package.json"
        $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json
        $currentVersion = $packageJson.version
        Write-Host "Current Version: $currentVersion" -ForegroundColor Yellow
        
        # Parse version components
        $versionParts = $currentVersion -split '\.'
        $major = [int]$versionParts[0]
        $minor = [int]$versionParts[1]
        $patch = [int]$versionParts[2]
        
        # Calculate next versions
        $nextPatch = "$major.$minor.$($patch + 1)"
        $nextMinor = "$major.$($minor + 1).0"
        $nextMajor = "$($major + 1).0.0"
        
        Write-Host "  [1] Patch Version: $nextPatch (dev-release)" -ForegroundColor Green
        Write-Host "  [2] Minor Version: $nextMinor (dev-release)" -ForegroundColor Green
        Write-Host "  [3] Major Version: $nextMajor (dev-release)" -ForegroundColor Green
        Write-Host "  [4] Production Release (current version)" -ForegroundColor Green
        Write-Host "  [5] Custom Version" -ForegroundColor Green
        Write-Host "  [0] Back to Main Menu" -ForegroundColor Yellow
        
        $choice = Read-Host "`nEnter your choice (0-5)"
        
        switch ($choice) {
            "0" { return "back" }
            "1" { return @("-NewVersion", $nextPatch, "-ReleaseType", "dev-release") }
            "2" { return @("-NewVersion", $nextMinor, "-ReleaseType", "dev-release") }
            "3" { return @("-NewVersion", $nextMajor, "-ReleaseType", "dev-release") }
            "4" { return @("-NewVersion", $currentVersion, "-ReleaseType", "production-release") }
            "5" {
                $customVersion = Read-Host "Enter custom version number (format: X.Y.Z)"
                $releaseType = Read-Host "Release type (dev/prod) [dev]"
                
                if ($releaseType -eq "prod") {
                    return @("-NewVersion", $customVersion, "-ReleaseType", "production-release")
                } else {
                    return @("-NewVersion", $customVersion, "-ReleaseType", "dev-release")
                }
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
                return Show-VersionOptions
            }
        }
    } catch {
        Write-Host "Error reading version information: $_" -ForegroundColor Red
        $customVersion = Read-Host "Enter version number (format: X.Y.Z)"
        $releaseType = Read-Host "Release type (dev/prod) [dev]"
        
        if ($releaseType -eq "prod") {
            return @("-NewVersion", $customVersion, "-ReleaseType", "production-release")
        } else {
            return @("-NewVersion", $customVersion, "-ReleaseType", "dev-release")
        }
    }
}

function Show-AnalyzeOptions {
    Clear-Host
    Write-Host "Analyze Package Options" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host ""
    
    $packageDir = Join-Path -Path $PSScriptRoot -ChildPath "package"
    
    # Find ZIP files in the package directory
    if (Test-Path $packageDir) {
        $zipFiles = Get-ChildItem -Path $packageDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending
        
        if ($zipFiles.Count -gt 0) {
            Write-Host "Available packages:" -ForegroundColor Yellow
            
            for ($i = 0; $i -lt [Math]::Min(5, $zipFiles.Count); $i++) {
                $file = $zipFiles[$i]
                $fileSize = [Math]::Round($file.Length / 1KB, 0)
                Write-Host "  [$($i+1)] $($file.Name) ($fileSize KB, $($file.LastWriteTime))" -ForegroundColor Green
            }
            
            Write-Host "  [C] Custom path" -ForegroundColor Green
            Write-Host "  [0] Back to Main Menu" -ForegroundColor Yellow
            
            $choice = Read-Host "`nEnter your choice (0-$([Math]::Min(5, $zipFiles.Count)), C)"
            
            if ($choice -eq "0") {
                return "back"
            } elseif ($choice -eq "C" -or $choice -eq "c") {
                $customPath = Read-Host "Enter path to ZIP file"
                if (-not (Test-Path $customPath)) {
                    Write-Host "File not found. Please try again." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                    return Show-AnalyzeOptions
                }
                return @("-ZipPath", $customPath)
            } elseif ([int]::TryParse($choice, [ref]$null) -and [int]$choice -ge 1 -and [int]$choice -le [Math]::Min(5, $zipFiles.Count)) {
                $selectedFile = $zipFiles[[int]$choice-1]
                return @("-ZipPath", $selectedFile.FullName)
            } else {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
                return Show-AnalyzeOptions
            }
        } else {
            Write-Host "No packages found in the package directory." -ForegroundColor Yellow
            Write-Host "  [C] Custom path" -ForegroundColor Green
            Write-Host "  [0] Back to Main Menu" -ForegroundColor Yellow
            
            $choice = Read-Host "`nEnter your choice (C, 0)"
            
            if ($choice -eq "0") {
                return "back"
            } elseif ($choice -eq "C" -or $choice -eq "c") {
                $customPath = Read-Host "Enter path to ZIP file"
                if (-not (Test-Path $customPath)) {
                    Write-Host "File not found. Please try again." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                    return Show-AnalyzeOptions
                }
                return @("-ZipPath", $customPath)
            } else {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
                return Show-AnalyzeOptions
            }
        }
    } else {
        Write-Host "Package directory not found." -ForegroundColor Yellow
        Write-Host "  [C] Custom path" -ForegroundColor Green
        Write-Host "  [0] Back to Main Menu" -ForegroundColor Yellow
        
        $choice = Read-Host "`nEnter your choice (C, 0)"
        
        if ($choice -eq "0") {
            return "back"
        } elseif ($choice -eq "C" -or $choice -eq "c") {
            $customPath = Read-Host "Enter path to ZIP file"
            if (-not (Test-Path $customPath)) {
                Write-Host "File not found. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
                return Show-AnalyzeOptions
            }
            return @("-ZipPath", $customPath)
        } else {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            return Show-AnalyzeOptions
        }
    }
}

function Show-FixOptions {
    Clear-Host
    Write-Host "Fix Package Options" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get current version
    try {
        $packageJsonPath = Join-Path -Path $PSScriptRoot -ChildPath "package.json"
        $packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json
        $currentVersion = $packageJson.version
        Write-Host "Current Version: $currentVersion" -ForegroundColor Yellow
        
        $packageDir = Join-Path -Path $PSScriptRoot -ChildPath "package"
        $packagePath = Join-Path -Path $packageDir -ChildPath "wrservices-statusoverview-panel-$currentVersion.zip"
        
        if (Test-Path $packagePath) {
            Write-Host "Package found: $packagePath" -ForegroundColor Green
            Write-Host "  [1] Fix Current Version ($currentVersion)" -ForegroundColor Green
        } else {
            Write-Host "Package for current version not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error reading version information" -ForegroundColor Yellow
    }
    
    Write-Host "  [2] Custom Version" -ForegroundColor Green
    Write-Host "  [0] Back to Main Menu" -ForegroundColor Yellow
    
    $choice = Read-Host "`nEnter your choice (0-2)"
    
    switch ($choice) {
        "0" { return "back" }
        "1" {
            if (Test-Path $packagePath) {
                return @("-Version", $currentVersion)
            } else {
                Write-Host "Package for version $currentVersion not found." -ForegroundColor Red
                Start-Sleep -Seconds 1
                return Show-FixOptions
            }
        }
        "2" {
            $customVersion = Read-Host "Enter version to fix"
            return @("-Version", $customVersion)
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
            return Show-FixOptions
        }
    }
}