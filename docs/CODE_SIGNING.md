# Code Signing Setup

This document explains how to set up code signing and notarization for the GitHub Actions release workflow.

## Current State

The app is currently built **unsigned**. Users will see a security warning on first launch and need to right-click → Open to run the app.

## Setting Up Code Signing

When you're ready to sign the app, follow these steps:

### 1. Prerequisites

- Apple Developer account ($99/year)
- Developer ID Application certificate
- App-specific password for notarization

### 2. Export Your Certificate

On your Mac with the signing certificate installed:

```bash
# Export certificate to p12 file
# Keychain Access → My Certificates → Right-click certificate → Export

# Convert to base64 for GitHub Secrets
base64 -i certificate.p12 | pbcopy
```

### 3. Create App-Specific Password

1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. Security → App-Specific Passwords → Generate
4. Save the generated password

### 4. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `CERTIFICATE_BASE64` | Base64-encoded p12 certificate | From step 2 above |
| `P12_PASSWORD` | Password for p12 file | Password you set when exporting |
| `DEVELOPMENT_TEAM` | Your Team ID | developer.apple.com → Membership |
| `CODE_SIGN_IDENTITY` | Certificate name | Usually "Developer ID Application: Your Name (TEAM_ID)" |
| `APPLE_ID` | Your Apple ID email | Your Apple ID email |
| `APPLE_ID_PASSWORD` | App-specific password | From step 3 above |
| `TEAM_ID` | Your Team ID | Same as DEVELOPMENT_TEAM |

### 5. Enable Signing in Workflow

Edit `.github/workflows/release.yml`:

1. **Uncomment the certificate import step** (lines ~30-47)
2. **Uncomment the signed build step** (lines ~49-60)
3. **Comment out or remove the unsigned build step** (lines ~63-72)
4. **Uncomment the notarization step** (lines ~77-93)

### 6. Test the Workflow

```bash
# Create a test tag
git tag v0.1.1-test
git push origin v0.1.1-test

# Monitor the workflow in GitHub Actions tab
# Check that signing and notarization complete successfully
```

## Verification

After signing is enabled:

1. Download the DMG from the release
2. Open it and install the app
3. Launch the app - it should open without security warnings
4. Verify the signature:

```bash
codesign -dvv /Applications/MusicAssistantPlayer.app
spctl -a -vv /Applications/MusicAssistantPlayer.app
```

Expected output:
- `codesign`: Should show your Developer ID
- `spctl`: Should show "accepted" and "source=Notarized Developer ID"

## Troubleshooting

### Certificate Import Fails

- Check that `CERTIFICATE_BASE64` is valid base64
- Verify `P12_PASSWORD` matches the export password
- Ensure certificate is "Developer ID Application" not "Apple Development"

### Notarization Fails

- Verify `APPLE_ID` and `APPLE_ID_PASSWORD` are correct
- Check that app-specific password hasn't expired
- Review notarization log: `xcrun notarytool log <submission-id>`

### App Shows "Damaged" Error

- Usually means signature is invalid or notarization didn't staple
- Re-run notarization and stapling steps
- Check that you're not modifying the app after signing

## Resources

- [Apple Developer Documentation - Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub Actions - Code Signing for macOS](https://docs.github.com/en/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development)
