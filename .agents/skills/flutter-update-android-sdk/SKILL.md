---
name: update-android-sdk
description: Bumps this Flutter plugin's underlying native Android dependency to its latest released version.
user-invocable: true
---

# Flutter: Update Android Dependency

Use this skill to bump the native Android dependency consumed by this Flutter plugin to its
latest released version.

All paths below are relative to the repository root.

- **Upstream repository**: https://github.com/Adyen/adyen-android
- **Latest release**: https://github.com/Adyen/adyen-android/releases/latest
- **Dependency declaration**: `android/build.gradle`, `implementation 'com.adyen.checkout:drop-in:X.X.X'`

## Steps

1. Check the latest release tag at https://github.com/Adyen/adyen-android/releases/latest.

2. Compare with the version currently pinned in the dependency declaration file above.
   - If already on the latest version, stop here and report that no update is needed. Otherwise continue.

3. Create a branch from `main` named `feature/UpdateAndroidSdkToVX.X.X` (substitute the target version).

4. Update the dependency declaration to the latest version.

5. Update the corresponding platform badge in `README.md` to reference the new version and its
   release tag URL.

6. Update `CHANGELOG.md`:
   - In the development section, update the dependency version in the dependency versions table.
   - Follow the existing format: link to the release notes and show the version transition in bold.
   - Example row:
     `| [Android Drop-in/Components](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=Android+Components%2FDrop-in&version%5B0%5D=X.X.X) | Y.Y.Y -> **X.X.X** |`

7. Verify the bump builds:
   - Run `flutter pub get` at the repository root.
   - Run `flutter build apk --debug` from `example/` to confirm the plugin still compiles against the
     new Android dependency.
   - If the build fails, investigate whether it's due to a breaking change in the new dependency
     version before continuing.

8. Commit, push, and open a PR:
   - Commit the changes with a message such as `chore: Update Android SDK to vX.X.X`.
   - Push the branch: `git push -u origin feature/UpdateAndroidSdkToVX.X.X`.
   - Open a PR against `main` in `Adyen/adyen-flutter` with `gh pr create`, summarizing the version
     bump and linking the upstream release notes.

## Sanity checks

- Ensure no unrelated files are modified.
- Check the upstream release notes and migration guide for breaking changes that could affect the Flutter plugin.
- If the Gradle build fails or dependency resolution errors occur, try invalidating the Gradle
  cache (`cd android && ./gradlew clean`) before re-running the build.
