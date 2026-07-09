#!/usr/bin/env python3
"""Hero image colour grading pipeline.

Usage:
  python3 grading-hero-image.py <input.jpg> <output.jpg>

Applies:
  1. Overall desaturation by 15%
  2. Green saturation boost (H 42-128): +20%
  3. Red/orange saturation boost (H 0-28 or 227-255): +15%
  4. Shadow lift (Value < 90): +30%

This matches the Chaingang Design Addendum v2.0 A-002 spec.
"""

import sys, os
from PIL import Image

def grade_image(input_path: str, output_path: str, quality: int = 92):
    img = Image.open(input_path)
    
    from PIL import ImageEnhance
    enhancer = ImageEnhance.Color(img)
    img = enhancer.enhance(0.85)
    
    hsv = img.convert('HSV')
    pixels = list(hsv.getdata())
    
    new_pixels = []
    for h, s, v in pixels:
        if 42 <= h <= 128:
            s = min(255, int(s * 1.20))
        if (0 <= h <= 28) or (h >= 227):
            s = min(255, int(s * 1.15))
        if v < 90:
            v = min(255, int(v * 1.3))
        new_pixels.append((h, s, v))
    
    hsv.putdata(new_pixels)
    result = hsv.convert('RGB')
    
    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)
    result.save(output_path, quality=quality)
    print(f"Graded: {os.path.getsize(output_path)} bytes @ {result.size}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 grading-hero-image.py <input.jpg> <output.jpg> [quality]")
        sys.exit(1)
    quality = int(sys.argv[3]) if len(sys.argv) > 3 else 92
    grade_image(sys.argv[1], sys.argv[2], quality)
