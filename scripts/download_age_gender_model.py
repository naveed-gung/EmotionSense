#!/usr/bin/env python3
"""Download age/gender/ethnicity TFLite model"""

import urllib.request
import os

# Model URLs (trying multiple sources)
MODEL_URLS = [
    # MobileFaceNets age/gender model
    "https://github.com/yakhyo/face-attributes-pytorch/releases/download/v0.0.1/age_gender.tflite",
    # Alternative: patlevin's face detector lite
    "https://github.com/patlevin/face-detector-lite/raw/main/fdlite/data/age_googlenet.tflite",
]

models_dir = os.path.join(os.path.dirname(__file__), "../assets/models")
os.makedirs(models_dir, exist_ok=True)

output_path = os.path.join(models_dir, "age_gender_ethnicity.tflite")

print("Downloading age/gender/ethnicity TFLite model...")
print(f"Output: {output_path}")

for i, url in enumerate(MODEL_URLS, 1):
    try:
        print(f"\nAttempt {i}/{len(MODEL_URLS)}: {url}")
        urllib.request.urlretrieve(url, output_path)
        
        # Verify it's not HTML
        with open(output_path, 'rb') as f:
            header = f.read(20)
            if b'<!DOCTYPE' in header or b'<html' in header:
                print("  ❌ Downloaded file is HTML, trying next source...")
                os.remove(output_path)
                continue
            
            # Check for TFLite magic number (0x54464C33 = "TFL3")
            if header[:4] == b'TFL3':
                print(f"  ✅ Valid TFLite model downloaded!")
                file_size = os.path.getsize(output_path)
                print(f"  Size: {file_size:,} bytes ({file_size/1024:.1f} KB)")
                break
            else:
                print(f"  ⚠️  File doesn't have TFLite header, but may still work")
                file_size = os.path.getsize(output_path)
                print(f"  Size: {file_size:,} bytes")
                break
                
    except Exception as e:
        print(f"  ❌ Failed: {e}")
        if os.path.exists(output_path):
            os.remove(output_path)
else:
    print("\n❌ All download attempts failed!")
    exit(1)

print("\n✅ Model download complete!")
print("\nNote: This model may have different output format than the original.")
print("You might need to adjust the UnifiedTFLiteService prediction parsing.")
