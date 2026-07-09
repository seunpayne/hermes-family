#!/usr/bin/env python3
"""Remove solid gray/white backgrounds from logo PNGs by making near-gray pixels transparent.

Usage: python3 remove-logo-background.py <input.png> <output.png>

Detects pixels where all RGB channels are within 25 of each other AND brightness > 190.
Those pixels become fully transparent. Everything else is preserved.
Also crops the output to the content bounding box.
"""

import sys
from PIL import Image

GRAY_TOLERANCE = 25       # max diff between channels to be considered "gray"
BRIGHTNESS_THRESHOLD = 190  # min brightness to be considered "background"

def remove_background(input_path: str, output_path: str) -> None:
    img = Image.open(input_path).convert('RGBA')
    data = list(img.getdata())

    new_data = []
    removed = 0
    for r, g, b, a in data:
        is_gray = max(r, g, b) - min(r, g, b) < GRAY_TOLERANCE
        is_bright = r > BRIGHTNESS_THRESHOLD and g > BRIGHTNESS_THRESHOLD and b > BRIGHTNESS_THRESHOLD

        if is_gray and is_bright:
            new_data.append((r, g, b, 0))
            removed += 1
        else:
            new_data.append((r, g, b, a))

    img.putdata(new_data)

    # Crop to content
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    img.save(output_path, 'PNG')

    total = len(data)
    pct = 100 * removed / total if total else 0
    print(f"Removed {removed}/{total} background pixels ({pct:.1f}%)")
    print(f"Final size: {img.size[0]}x{img.size[1]}")
    print(f"Saved: {output_path}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 remove-logo-background.py <input.png> <output.png>")
        sys.exit(1)
    remove_background(sys.argv[1], sys.argv[2])
