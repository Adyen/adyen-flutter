---
name: flutter-update-ios-sdk
description: Bumps this Flutter plugin's underlying native iOS dependency to its latest released version.
user-invocable: true
---

# Flutter: Update iOS Dependency

Use this skill to bump the native iOS dependency consumed by this Flutter plugin to its latest
released version.

All paths below are relative to the repository root.

- **Upstream repository**: https://github.com/Adyen/adyen-ios
- **Latest release**: https://github.com/Adyen/adyen-ios/releases/latest
- **CocoaPods declaration**: `ios/adyen_checkout.podspec`, `s.dependency 'Adyen', 'X.X.X'`
- **Swift Package Manager pin**: `ios/adyen_checkout/Package.swift`, `exact` version of `adyen-ios`

## Steps

1. Check the latest release version at https://github.com/Adyen/adyen-ios/releases/latest.

2. Compare with the version currently pinned in the CocoaPods declaration file above.
   - If already on the latest version, stop here and report that no update is needed. Otherwise continue.

3. Create a branch from `main` named `feature/UpdateIosSdkToVX.X.X` (substitute the target version).

4. Update the CocoaPods dependency declaration to the latest version.

5. Update the Swift Package Manager pin to the same latest version.

6. Update the corresponding platform badge in `README.md` to reference the new version and its
   release tag URL.

7. Update `CHANGELOG.md`:
   - In the development section, update the dependency version in the dependency versions table.
   - Example row:
     `| [iOS Drop-in/Components](https://docs.adyen.com/online-payments/release-notes/#releaseNote=YYYY-MM-DD-ios-componentsdrop-in-X.X.X) | X.X.X |`

8. Verify the bump builds:
   - Run `flutter pub get` at the repository root.
   - Run `pod install` from `example/ios/` to resolve the new CocoaPods dependency.
   - Run `flutter build ios --debug --simulator` from `example/` to confirm the plugin still compiles
     against the new iOS dependency.
   - If the build fails, investigate whether it's due to a breaking change in the new dependency
     version before continuing.

9. Commit, push, and open a PR:
   - Commit the changes with a message such as `chore: Update iOS SDK to vX.X.X`.
   - Push the branch: `git push -u origin feature/UpdateIosSdkToVX.X.X`.
   - Open a PR against `main` in `Adyen/adyen-flutter` with `gh pr create`, summarizing the version
     bump and linking the upstream release notes.

## Sanity checks

- Ensure no unrelated files are modified.
- If pod installation fails, try `pod repo update` first.
- Check the [Adyen iOS migration guide](https://docs.adyen.com/online-payments/build-your-integration/?platform=iOS&integration=Drop-in#migration-guide) for any breaking changes.
- Verify minimum iOS version requirements have not changed.
