#!/usr/bin/env python3
import sys
import os

print("Python version:", sys.version)
print("\nPython path:")
for path in sys.path:
    print(f"  {path}")

print("\nChecking for libcamera and kmsxx files:")
for root, dirs, files in os.walk("/usr/local"):
    for file in files:
        if ("libcamera" in file.lower() or "kms" in file.lower()) and file.endswith(('.so', '.py', '.pyi')):
            print(f"  {os.path.join(root, file)}")

print("\nEnvironment variables:")
for var in ['PYTHONPATH', 'LD_LIBRARY_PATH', 'PKG_CONFIG_PATH']:
    print(f"  {var}: {os.environ.get(var, 'Not set')}")

print("\nTrying to import libcamera...")
try:
    import libcamera
    print("✓ libcamera imported successfully")
except ImportError as e:
    print(f"✗ libcamera import failed: {e}")

print("\nTrying to import pykms...")
try:
    import pykms
    print("✓ pykms imported successfully")
    if hasattr(pykms, 'PixelFormat'):
        print("✓ PixelFormat attribute found")
        print(f"  RGB888: {pykms.PixelFormat.RGB888}")
    else:
        print("✗ PixelFormat attribute missing")
except ImportError as e:
    print(f"✗ pykms import failed: {e}")
    
print("\nTrying to import kms...")
try:
    import kms
    print("✓ kms imported successfully")
    if hasattr(kms, 'PixelFormat'):
        print("✓ PixelFormat attribute found")
        print(f"  RGB888: {kms.PixelFormat.RGB888}")
    else:
        print("✗ PixelFormat attribute missing")
except ImportError as e:
    print(f"✗ kms import failed: {e}")

print("\nTrying to import picamera2...")
try:
    import picamera2
    print("✓ picamera2 imported successfully")
except ImportError as e:
    print(f"✗ picamera2 import failed: {e}")
