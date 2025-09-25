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

For more information, see [Grafana's documentation on build attestation](https://grafana.com/developers/plugin-tools/publish-a-plugin/build-automation#enable-provenance-attestation).