# Code Signing and Notarization Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Enable code signing and notarization for macOS releases so users can run the app without security warnings.

**Architecture:** Use GitHub Actions with Developer ID Application certificate for signing and App Store Connect API keys for notarization. Credentials stored as GitHub secrets, workflow handles keychain management and notarization submission.

**Tech Stack:** Xcode command-line tools (xcodebuild, codesign, notarytool), GitHub Actions secrets, App Store Connect API

---

## Task 1: Set Up GitHub Secrets

**Files:**
- None (GitHub web UI or CLI)

**Step 1: Prepare secret values**

You'll need these 6 secrets. Have ready:
- Your Developer ID Application certificate (.p12 file)
- Password for that certificate
- Your Apple Team ID (10-character string)
- App Store Connect API Key ID
- App Store Connect Issuer ID
- App Store Connect API Key (.p8 file)

**Step 2: Upload certificate secret**

```bash
# Convert .p12 to base64 and upload (replace <path-to-cert.p12>)
base64 -i <path-to-cert.p12> | gh secret set CERTIFICATE_BASE64
```

Expected: "✓ Set Actions secret CERTIFICATE_BASE64 for harperreed/ma"

**Step 3: Upload certificate password**

```bash
# Upload password (replace <your-password>)
echo -n '<your-password>' | gh secret set P12_PASSWORD
```

Expected: "✓ Set Actions secret P12_PASSWORD for harperreed/ma"

**Step 4: Upload Team ID**

```bash
# Upload Team ID (replace <your-team-id>)
echo -n '<your-team-id>' | gh secret set TEAM_ID
```

Expected: "✓ Set Actions secret TEAM_ID for harperreed/ma"

**Step 5: Upload API Key ID**

```bash
# Upload API Key ID (replace <your-key-id>)
echo -n '<your-key-id>' | gh secret set APP_STORE_CONNECT_API_KEY_ID
```

Expected: "✓ Set Actions secret APP_STORE_CONNECT_API_KEY_ID for harperreed/ma"

**Step 6: Upload Issuer ID**

```bash
# Upload Issuer ID (replace <your-issuer-id>)
echo -n '<your-issuer-id>' | gh secret set APP_STORE_CONNECT_ISSUER_ID
```

Expected: "✓ Set Actions secret APP_STORE_CONNECT_ISSUER_ID for harperreed/ma"

**Step 7: Upload API Key file**

```bash
# Convert .p8 to base64 and upload (replace <path-to-key.p8>)
base64 -i <path-to-key.p8> | gh secret set APP_STORE_CONNECT_API_KEY
```

Expected: "✓ Set Actions secret APP_STORE_CONNECT_API_KEY for harperreed/ma"

**Step 8: Verify secrets**

```bash
gh secret list
```

Expected: All 6 secrets listed

---

## Task 2: Update Workflow - Code Signing

**Files:**
- Modify: `.github/workflows/release.yml:31-79`

**Step 1: Replace unsigned build with signed build**

Replace the entire "Build app (unsigned)" section (lines 68-79) and uncomment/update the code signing section (lines 31-66).

Update `.github/workflows/release.yml` to replace lines 31-79 with:

```yaml
      - name: Import Code Signing Certificate
        env:
          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
          CERTIFICATE_BASE64: ${{ secrets.CERTIFICATE_BASE64 }}
        run: |
          # Create temporary keychain
          KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
          KEYCHAIN_PASSWORD=$(openssl rand -base64 32)

          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          # Import certificate
          echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
          security import certificate.p12 -k "$KEYCHAIN_PATH" -P "$P12_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          # Set as default keychain
          security list-keychains -d user -s "$KEYCHAIN_PATH"
          rm certificate.p12

      - name: Build and sign app
        env:
          TEAM_ID: ${{ secrets.TEAM_ID }}
        run: |
          xcodebuild -project MusicAssistantPlayer.xcodeproj \
            -scheme MusicAssistantPlayer \
            -configuration Release \
            -derivedDataPath build \
            -onlyUsePackageVersionsFromResolvedFile \
            CODE_SIGN_IDENTITY="Developer ID Application" \
            DEVELOPMENT_TEAM="$TEAM_ID" \
            CODE_SIGN_STYLE=Manual \
            clean build
```

**Step 2: Verify syntax**

```bash
# Check YAML is valid
cat .github/workflows/release.yml | grep -A 5 "Import Code Signing"
```

Expected: No YAML syntax errors, proper indentation

**Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "feat: add code signing to release workflow"
```

---

## Task 3: Update Workflow - Notarization

**Files:**
- Modify: `.github/workflows/release.yml:84-101`

**Step 1: Replace commented notarization with API key version**

Replace the commented notarization section (lines 84-101) with API key implementation:

```yaml
      - name: Notarize DMG
        env:
          API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          API_KEY_BASE64: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          DMG_FILE=$(ls MusicAssistantPlayer-*.dmg)

          # Write API key to temporary file
          echo "$API_KEY_BASE64" | base64 --decode > AuthKey.p8

          # Submit for notarization with API key
          xcrun notarytool submit "$DMG_FILE" \
            --key AuthKey.p8 \
            --key-id "$API_KEY_ID" \
            --issuer "$API_ISSUER_ID" \
            --wait

          # Staple the notarization ticket
          xcrun stapler staple "$DMG_FILE"

          # Clean up API key
          rm AuthKey.p8
```

**Step 2: Verify syntax**

```bash
# Check YAML is valid
cat .github/workflows/release.yml | grep -A 5 "Notarize DMG"
```

Expected: No YAML syntax errors, proper indentation

**Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "feat: add notarization with API key to release workflow"
```

**Step 4: Push changes**

```bash
git push
```

Expected: Changes pushed to main

---

## Task 4: Test Signing and Notarization

**Files:**
- None (creating git tag)

**Step 1: Create test tag**

```bash
git tag v0.2.5
git push origin v0.2.5
```

Expected: Tag pushed, workflow triggered

**Step 2: Monitor workflow**

```bash
gh run watch
```

Expected:
- "Import Code Signing Certificate" step succeeds
- "Build and sign app" step succeeds
- "Notarize DMG" step succeeds (may take 2-5 minutes)
- "Create GitHub Release" step succeeds

**Step 3: Verify signed DMG**

```bash
# Download the DMG
gh release download v0.2.5

# Check code signature
codesign -dv --verbose=4 MusicAssistantPlayer-0.1.0.dmg

# Check notarization
spctl -a -vv -t install MusicAssistantPlayer-0.1.0.dmg
```

Expected:
- Code signature shows "Developer ID Application"
- spctl shows "accepted" and "Notarized Developer ID"

**Step 4: Test installation**

- Double-click DMG
- Drag app to Applications
- Open app normally (no right-click needed)

Expected: App opens without security warnings

---

## Troubleshooting

**If signing fails:**
- Check that CERTIFICATE_BASE64 and P12_PASSWORD are correct
- Verify certificate is "Developer ID Application" type
- Check TEAM_ID matches the certificate

**If notarization fails:**
- Check API Key has "Developer" role in App Store Connect
- Verify API_KEY_ID, API_ISSUER_ID are correct
- Check that .p8 file was encoded correctly

**If stapling fails:**
- Notarization must complete successfully first
- DMG file name must match what was notarized
