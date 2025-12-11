<div align="center">

# EmotionSense

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/TensorFlow_Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white" alt="TensorFlow Lite"/>
  <img src="https://img.shields.io/badge/Google_ML_Kit-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="ML Kit"/>
</p>

**Real-time facial emotion, age, and gender detection with advanced ML models**

<p align="center">
  A privacy-first Flutter application combining Google ML Kit face detection with TensorFlow Lite models for comprehensive facial analysis
</p>

</div>

---

## <img src="https://cdn-icons-png.flaticon.com/512/3209/3209265.png" width="24" align="center"/> Overview

EmotionSense is a real-time facial analysis application that processes camera feed to detect emotions, estimate age, and identify gender. All processing occurs on-device with no data transmission, ensuring complete privacy.

### Key Capabilities

- <img src="https://cdn-icons-png.flaticon.com/512/2620/2620969.png" width="18" align="center"/> **Real-Time Emotion Detection** - Detects 7 emotions (Happy, Sad, Angry, Surprised, Disgusted, Fearful, Neutral) with temporal smoothing
- <img src="https://cdn-icons-png.flaticon.com/512/1077/1077114.png" width="18" align="center"/> **Age Estimation** - Quantized TensorFlow Lite model for age prediction
- <img src="https://cdn-icons-png.flaticon.com/512/1077/1077063.png" width="18" align="center"/> **Gender Detection** - Binary classification with probability-based thresholding
- <img src="https://cdn-icons-png.flaticon.com/512/6195/6195699.png" width="18" align="center"/> **Privacy-First Architecture** - 100% on-device processing with no network requests
- <img src="https://cdn-icons-png.flaticon.com/512/3094/3094837.png" width="18" align="center"/> **Temporal Smoothing** - 8-frame history with median/majority voting to reduce prediction flickering

---

## <img src="https://cdn-icons-png.flaticon.com/512/1087/1087815.png" width="24" align="center"/> Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Android SDK 21+ or iOS 15.0+

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

## <img src="https://cdn-icons-png.flaticon.com/512/3281/3281289.png" width="24" align="center"/> Architecture

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

| Emotion                                                                                     | Detection Criteria                |
| ------------------------------------------------------------------------------------------- | --------------------------------- |
| <img src="https://cdn-icons-png.flaticon.com/512/742/742751.png" width="16"/> **Happy**     | `smilingProbability > 0.70`       |
| <img src="https://cdn-icons-png.flaticon.com/512/742/742759.png" width="16"/> **Sad**       | `smilingProbability < 0.30`       |
| <img src="https://cdn-icons-png.flaticon.com/512/742/742769.png" width="16"/> **Neutral**   | `smilingProbability 0.30-0.70`    |
| <img src="https://cdn-icons-png.flaticon.com/512/742/742774.png" width="16"/> **Surprised** | Eyes wide open + mouth open       |
| <img src="https://cdn-icons-png.flaticon.com/512/742/742752.png" width="16"/> **Angry**     | Low smile + specific eye patterns |
| <img src="https://cdn-icons-png.flaticon.com/512/742/742770.png" width="16"/> **Disgusted** | Face contortion detection         |
| <img src="https://cdn-icons-png.flaticon.com/512/742/742753.png" width="16"/> **Fearful**   | Wide eyes + low smile             |

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

## <img src="https://cdn-icons-png.flaticon.com/512/3281/3281307.png" width="24" align="center"/> Technical Specifications

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

## <img src="https://cdn-icons-png.flaticon.com/512/6195/6195699.png" width="24" align="center"/> Privacy & Security

<table>
<tr>
<td><img src="https://cdn-icons-png.flaticon.com/512/5610/5610944.png" width="24"/></td>
<td><b>100% On-Device Processing</b><br/>All ML inference runs locally</td>
</tr>
<tr>
<td><img src="https://cdn-icons-png.flaticon.com/512/1087/1087927.png" width="24"/></td>
<td><b>No Network Requests</b><br/>Zero data transmission to external servers</td>
</tr>
<tr>
<td><img src="https://cdn-icons-png.flaticon.com/512/3179/3179047.png" width="24"/></td>
<td><b>No Analytics/Telemetry</b><br/>No user tracking or behavior analysis</td>
</tr>
<tr>
<td><img src="https://cdn-icons-png.flaticon.com/512/3094/3094851.png" width="24"/></td>
<td><b>Local Storage Only</b><br/>Photos saved locally with user consent</td>
</tr>
</table>

---

## <img src="https://cdn-icons-png.flaticon.com/512/3281/3281307.png" width="24" align="center"/> Performance

- **Processing Speed:** ~10-15 FPS on modern devices
- **Latency:** <100ms per frame (detection + inference)
- **Memory Usage:** ~150MB (includes loaded ML models)

---

## <img src="https://cdn-icons-png.flaticon.com/512/3094/3094840.png" width="24" align="center"/> Build & Deployment

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

### <img src="https://cdn-icons-png.flaticon.com/512/25/25231.png" width="20" align="center"/> Automated CI/CD

This project includes a **pre-configured GitHub Actions workflow** for automated iOS IPA generation:

- <img src="https://cdn-icons-png.flaticon.com/512/733/733553.png" width="16" align="center"/> **Automated IPA Builds** - GitHub workflow automatically generates unsigned IPA on push/release
- <img src="https://cdn-icons-png.flaticon.com/512/2965/2965358.png" width="16" align="center"/> **TrollStore Compatible** - Ready for TrollStore permanent installation (iOS 14.0-16.6.1)
- <img src="https://cdn-icons-png.flaticon.com/512/2888/2888720.png" width="16" align="center"/> **Sideloading Ready** - Works with AltStore, Sideloadly, or any standard sideloading method

**Installation Options:**

- **TrollStore:** Permanent installation without re-signing (recommended for jailbroken/exploited devices)
- **AltStore/Sideloadly:** 7-day signing with free Apple ID, 1-year with paid developer account
- **Xcode:** Direct installation via cable for development/testing

Check the `.github/workflows/` directory for CI configuration details.

---

## <img src="https://cdn-icons-png.flaticon.com/512/1087/1087927.png" width="24" align="center"/> Dependencies

- `google_ml_kit_face_detection` - Face detection
- `tflite_flutter` - TensorFlow Lite runtime
- `camera` - Camera access
- `provider` - State management
- `image` - Image processing

---

## <img src="https://cdn-icons-png.flaticon.com/512/3281/3281289.png" width="24" align="center"/> License

MIT License - See [LICENSE](LICENSE) for details

---

<div align="center">

**Built with Flutter & TensorFlow Lite**

<img src="https://img.shields.io/badge/Made_with-Flutter-02569B?style=flat&logo=flutter" alt="Made with Flutter"/>

</div>
