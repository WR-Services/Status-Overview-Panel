# Plugin Management Scripts

This directory contains PowerShell scripts for managing the Grafana Status Overview Panel plugin.

## Available Scripts

| Script | Description |
|--------|-------------|
| `build.ps1` | Builds the plugin in development or production mode |
| `clean-build.ps1` | Performs a complete clean and rebuild of the plugin |
| `package.ps1` | Creates a properly structured package for Grafana distribution |
| `analyze.ps1` | Analyzes an existing package for structural issues |
| `fix.ps1` | Fixes package structure issues in an existing package |
| `update-version.ps1` | Updates version numbers across all project files |
| `github-setup.ps1` | Sets up GitHub workflow for plugin attestation |

## Usage

The recommended way to use these scripts is through the main `plugin.ps1` script in the root directory:

```powershell
./plugin.ps1 [command] [options]
```

For example:
```powershell
./plugin.ps1 build -Production
./plugin.ps1 package
./plugin.ps1 update-version -NewVersion "0.0.8" -ReleaseType "production-release"
```

## Script Details

### build.ps1
Builds the plugin in either development or production mode.

**Parameters:**
- `-Production` - Build in production mode
- `-Clean` - Perform a clean build, removing caches

### clean-build.ps1
Performs a complete clean and rebuild of the plugin.

**Parameters:**
- `-ReinstallDeps` - Also reinstall dependencies

### package.ps1
Packages the plugin for distribution to Grafana.

**Parameters:**
- `-SkipBuild` - Skip the build step
- `-OutputFolder` - Specify output folder (default: "package")

### analyze.ps1
Analyzes an existing ZIP package to verify it meets Grafana's requirements.

**Parameters:**
- `-ZipPath` - Path to the ZIP file to analyze (required)
- `-Brief` - Show only summary information

### fix.ps1
Fixes structural issues in an existing plugin package.

**Parameters:**
- `-Version` - Version to fix (defaults to current version in package.json)
- `-OutputFolder` - Specify output folder (default: "package")

### update-version.ps1
Updates version numbers across project files.

**Parameters:**
- `-NewVersion` - New version number (required)
- `-ReleaseType` - Release type ("dev-release" or "production-release")
- `-ReleaseDate` - Release date (defaults to today)