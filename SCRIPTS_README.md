# Grafana Plugin Management Scripts

This project includes a comprehensive set of tools for developing, building, packaging, and distributing a Grafana plugin.

## Quick Start

All plugin management tasks can be performed using the central `plugin.ps1` script:

```powershell
# Show all available commands
./plugin.ps1 help

# Build the plugin
./plugin.ps1 build -Production

# Package the plugin for distribution
./plugin.ps1 package

# Update the plugin version
./plugin.ps1 update-version -NewVersion "0.0.8" -ReleaseType "production-release"
```

## Directory Structure

```
Status-Overview-Panel/
├── dist/                # Built plugin files
├── scripts/             # Plugin management scripts
│   ├── analyze.ps1      # Analyzes package structure
│   ├── build.ps1        # Builds the plugin
│   ├── fix.ps1          # Fixes package structure issues
│   ├── github-setup.ps1 # Sets up GitHub workflow
│   ├── package.ps1      # Creates distributable package
│   ├── update-version.ps1 # Updates version numbers
│   └── README.md        # Documentation for scripts
├── package/             # Output directory for packages
├── plugin.ps1           # Main entry point for all commands
└── GITHUB_WORKFLOW.md   # GitHub workflow documentation
```

## Available Commands

### Build

Build the plugin in development or production mode:

```powershell
./plugin.ps1 build
./plugin.ps1 build -Production
./plugin.ps1 build -Clean
```

### Clean Build

Perform a complete clean and rebuild of the plugin:

```powershell
./plugin.ps1 clean-build
./plugin.ps1 clean-build -ReinstallDeps
```

### Package

Package the plugin for distribution:

```powershell
./plugin.ps1 package
```

### Analyze Package Structure

Analyze an existing package for structural issues:

```powershell
./plugin.ps1 analyze -ZipPath "package/wrservices-statusoverview-panel-0.0.8.zip"
```

### Fix Package Structure

Fix structural issues in an existing package:

```powershell
./plugin.ps1 fix -Version "0.0.8"
```

### Update Version

Update version numbers across all project files:

```powershell
./plugin.ps1 update-version -NewVersion "0.0.8" -ReleaseType "production-release"
```

### GitHub Workflow Setup

Set up GitHub Actions workflow for plugin signing and attestation:

```powershell
./plugin.ps1 github-setup
```

## Grafana Plugin Requirements

For a package to be accepted by Grafana:

1. The ZIP file must contain exactly one directory, named after the plugin ID
2. That directory must contain all plugin files
3. Required files: `plugin.json` and `module.js`
4. For signing, provenance attestation is required (via GitHub workflow)

## Troubleshooting

If you encounter package structure issues:

1. Run `./plugin.ps1 analyze` to identify the problem
2. Fix with `./plugin.ps1 fix`
3. Verify the fix with `./plugin.ps1 analyze` again

For Grafana signing issues, ensure your GitHub workflow is set up correctly:

```powershell
./plugin.ps1 github-setup
```

See `GITHUB_WORKFLOW.md` for detailed instructions on GitHub setup.