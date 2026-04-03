# EmotionSense

![EmotionSense brand mark](assets/icons/emotionsense_brand.svg)

Live, privacy-first facial analysis built with Flutter, Google ML Kit, and TensorFlow Lite.

Detect emotion in real time, estimate age and gender on-device, optionally classify ethnicity, and present the results through a mobile camera workflow designed for speed and clarity.

## Why EmotionSense

EmotionSense is a mobile-first Flutter application focused on local inference. The app analyzes faces directly on the device instead of sending frames to a server, which makes it faster to demo, safer to share, and easier to reason about from a privacy perspective.

It is designed around three goals:

- Deliver a responsive live camera experience with readable output.
- Keep inference and media handling local to the device.
- Support a browser-safe preview mode without changing the core mobile pipeline.

## Highlights

- Multi-face tracking with live per-face analysis.
- Real-time emotion detection with smoothing and optional fast-response mode.
- On-device age and gender estimation through TFLite models.
- Optional ethnicity classification controlled from settings.
- Camera-side comparison and capture workflows.
- Emoji rain, alerts, onboarding, and saved-history support.
- Web preview mode for browser demos when native ML features are unavailable.

## Tech Stack

| Layer | Tools |
| --- | --- |
| App framework | Flutter 3.x, Dart 3.x |
| State management | Provider |
| Face detection | `google_mlkit_face_detection` |
| ML inference | `tflite_flutter` |
| Media and storage | `camera`, `photo_manager`, `shared_preferences`, `path_provider` |
| UI and polish | Material 3, `google_fonts`, `flutter_animate`, `audioplayers` |

## Platform Support

| Platform | Support | Notes |
| --- | --- | --- |
| Android | Full | Main target for live camera and local ML. |
| iOS | Full | Same core experience as Android. |
| Web | Limited | Preview-safe build only; native camera and ML integrations are intentionally reduced. |
| Desktop | Partial scaffold | Platform folders exist, but the production experience is still mobile-first. |

## Core Models

Bundled local models in `assets/models/`:

- `face_detection_short_range.tflite`
- `model_lite_age_q.tflite`
- `model_lite_gender_q.tflite`
- `age_gender_ethnicity_new.tflite`

## Getting Started

### Prerequisites

- Flutter SDK available in the local environment.
- Android Studio or Xcode, depending on the device target.
- A connected device or emulator if you want the full experience.

### Install Dependencies

```bash
flutter pub get
```

### Run On A Device

```bash
flutter run -d <device-id>
```

### Run On An Android Emulator

This repo already supports an emulator-focused path for `x86_64`:

```bash
flutter run -d emulator-5554 --target-platform android-x64
```

### Run The Web Preview

If you want a browser-safe shell without relying on a local Edge configuration:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Or use a browser target directly when available:

```bash
flutter run -d chrome
```

## Project Structure

```text
lib/
  app.dart
  main.dart
  core/
  data/
  presentation/
  services/
  ui/
  utils/
assets/
  icons/
  models/
  sounds/
scripts/
test/
web/
android/
ios/
```

## Runtime Flow

1. The camera provider streams frames on-device.
2. ML Kit detects faces, landmarks, and tracking information.
3. Face crops are normalized for the TFLite pipeline.
4. Age, gender, and optional ethnicity are inferred locally.
5. Emotion is derived and smoothed before UI presentation.
6. The camera view, result screens, and comparison flow render the final state.

## Product Experience

### Live Camera

- Face brackets and clean live overlays.
- Horizontal stats panel below the preview.
- Separate summary presentation for demographics and emotion.
- Optional emoji rain and fast emotion response.

### Settings

- Detection sensitivity.
- Analysis FPS.
- Fast emotion response toggle.
- Emoji rain toggle.
- Age and gender display toggle.
- Ethnicity classification toggle.
- Alert and capture behavior.

### Results And Comparison

- Capture review flow.
- Side-by-side comparison mode when multiple faces are present.
- History access for saved outputs.

## Web Mode

The web build is intentionally framed as a preview, not a feature-complete port of the mobile ML pipeline. It exists so the app can launch in a browser, demonstrate structure and UI, and avoid breaking on native-only integrations.

If you need the full camera and inference stack, use Android or iOS.

## Build Commands

```bash
# Debug APK
flutter build apk --debug

# Emulator-friendly debug APK
flutter build apk --debug --target-platform android-x64

# Release APK
flutter build apk --release

# Web build
flutter build web

# iOS release build
flutter build ios --release
```

## Branding Notes

- The launcher icon and favicon are generated from the same badge used in the app settings header.
- The README uses a dedicated SVG wordmark for cleaner presentation.
- Legacy root logos were removed so there is a single current branding direction.

## Regenerating Icons

```bash
python scripts/generate_brand_icons.py
dart run flutter_launcher_icons
```

## Troubleshooting

### Browser launches but detection is limited

That is expected in preview mode. Use Android or iOS for the full camera-and-ML flow.

### Android debug builds pause for a long time

Cold Gradle and Flutter artifact downloads can make the first build feel stuck. Subsequent runs are usually much faster once caches are warm.

### Branding changes do not appear immediately

Regenerate icons, then rebuild the target platform so cached launcher assets are refreshed.

## License

