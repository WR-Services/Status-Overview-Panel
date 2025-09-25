# Status Overview Panel - Packaging Documentation

This document explains how to package and distribute the Status Overview Panel plugin for Grafana.

## Prerequisites

- Node.js (v14+)
- PowerShell
- Docker (optional, for testing)

## Packaging Instructions

1. **Build and Package the Plugin**

   Run the packaging script:
   ```powershell
   .\package-plugin.ps1
   ```

   This script will:
   - Build the plugin in production mode
   - Create a clean package structure
   - Generate a ZIP file in the `package` folder
   - Calculate MD5 and SHA1 checksums for verification (Grafana only supports these formats)

2. **Output Files**

   The script generates:
   - `package/wrservices-statusoverview-panel/` - Clean plugin files
   - `package/wrservices-statusoverview-panel-[VERSION].zip` - ZIP archive for distribution
   - `package/wrservices-statusoverview-panel-[VERSION].zip.md5` - MD5 checksum file
   - `package/wrservices-statusoverview-panel-[VERSION].zip.sha1` - SHA1 checksum file

3. **Testing the Packaged Plugin**

   - Extract the ZIP to a Grafana plugins directory
   - Restart Grafana
   - Verify the plugin works as expected

## Signing the Plugin

To sign your plugin for distribution:

```powershell
.\sign-plugin.ps1 -ApiKey "your-grafana-api-key"
```

## Submission to Grafana Catalog

1. Follow the submission guidelines: https://grafana.com/docs/grafana/latest/developers/plugins/publishing-and-signing-criteria/
2. Submit your plugin: https://grafana.com/grafana/plugins/submit/
3. For plugin signing information: https://grafana.com/docs/grafana/latest/developers/plugins/sign-a-plugin/

## Development Build

For development purposes, use the rebuild script:
```powershell
.\rebuild.ps1
```

For production builds:
```powershell
.\rebuild.ps1 -Production
```

## Version Management

To update the version across all files:
```powershell
.\update-version.ps1 -NewVersion "0.0.8" -ReleaseType "production-release"
```

After updating the version, make sure to run a clean build before packaging:
```powershell
npm run clean
npm run build
.\package-plugin.ps1
```