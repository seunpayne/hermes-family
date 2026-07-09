#!/usr/bin/env python3
"""Create a light/white variant of a dark logo for use on dark backgrounds.

Usage: python3 lighten-logo.py <input.png> <output.png>

Converts dark navy/blue pixels to white while preserving:
  - Alpha channel (smooth anti-aliased edges)
  - Already-light pixels (accents, highlights)
  - Transparent pixels

Use when a logo has good contrast on light backgrounds but is invisible
on dark navy headers/footers.
"""

import sys
from PIL import Image

DARK_THRESHOLD = 80    # brightness below this → convert to white
MID_THRESHOLD = 180    # brightness below this → convert to light gray
WHITE = (255, 255, 255)
LIGHT_GRAY = (220, 220, 220)


def brightness(r: int, g: int, b: int) -> float:
    """Perceptual brightness (ITU-R BT.601)."""
    return 0.299 * r + 0.587 * g + 0.114 * b


def lighten_logo(input_path: str, output_path: str) -> None:
    img = Image.open(input_path).convert('RGBA')
    pixels = list(img.getdata())

    new_pixels = []
    darkened = 0
    for r, g, b, a in pixels:
        if a == 0:
            new_pixels.append((0, 0, 0, 0))
        else:
            bri = brightness(r, g, b)
            if bri < DARK_THRESHOLD:
                new_pixels.append((*WHITE, a))
                darkened += 1
            elif bri < MID_THRESHOLD:
                new_pixels.append((*LIGHT_GRAY, a))
                darkened += 1
            else:
                new_pixels.append((r, g, b, a))

    img.putdata(new_pixels)
    img.save(output_path, 'PNG')

    total = len(pixels)
    pct = 100 * darkened / total if total else 0
    print(f"Lightened {darkened}/{total} pixels ({pct:.1f}%)")
    print(f"Saved: {output_path}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 lighten-logo.py <input.png> <output.png>")
        sys.exit(1)
    lighten_logo(sys.argv[1], sys.argv[2])
