<div align="center">

<img src="logo.svg" alt="EmotionSense Logo" width="200"/>

# EmotionSense

<<<<<<< HEAD
**Real-time multi-face emotion, age, gender & head pose analysis with on-device ML**
=======
**Real-time facial emotion, age, and gender detection with advanced ML models**
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

<p align="center">
  A privacy-first Flutter application combining Google ML Kit face detection with TensorFlow Lite models for comprehensive facial analysis — now with multi-face tracking, emoji rain, emotion alerts, comparison mode, and more.
</p>

</div>

---

<<<<<<< HEAD
## Overview
=======
## <img src="assets/icons/overview.svg" width="24" align="center" alt="Overview"/> Overview
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

EmotionSense is a real-time facial analysis application that processes camera feed to detect emotions, estimate age, classify gender, determine ethnicity, and display head pose angles — all on-device with zero data transmission.

### Key Features

<<<<<<< HEAD
- **Multi-Face Tracking** — Track and label up to 5 faces simultaneously with per-face results and tracking IDs
- **Real-Time Emotion Detection** — Detects Happy, Sad, Angry, Surprised, Neutral with temporal smoothing
- **Age & Gender Estimation** — TFLite quantized models with per-face smoothed predictions
- **Ethnicity Classification** — Optional opt-in ethnicity prediction via combined TFLite model
- **Head Pose Estimation** — Live yaw/pitch/roll angles from ML Kit landmarks per face
- **Emotion Alerts** — Configurable notifications when a specific emotion exceeds a threshold
- **Model Hot-Swapping** — Switch between Accuracy (2 threads) and Speed (4 threads) modes
- **Live Emoji Rain** — Subtle particle effect matching the detected emotion
- **Comparison Mode** — Side-by-side two-person emotion comparison when 2+ faces detected
- **Performance Dashboard** — Developer tools with FPS/latency history charts, model pipeline info, per-face details
- **3-Screen Onboarding** — Privacy, permissions, and features walkthrough for first-time users
- **Privacy-First Architecture** — 100% on-device processing, no network requests

---

## Tech Stack
=======
- <img src="assets/icons/emotion.svg" width="18" align="center" alt="Emotion Detection"/> **Real-Time Emotion Detection** - Detects 7 emotions (Happy, Sad, Angry, Surprised, Disgusted, Fearful, Neutral) with temporal smoothing
- <img src="assets/icons/age.svg" width="18" align="center" alt="Age Estimation"/> **Age Estimation** - Quantized TensorFlow Lite model for age prediction
- <img src="assets/icons/gender.svg" width="18" align="center" alt="Gender Detection"/> **Gender Detection** - Binary classification with probability-based thresholding
- <img src="assets/icons/privacy.svg" width="18" align="center" alt="Privacy"/> **Privacy-First Architecture** - 100% on-device processing with no network requests
- <img src="assets/icons/smoothing.svg" width="18" align="center" alt="Temporal Smoothing"/> **Temporal Smoothing** - 8-frame history with median/majority voting to reduce prediction flickering

---

## <img src="assets/icons/tech.svg" width="24" align="center" alt="Technology"/> Tech Stack
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

### Core Framework

| Technology             | Purpose                     |
| ---------------------- | --------------------------- |
| **Flutter** (>=3.19.0) | Cross-platform UI framework |
| **Dart** (>=3.3.0)     | Programming language        |
| **Provider**           | State management            |

### Machine Learning

| Component                | Technology                          | Details                                    |
| ------------------------ | ----------------------------------- | ------------------------------------------ |
| Face Detection           | Google ML Kit                       | Short-range, tracking, landmarks, contours |
| Age Estimation           | TFLite (`model_lite_age_q`)         | 200×200×3 input, INT8 quantized            |
| Gender Classification    | TFLite (`model_lite_gender_q`)      | 128×128×3 input, INT8 quantized            |
| Ethnicity Classification | TFLite (`age_gender_ethnicity_new`) | Combined model, 5-class output             |
| Emotion Detection        | ML Kit Heuristics                   | Smile + eye + landmark analysis            |

### Key Dependencies

| Package                       | Purpose                                            | Version |
| ----------------------------- | -------------------------------------------------- | ------- |
| `google_mlkit_face_detection` | Face detection with tracking & landmarks           | ^0.13.1 |
| `tflite_flutter`              | TFLite runtime for age/gender/ethnicity            | ^0.11.0 |
| `camera`                      | Camera stream & frame capture                      | ^0.11.3 |
| `provider`                    | State management (Settings, Camera, History, Face) | ^6.0.0  |
| `image`                       | Image processing & manipulation                    | ^4.0.0  |
| `shared_preferences`          | Persisted settings storage                         | ^2.2.0  |
| `google_fonts`                | Poppins font family                                | ^6.0.0  |

### Platform Support

| Platform | Min Version | Status                                 |
| -------- | ----------- | -------------------------------------- |
| Android  | API 21+     | ✅ Supported                           |
| iOS      | 16.0+       | ✅ Supported                           |
| Web      | —           | ❌ Not supported (native dependencies) |

---

<<<<<<< HEAD
## Getting Started
=======
## <img src="assets/icons/getting-started.svg" width="24" align="center" alt="Getting Started"/> Getting Started
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

### Prerequisites

- Flutter SDK >=3.19.0
- Dart >=3.3.0
- Android SDK 21+ or iOS 16.0+

### Installation

```bash
git clone <repository-url>
cd EmotionSense
flutter pub get
flutter run
```

### Platform-Specific Setup

**Android:** `flutter run -d <device-id>`

**iOS:**

```bash
cd ios && pod install && cd ..
flutter run -d <device-id>
```

---

<<<<<<< HEAD
## Architecture
=======
## <img src="assets/icons/architecture.svg" width="24" align="center" alt="Architecture"/> Architecture
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

### ML Pipeline

```
Camera Frame
    ↓
ML Kit Face Detection (up to 5 faces, tracking IDs, landmarks)
    ↓
┌─────────────────────────────────────────────┐
│  For each detected face:                    │
│  1. Crop & resize (200×200 age, 128×128 gen)│
│  2. TFLite inference (age, gender, ethnicity)│
│  3. ML Kit heuristic emotion classification │
│  4. Head pose angles (yaw/pitch/roll)       │
│  5. Per-face temporal smoothing (by ID)     │
│  6. Emotion alert check                     │
└─────────────────────────────────────────────┘
    ↓
UI: Corner brackets + floating labels + emoji rain + comparison
```

### Emotion Detection Criteria

<<<<<<< HEAD
| Emotion      | Detection Method                              |
| ------------ | --------------------------------------------- |
| 😄 Happy     | `smilingProbability > 0.70`                   |
| 😢 Sad       | `smilingProbability < 0.30` + frown detection |
| 😠 Angry     | Low smile + brow compression + face energy    |
| 😲 Surprised | Wide eyes + mouth open                        |
| 😐 Neutral   | Default fallback                              |
=======
Utilizes **Google ML Kit Face Detection** with multi-factor analysis:

| Emotion                                                                               | Detection Criteria                |
| ------------------------------------------------------------------------------------- | --------------------------------- |
| <img src="assets/icons/happy.svg" width="16" alt="Happy"/> **Happy**                 | `smilingProbability > 0.70`       |
| <img src="assets/icons/sad.svg" width="16" alt="Sad"/> **Sad**                       | `smilingProbability < 0.30`       |
| <img src="assets/icons/neutral.svg" width="16" alt="Neutral"/> **Neutral**           | `smilingProbability 0.30-0.70`    |
| <img src="assets/icons/surprised.svg" width="16" alt="Surprised"/> **Surprised**     | Eyes wide open + mouth open       |
| <img src="assets/icons/angry.svg" width="16" alt="Angry"/> **Angry**                 | Low smile + specific eye patterns |
| <img src="assets/icons/disgusted.svg" width="16" alt="Disgusted"/> **Disgusted**     | Face contortion detection         |
| <img src="assets/icons/fearful.svg" width="16" alt="Fearful"/> **Fearful**           | Wide eyes + low smile             |

**Smoothing:** 5-frame history with majority voting to prevent jitter
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

### Project Structure

```
lib/
├── app.dart                          # AppColors, theme, routing (onboarding/camera)
├── main.dart                         # Entry point
├── core/
│   ├── constants/emotions.dart       # Emotion enum + display extensions
│   └── utils/                        # Permission manager
├── data/
│   ├── models/                       # AgeGenderData, etc.
│   └── repositories/
│       └── settings_repository.dart  # SharedPreferences persistence
├── presentation/
│   ├── providers/
│   │   ├── face_attributes_provider.dart  # Multi-face ML orchestration
│   │   ├── settings_provider.dart         # All app settings state
│   │   ├── camera_provider.dart           # Camera controller state
│   │   └── history_provider.dart          # Capture history state
│   ├── screens/
│   │   ├── onboarding_screen.dart         # 3-page onboarding flow
│   │   ├── settings_screen.dart           # Full settings (model, alerts, etc.)
│   │   ├── analysis_result_screen.dart    # Capture result display
│   │   ├── comparison_screen.dart         # 2-person side-by-side comparison
│   │   └── performance_dashboard_screen.dart  # Dev tools dashboard
│   └── widgets/
│       └── emoji_rain_widget.dart         # Particle effect widget
├── services/
│   ├── mlkit_face_service.dart       # ML Kit wrapper + emotion heuristics
│   └── unified_tflite_service.dart   # TFLite model manager + hot-swap
├── ui/
│   └── camera_view.dart              # Main camera screen + overlays
└── utils/
    ├── image_converter.dart          # YUV→RGB conversion
    └── image_preprocess.dart         # Normalization modes
```

---

<<<<<<< HEAD
## Screens
=======
## <img src="assets/icons/tech.svg" width="24" align="center" alt="Technical Specifications"/> Technical Specifications
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

### Camera View (Main)

- Live camera preview with blue corner-bracket face overlays
- Per-face floating labels: emoji + emotion + gender + age + head pose yaw
- Face count badge when multiple faces detected
- FPS/latency stats panel (tap to open Performance Dashboard)
- Emotion confidence bars
- Compare button (appears with 2+ faces)
- Emoji rain particle effect
- Emotion alert banner
- Privacy toggle, flash toggle, camera flip

### Onboarding (3 Screens)

1. **Privacy** — Explains on-device processing, zero data transmission
2. **Camera Access** — Explains camera permission requirement
3. **Features** — Highlights multi-face, head pose, alerts, comparison

### Settings

- **Analysis** — Sensitivity slider, analysis FPS control, temporal smoothing
- **Classification** — Age/gender toggle, ethnicity opt-in
- **Model** — Performance mode toggle (Accuracy 🎯 vs Speed ⚡)
- **Emotion Alerts** — Select emotion, set confidence threshold
- **Capture** — Auto-capture, confidence threshold, cooldown
- **Feedback** — Sound effects, haptic feedback
- **Privacy** — Zero-cloud promise display

### Analysis Result

- Captured image with face corner brackets
- Large emoji + emotion name + confidence percentage
- Gender, age, ethnicity chips
- Save to history or discard

### Comparison Mode

- Side-by-side cards for Person 1 and Person 2
- Full attribute display per person (emotion, gender, age, ethnicity, head pose)
- Emotion match/mismatch summary

### Performance Dashboard

- Live FPS, latency, face count metric cards
- FPS and latency history mini-charts
- Model pipeline breakdown (5 stages)
- Per-face detail cards with tracking IDs

---

<<<<<<< HEAD
## Settings Reference

| Setting                  | Default  | Range                                 | Description                           |
| ------------------------ | -------- | ------------------------------------- | ------------------------------------- |
| Detection Sensitivity    | 60%      | 30–90%                                | Face detection confidence threshold   |
| Analysis FPS             | 15       | 5–30                                  | Target frames per second for analysis |
| Show Age & Gender        | On       | —                                     | Display demographic predictions       |
| Ethnicity Classification | On       | —                                     | Opt-in ethnicity prediction           |
| Performance Mode         | Accuracy | Accuracy/Speed                        | Thread count for TFLite inference     |
| Alert Emotion            | Off      | Off/Happy/Sad/Angry/Surprised/Neutral | Emotion to monitor                    |
| Alert Threshold          | 70%      | 30–95%                                | Confidence to trigger alert           |
| Auto Capture             | On       | —                                     | Auto-capture on strong emotion        |
| Sound Effects            | On       | —                                     | Enable/disable sounds                 |
| Haptic Feedback          | On       | —                                     | Enable/disable haptic                 |

---

## Privacy & Security
=======
## <img src="assets/icons/privacy.svg" width="24" align="center" alt="Privacy and Security"/> Privacy & Security

<table>
<tr>
<td><img src="assets/icons/on-device.svg" width="24" alt="On-Device Processing"/></td>
<td><b>100% On-Device Processing</b><br/>All ML inference runs locally</td>
</tr>
<tr>
<td><img src="assets/icons/no-network.svg" width="24" alt="No Network Requests"/></td>
<td><b>No Network Requests</b><br/>Zero data transmission to external servers</td>
</tr>
<tr>
<td><img src="assets/icons/no-analytics.svg" width="24" alt="No Analytics or Telemetry"/></td>
<td><b>No Analytics/Telemetry</b><br/>No user tracking or behavior analysis</td>
</tr>
<tr>
<td><img src="assets/icons/local-storage.svg" width="24" alt="Local Storage Only"/></td>
<td><b>Local Storage Only</b><br/>Photos saved locally with user consent</td>
</tr>
</table>

---

## <img src="assets/icons/tech.svg" width="24" align="center" alt="Performance"/> Performance
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

| Guarantee                  | Details                                         |
| -------------------------- | ----------------------------------------------- |
| **100% On-Device**         | All ML inference runs locally on the device     |
| **No Network Requests**    | Zero data transmission to external servers      |
| **No Analytics**           | No tracking, telemetry, or behavior analysis    |
| **Local Storage Only**     | Photos saved locally with explicit user consent |
| **Camera-Only Permission** | No microphone, contacts, or location access     |

---

<<<<<<< HEAD
## Performance
=======
## <img src="assets/icons/build.svg" width="24" align="center" alt="Build and Deployment"/> Build & Deployment
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

| Metric           | Value                                               |
| ---------------- | --------------------------------------------------- |
| Processing Speed | ~10–15 FPS (accuracy mode), ~15–25 FPS (speed mode) |
| Latency          | <100ms per frame (detection + inference)            |
| Memory           | ~150MB (includes loaded ML models)                  |
| Max Faces        | 5 simultaneously tracked                            |
| Smoothing        | 8-frame history (age/gender), 5-frame (emotion)     |

---

## Build & Deployment

```bash
# Debug
flutter build apk --debug

# Release APK
flutter build apk --release

# iOS
flutter build ios --release
```

<<<<<<< HEAD
---

## License

MIT License — See [LICENSE](LICENSE) for details
=======
### <img src="assets/icons/github.svg" width="20" align="center" alt="GitHub Actions"/> Automated CI/CD

This project includes a **pre-configured GitHub Actions workflow** for automated iOS IPA generation:

- <img src="assets/icons/automated-build.svg" width="16" align="center" alt="Automated IPA Builds"/> **Automated IPA Builds** - GitHub workflow automatically generates unsigned IPA on push/release
- <img src="assets/icons/trollstore.svg" width="16" align="center" alt="TrollStore Compatible"/> **TrollStore Compatible** - Ready for TrollStore permanent installation (iOS 14.0-16.6.1)
- <img src="assets/icons/sideload.svg" width="16" align="center" alt="Sideloading Ready"/> **Sideloading Ready** - Works with AltStore, Sideloadly, or any standard sideloading method

**Installation Options:**

- **TrollStore:** Permanent installation without re-signing (recommended for jailbroken/exploited devices)
- **AltStore/Sideloadly:** 7-day signing with free Apple ID, 1-year with paid developer account
- **Xcode:** Direct installation via cable for development/testing

Check the `.github/workflows/` directory for CI configuration details.

---

## <img src="assets/icons/dependencies.svg" width="24" align="center" alt="Dependencies"/> Dependencies

- `google_ml_kit_face_detection` - Face detection
- `tflite_flutter` - TensorFlow Lite runtime
- `camera` - Camera access
- `provider` - State management
- `image` - Image processing

---

## <img src="assets/icons/license.svg" width="24" align="center" alt="License"/> License

MIT License - See [LICENSE](LICENSE) for details
>>>>>>> 6385ec55107389e1a63d9e8c5687c00cbdce8da3

---

<div align="center">

**Built with Flutter, TensorFlow Lite & Google ML Kit**

</div>
