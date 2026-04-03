# Fix: Build Stuck at 71% — ARM Artifact Downloads

## Root Cause (confirmed from log)

Two separate downloads are blocking progress simultaneously:

```
> :app:checkDebugDuplicateClasses > arm64_v8a_debug-1.0.0-13e658...jar
> :app:checkDebugDuplicateClasses > armeabi_v7a_debug-1.0.0-13e658...jar
> :tflite_flutter:extractDebugAnnotations > kotlin-compiler-31.9.1.jar
```

The Flutter assemble command is confirmed building for **all three ABIs**:

```
-dAndroidArchs=android-arm android-arm64 android-x64
```

This comes from Flutter itself, not just `abiFilters`. Even if the emulator only
needs `x86_64`, Flutter's Gradle plugin forces all three unless told otherwise.
The two ARM JARs are ~25 MB each and download on a cold Gradle cache.

**This is a one-time block.** Once those three files land in
`~/.gradle/caches`, this 71% wall disappears permanently.

---

## Option A — Wait It Out (Zero Changes Required)

Let the current build finish. The downloads will complete, Gradle will store
the entries, and every subsequent build will skip straight past this point
with `FROM-CACHE` hits.

Estimated remaining time: 2–10 minutes depending on connection speed.

---

## Option B — Kill and Rebuild Lean (Recommended for Emulator Work)

Kill the current build, apply the one-line change below, then rerun.
Future debug builds targeting the emulator will download zero extra JARs.

### File to edit: `android/app/build.gradle.kts`

Find the `defaultConfig` block. Replace the existing `ndk { }` block with:

```kotlin
defaultConfig {
    applicationId = "com.example.emotion_sense"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    ndk {
        // Emulator: x86_64 only — no ARM downloads
        // Physical device: swap to listOf("arm64-v8a", "armeabi-v7a")
        abiFilters += listOf("x86_64")
    }
}
```

### Add a VS Code launch config: `.vscode/launch.json`

Create this file (or add to it if it already exists):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "EmotionSense (emulator)",
      "request": "launch",
      "type": "dart",
      "args": ["--target-platform", "android-x64"]
    },
    {
      "name": "EmotionSense (device)",
      "request": "launch",
      "type": "dart",
      "args": ["--target-platform", "android-arm64"]
    }
  ]
}
```

Or run directly from terminal:

```bash
flutter run --target-platform android-x64
```

This tells Flutter's assembler to pass only `android-x64` to `-dAndroidArchs`,
so no ARM JARs are requested at all.

---

## Option C — Pre-warm the Cache Right Now

Run this in a separate terminal while waiting (or after killing the stuck build):

```bash
flutter precache --android
```

This downloads all Flutter engine artifacts into Flutter's own local cache so
Gradle never fetches them during a build again.

---

## Why `tflite_flutter` Is Also Slow

`tflite_flutter:extractDebugAnnotations` is downloading
`kotlin-compiler-31.9.1.jar` (~80 MB). This is a one-time event stored at:

```
%USERPROFILE%\.gradle\caches\modules-2\files-2.1\
  com.android.tools.external.com-intellij\kotlin-compiler\31.9.1\
```

Once that directory exists with a `.jar` file, future builds skip the download.
No action needed — just let it complete once.

---

## How to Confirm the Fix Worked

On the next build after the cache is warm, both of these should appear as
`UP-TO-DATE` with no download lines underneath:

```
> Task :app:checkDebugDuplicateClasses UP-TO-DATE
> Task :tflite_flutter:extractDebugAnnotations UP-TO-DATE
```

If you see those, the 71% block is gone permanently.

---

## Summary

| Option | Action needed | Fixes it permanently? |
|--------|---------------|-----------------------|
| A | Wait (do nothing) | Yes — cache warms up |
| B | Edit `build.gradle.kts` + add launch.json | Yes — skips ARM entirely |
| C | Run `flutter precache --android` | Yes — cache warms up |

Recommended path: let the current build finish (A), then apply B so future
emulator runs never touch ARM artifacts again.
