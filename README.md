<div align="center">

<img src="logo.svg" alt="EmotionSense Logo" width="200"/>

# EmotionSense

**Real-time facial emotion, age, and gender detection with advanced ML models**

<p align="center">
  A privacy-first Flutter application combining Google ML Kit face detection with TensorFlow Lite models for comprehensive facial analysis
</p>

</div>

---

## <img src="assets/icons/overview.svg" width="24" align="center" alt="Overview"/> Overview

EmotionSense is a real-time facial analysis application that processes camera feed to detect emotions, estimate age, and identify gender. All processing occurs on-device with no data transmission, ensuring complete privacy.

### Key Capabilities

- <img src="assets/icons/emotion.svg" width="18" align="center" alt="Emotion Detection"/> **Real-Time Emotion Detection** - Detects 7 emotions (Happy, Sad, Angry, Surprised, Disgusted, Fearful, Neutral) with temporal smoothing
- <img src="assets/icons/age.svg" width="18" align="center" alt="Age Estimation"/> **Age Estimation** - Quantized TensorFlow Lite model for age prediction
- <img src="assets/icons/gender.svg" width="18" align="center" alt="Gender Detection"/> **Gender Detection** - Binary classification with probability-based thresholding
- <img src="assets/icons/privacy.svg" width="18" align="center" alt="Privacy"/> **Privacy-First Architecture** - 100% on-device processing with no network requests
- <img src="assets/icons/smoothing.svg" width="18" align="center" alt="Temporal Smoothing"/> **Temporal Smoothing** - 8-frame history with median/majority voting to reduce prediction flickering

---

## <img src="assets/icons/tech.svg" width="24" align="center" alt="Technology"/> Tech Stack

### Core Framework

<table>
<tr>
<td align="center" width="140">
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/><br/>
<b>Flutter</b><br/>
<sub>Cross-platform UI framework</sub>
</td>
<td align="center" width="140">
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/><br/>
<b>Dart</b><br/>
<sub>Programming language</sub>
</td>
</tr>
</table>

### Machine Learning

<table>
<tr>
<td align="center" width="140">
<img src="https://img.shields.io/badge/TensorFlow_Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white" alt="TensorFlow Lite"/><br/>
<b>TensorFlow Lite</b><br/>
<sub>Age/Gender models</sub>
</td>
<td align="center" width="140">
<img src="https://img.shields.io/badge/Google_ML_Kit-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="ML Kit"/><br/>
<b>Google ML Kit</b><br/>
<sub>Face detection</sub>
</td>
</tr>
</table>

### Key Dependencies

| Package                       | Purpose                                       | Version |
| ----------------------------- | --------------------------------------------- | ------- |
| `google_mlkit_face_detection` | Real-time face detection & emotion analysis   | ^0.13.1 |
| `tflite_flutter`              | TensorFlow Lite runtime for age/gender models | ^0.11.0 |
| `camera`                      | Camera access & frame capture                 | ^0.11.0 |
| `provider`                    | State management                              | ^6.0.0  |
| `image`                       | Image processing & manipulation               | ^4.0.0  |
| `permission_handler`          | Runtime permissions (camera/microphone)       | ^11.0.0 |
| `photo_manager`               | Photo gallery management                      | ^3.7.1  |
| `audioplayers`                | Sound effects & audio feedback                | ^5.2.1  |

### Platform Support

<table>
<tr>
<td align="center" width="100">
<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android"/><br/>
<b>Android</b><br/>
<sub>API 21+</sub>
</td>
<td align="center" width="100">
<img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" alt="iOS"/><br/>
<b>iOS</b><br/>
<sub>16.0+</sub>
</td>
</tr>
</table>

### Development Tools

- **CI/CD:** GitHub Actions (automated IPA builds)
- **Build System:** Gradle (Android), Xcode (iOS), CocoaPods
- **Version Control:** Git

---

## <img src="assets/icons/getting-started.svg" width="24" align="center" alt="Getting Started"/> Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Android SDK 21+ or iOS 16.0+

### Installation

```bash
# Clone repository
git clone <repository-url>
cd EmotionSense

# Install dependencies
flutter pub get

# Run application
flutter run
```

### Platform-Specific Setup

**Android**

```bash
flutter run -d <device-id>
```

**iOS**

```bash
cd ios && pod install
flutter run -d <device-id>
```

---

## <img src="assets/icons/architecture.svg" width="24" align="center" alt="Architecture"/> Architecture

### ML Pipeline

```
Camera Frame → ML Kit Face Detection → Face Bounding Box
                                              ↓
                        Crop & Resize (200×200 for age, 128×128 for gender)
                                              ↓
                        TensorFlow Lite Inference (Quantized Models)
                                              ↓
                        Temporal Smoothing (8-frame history)
                                              ↓
                        Final Predictions (Age: Median, Gender: Majority Vote)
```

### Emotion Detection Logic

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

### Project Structure

```
lib/
├── core/
│   ├── enums/               # Emotion, TFLiteModelType enums
│   └── utils/               # Image processing utilities
├── data/
│   └── models/              # Data models (DetectedFace, Attributes)
├── presentation/
│   ├── providers/           # State management
│   │   └── face_attributes_provider.dart
│   └── widgets/             # UI components
│       └── morphing_emoji.dart
├── services/
│   ├── face_detection_service.dart    # ML Kit wrapper
│   └── unified_tflite_service.dart    # TFLite model manager
└── ui/
    └── camera_view.dart     # Main camera interface
```

---

## <img src="assets/icons/tech.svg" width="24" align="center" alt="Technical Specifications"/> Technical Specifications

### Models

| Model            | Input Size | Output               | Format    | Quantization |
| ---------------- | ---------- | -------------------- | --------- | ------------ |
| Age Estimation   | 200×200×3  | Single float (0-116) | `.tflite` | INT8         |
| Gender Detection | 128×128×3  | 2-class probability  | `.tflite` | INT8         |

### Smoothing Parameters

- **Age:** Median from 8-frame history (robust to outliers)
- **Gender:** Majority voting from 8-frame history
- **Emotion:** Majority voting from 5-frame history

### Face Bounding Box

- **Expansion:** 30% horizontal, 35% vertical
- **Purpose:** Ensures complete face capture including forehead/chin for accurate model input

---

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

- **Processing Speed:** ~10-15 FPS on modern devices
- **Latency:** <100ms per frame (detection + inference)
- **Memory Usage:** ~150MB (includes loaded ML models)

---

## <img src="assets/icons/build.svg" width="24" align="center" alt="Build and Deployment"/> Build & Deployment

### Android

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

### iOS

```bash
# Build for device
flutter build ios --release

# Build unsigned IPA for side-loading
flutter build ios --release --no-codesign
```

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

---

<div align="center">

**Built with Flutter & TensorFlow Lite**

<img src="https://img.shields.io/badge/Made_with-Flutter-02569B?style=flat&logo=flutter" alt="Made with Flutter"/>

</div>
