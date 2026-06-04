# Google Pay Android 5.9+ Cleanup — Implementation Plan

## Problem Statement

`Adyen/adyen-flutter` already bumped the Android SDK to 5.9.0 in commit `7e16b508`
(2024-era) and `AdyenComponentView` is wired up in `GooglePayComponentManager`, but
the Flutter wrapper still uses APIs that are deprecated in Adyen Android 5.9.0+:

- `googlePayComponent.startGooglePayScreen(activity, requestCode)` — replaced by
  `googlePayComponent.submit()` (verified in upstream Adyen 5.19.0:
  `GooglePayComponent.kt:95: override fun submit()`).
- `handleActivityResult(...)` — no longer needed once `startGooglePayScreen` is gone.
- The `addActivityResultListener` plumbing in `AdyenCheckoutPlugin` exists *only*
  to forward results to `GooglePayComponentManager.handleGooglePayActivityResult`
  (`AdyenCheckoutPlugin.kt:166-170`).

The deprecated flow still works in 5.19.0 (the wrapper has not yet been reaped), but
every Android consumer of the Flutter plugin is one Adyen SDK bump away from a
runtime break.

## Non-Goals / Out of Scope

- iOS-side changes — there is no Google Pay in Adyen's iOS SDK; iOS is a no-op and
  stays no-op.
- Refactor to `AdyenComponentView`-rendered button (i.e. dropping the
  `RawGooglePayButton` from the `pay` package). We keep the existing Flutter
  button + call `submit()` on the native component.
- `pay_android` split / migration. `pay: '>=3.2.1 <3.3.0'` already provides what we
  use (`RawGooglePayButton`) and is not deprecated.
- Bumping any SDK version. The Android `drop-in: 5.19.0` and iOS `Adyen: 5.25.0`
  pins stay as-is.
- Refactor of Apple Pay, Card, Drop-in, or any other component.
- **Dropping the `GooglePayComponent.PROVIDER.isAvailable(...)` check.** The Adyen
  5.9.0 migration guide calls this *optional* — *"You no longer need to call it"*.
  Our Flutter widget relies on the `AVAILABILITY` event to show/hide the button
  (`base_google_pay_component.dart:115`), and the Adyen `AdyenComponentView`
  fallback for users who don't render their own button is out of scope. Keeping the
  preflight check is the safe, backwards-compatible choice.

## Public API Sketch

**No breaking changes.** The Dart-facing API stays identical:

```dart
AdyenGooglePayComponent(
  configuration: GooglePayComponentConfiguration(...),  // unchanged
  paymentMethod: ...,
  checkout: ...,
  onPaymentResult: ...,
  style: GooglePayButtonStyle(...),                    // unchanged
  ...
)
```

Internally, on Android, the deprecated `startGooglePayScreen` path is replaced by
`submit()`. The Flutter-side button (`RawGooglePayButton`) is unchanged. From the
consumer's point of view, the component behaves the same.

### Internal New: Pigeon DTO Extension (optional, defaulted off)

Two new optional fields are added to `GooglePayConfigurationDTO` to expose the Adyen
5.9+ button rendering path. The fields are *optional* and default to "off" to
preserve the existing custom-button path. No public Dart model needs to change
unless we want to expose the styling knobs to consumers — out of scope for *bare
minimum* but trivial to add.

```dart
class GooglePayConfigurationDTO {
  // ... existing fields ...
  final bool? googlePaySubmitButtonVisible;       // NEW, optional
  final GooglePayButtonStylingDTO? googlePayButtonStyling;  // NEW, optional
}
```

These are wired through `ConfigurationMapper` to `setSubmitButtonVisible` and
`setGooglePayButtonStyling` on the Adyen 5.19.0 builder. Default = "off" → no
behaviour change for existing consumers.

## Ownership & Data Flow

| Concern | Where |
|---|---|
| Button rendering | Flutter (Dart), `BaseGooglePayComponent` — `RawGooglePayButton` from `pay` package, unchanged |
| Button click → native call | Flutter → `ComponentPlatformInterface.onInstantPaymentPressed()` → `GooglePayComponentManager.start()` |
| Native call to start Google Pay sheet | **Android only:** `googlePayComponent.submit()` (was `startGooglePayScreen()`) |
| Activity result for the sheet | **Removed.** `submit()` does not need an `onActivityResult` callback — the Adyen component pushes results through the existing `GooglePayCallback` chain (`GooglePayAdvancedCallback.onSubmit/onAdditionalDetails/onError`). |
| Availability check | **Unchanged.** `GooglePayComponent.PROVIDER.isAvailable(...)` is still called in `GooglePayComponentManager.initialize(...)`, the result is published via the `AVAILABILITY` `ComponentCommunicationType` event, and `BaseGooglePayComponent` uses it to show/hide the button. |

## Acceptance Criteria

- [ ] `GooglePayComponentManager.start()` calls `googlePayComponent.submit()` instead of `startGooglePayScreen(...)`.
- [ ] `GooglePayComponentManager.handleGooglePayActivityResult(...)` is removed.
- [ ] `Constants.GOOGLE_PAY_COMPONENT_REQUEST_CODE` is removed (no longer needed without `startGooglePayScreen`).
- [ ] `ComponentPlatformApi.handleActivityResult(...)` is removed.
- [ ] `AdyenCheckoutPlugin.onActivityResult(...)` is removed, `addActivityResultListener(this)` is removed, and `PluginRegistry.ActivityResultListener` is no longer implemented. `teardown()` no longer needs to call `removeActivityResultListener(this)`.
- [ ] The Pigeon proto (`pigeons/platform_api.dart`) no longer carries the `handleActivityResult` host API; `dart run pigeon --input pigeons/platform_api.dart` regenerates the platform channels.
- [ ] New optional Pigeon fields: `GooglePayConfigurationDTO.googlePaySubmitButtonVisible` and `GooglePayConfigurationDTO.googlePayButtonStyling` (with a small `GooglePayButtonStylingDTO` class). Mapped through `ConfigurationMapper` to `setSubmitButtonVisible` and `setGooglePayButtonStyling`. Both default to "off" → no behaviour change for existing consumers.
- [ ] Existing Dart consumer code (e.g. `BaseGooglePayComponent`, `AdyenGooglePayComponent`) is unchanged. The widget still uses `RawGooglePayButton` from the `pay` package and still calls `onInstantPaymentPressed` from Pigeon.
- [ ] CHANGELOG.md gets a single entry under `## Development` (matches the upstream style at HEAD `1b2dcb10`).
- [ ] All existing tests pass (`flutter test`, Android JUnit).
- [ ] No new file in a `generated/` directory is hand-edited.

## Phased Delivery

1. **Phase 1 — Pigeon DTOs + codegen** (pigeons/platform_api.dart; run pigeon)
2. **Phase 2 — Android Manager refactor** (GooglePayComponentManager.kt, ConfigurationMapper.kt, AdyenCheckoutPlugin.kt, ComponentPlatformApi.kt, Constants.kt)
3. **Phase 3 — Verification + CHANGELOG** (regenerate Pigeon if needed, run lint/tests, write CHANGELOG entry)

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `submit()` may not be available in older Adyen Android 5.9.0 (was added in 5.9.0) | `drop-in: 5.19.0` is the floor in this PR — verified. `submit()` exists in 5.19.0. Older 5.9.0 may need a version floor bump (out of scope for this PR). |
| The `DropIn.registerForDropInResult` flow also listens for activity results, so removing `addActivityResultListener` may break Drop-in | `ComponentPlatformApi.handleActivityResult` is the *only* consumer of the `onActivityResult` callback. `DropIn` uses `ActivityResultLauncher` (set up in `createLifecycleEventObserver`), not the deprecated `onActivityResult`. Verified by reading `AdyenCheckoutPlugin.kt:97-103` and `createLifecycleEventObserver` — Drop-in registration goes through `DropIn.registerForDropInResult`, the legacy `onActivityResult` path was purely for Google Pay's `startGooglePayScreen`. |
| Regenerating Pigeon may produce a noisy diff in the `generated/` folders | Expected. The PR will touch all 3 generated files (Dart, Kotlin, Swift). Reviewers are used to this (see commit `43bb806c Moved generated pigeon code for Android into a dedicated folder`). |
| `Constants.GOOGLE_PAY_COMPONENT_REQUEST_CODE` is referenced from iOS or example code | Verified: only referenced in `GooglePayComponentManager.kt:87`. Safe to remove. |

## Done When

- [ ] All phased steps merged into a single feature branch
- [ ] `flutter pub get` + `flutter analyze` clean
- [ ] `./gradlew :assemble` builds
- [ ] `flutter test` passes
- [ ] CHANGELOG.md has a `## Development` entry with the summary
- [ ] Branch pushed to `ED-1-bot/adyen-flutter` and PR opened against `Adyen/adyen-flutter:main`
- [ ] PR body links this plan and references the Adyen 5.9.0 migration guide
