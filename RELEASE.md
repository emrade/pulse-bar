# PulseBar Release Guide 🚀

This document outlines the complete process for releasing a new version of PulseBar.

## Prerequisites ✅

- [ ] All features and fixes are merged to `develop` branch
- [ ] Code is tested and working on your local machine
- [ ] Version number decided (following [Semantic Versioning](https://semver.org/))
- [ ] Release notes prepared (what's new, what's fixed)

## Release Process

### 1. Prepare the Release 📋

#### 1.1 Update Version Information
Update version numbers in the following files:

**Info.plist** (`PulseBar/Info.plist`):
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>  <!-- Update this -->
<key>CFBundleVersion</key>
<string>1</string>      <!-- Increment this -->
```

**README.md** (if needed):
- Update download link if version format changes
- Update any version-specific instructions

#### 1.2 Test the Build
```bash
# Clean previous builds
rm -rf DerivedData
rm -rf *.app
rm -rf *.zip

# Build and test locally (using custom DerivedData path)
xcodebuild -project PulseBar.xcodeproj \
  -scheme PulseBar \
  -configuration Release \
  -derivedDataPath ./DerivedData \
  clean build

# Test the app launches and works correctly
open DerivedData/Build/Products/Release/PulseBar.app
```

#### 1.3 Prepare Release Notes
Create a draft of what changed since the last version:
- New features ✨
- Bug fixes 🐛
- Performance improvements ⚡
- Breaking changes ⚠️
- Dependencies updated 📦

### 2. Commit and Tag 🏷️

#### 2.1 Commit Version Updates
```bash
# Add all changes
git add .

# Commit with version bump message
git commit -m "chore: bump version to v1.0.0"

# Push to develop
git push origin develop
```

#### 2.2 Create Release Tag
```bash
# Create annotated tag with version
git tag -a v1.0.0 -m "Release v1.0.0

- New feature: System monitoring dashboard
- Bug fix: Memory usage calculation
- Performance: Reduced CPU usage by 20%"

# Push the tag (this triggers GitHub Actions)
git push origin v1.0.0
```

### 3. Automated Release Process 🤖

Once you push the tag, GitHub Actions will automatically:

1. **Checkout** the tagged version
2. **Build** the Release configuration with ad-hoc signing
3. **Create ZIP** package: `PulseBar-v1.0.0.zip`
4. **Verify** code signature is valid  
5. **Generate** release notes from commits
6. **Create** GitHub Release with:
   - ZIP download
   - Installation instructions
   - System requirements
   - Open source notice

### 4. Verify the Release ✅

#### 4.1 Check GitHub Release
1. Go to [https://github.com/emrade/pulse-bar/releases](https://github.com/emrade/pulse-bar/releases)
2. Verify the new release appears
3. Check the ZIP file is attached
4. Verify download link works
5. Review auto-generated release notes

#### 4.2 Test Installation Flow
```bash
# Download the ZIP from GitHub
curl -L -o PulseBar-test.zip \
  https://github.com/emrade/pulse-bar/releases/latest/download/PulseBar-v1.0.0.zip

# Extract and test
unzip PulseBar-test.zip
codesign -vv PulseBar.app  # Should show "valid on disk"

# Test app launches
open PulseBar.app
```

#### 4.3 Update Documentation (if needed)
- Update README.md download links if needed
- Update version badges
- Add release announcement to Discussions

### 5. Post-Release Tasks 📢

#### 5.1 Merge to Main (optional)
```bash
# If you maintain a main branch for releases
git checkout main
git merge v1.0.0
git push origin main
```

#### 5.2 Announce the Release
- Share on social media
- Post in relevant macOS communities
- Update project website (if applicable)
- Notify users via existing channels

#### 5.3 Monitor for Issues
- Watch for GitHub issues
- Monitor crash reports
- Check user feedback

## Versioning Strategy 📊

PulseBar follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (1.0.0 → 2.0.0): Breaking changes, major features
- **MINOR** version (1.0.0 → 1.1.0): New features, backwards compatible
- **PATCH** version (1.0.0 → 1.0.1): Bug fixes, security patches

### Examples:
- `v1.0.0` - Initial release
- `v1.0.1` - Bug fix release  
- `v1.1.0` - New theme added
- `v2.0.0` - Major UI redesign

## Hotfix Process 🚨

For critical bug fixes that need immediate release:

```bash
# Create hotfix branch from the problematic tag
git checkout v1.0.0
git checkout -b hotfix/v1.0.1

# Make the fix
# ... edit files ...

# Commit fix
git commit -m "fix: resolve critical memory leak"

# Tag hotfix
git tag -a v1.0.1 -m "Hotfix v1.0.1 - Critical memory leak fix"

# Push (triggers release)
git push origin v1.0.1

# Merge back to develop
git checkout develop
git merge hotfix/v1.0.1
git push origin develop
```

## Rollback Process ↩️

If a release has critical issues:

1. **Delete the problematic release** from GitHub
2. **Delete the git tag** locally and remotely:
   ```bash
   git tag -d v1.0.0
   git push origin :refs/tags/v1.0.0
   ```
3. **Fix the issues** and re-release with a new version
4. **Communicate** the rollback to users

## Release Checklist 📝

Use this checklist for every release:

### Pre-Release
- [ ] All code merged to develop
- [ ] Local build and testing completed
- [ ] Version numbers updated in Info.plist
- [ ] Release notes prepared
- [ ] No breaking changes (or documented)

### Release
- [ ] Changes committed to develop
- [ ] Git tag created with proper message
- [ ] Tag pushed to GitHub
- [ ] GitHub Actions completed successfully
- [ ] Release appears on GitHub

### Post-Release
- [ ] ZIP download tested
- [ ] App installation tested on clean system  
- [ ] Release notes reviewed and updated if needed
- [ ] Announcement prepared
- [ ] Issues monitoring started

## Troubleshooting 🔧

### GitHub Actions Failed
- Check the Actions tab for error details
- Common issues:
  - Build errors: Fix code and re-tag
  - Signing issues: Verify Xcode settings
  - ZIP creation: Check file paths

### App Won't Launch After Download
- Verify code signature: `codesign -vv PulseBar.app`
- Check app bundle structure
- Test on different macOS versions

### Missing Release Assets
- Re-run failed GitHub Actions
- Manually upload ZIP if needed
- Verify workflow permissions

## Support 💬

For release process questions:
- Check [GitHub Issues](https://github.com/emrade/pulse-bar/issues)
- Review [GitHub Actions logs](https://github.com/emrade/pulse-bar/actions)
- Contact maintainers via [Discussions](https://github.com/emrade/pulse-bar/discussions)

---

**Remember**: Every release represents your work reaching users. Take time to test thoroughly and celebrate successful launches! 🎉