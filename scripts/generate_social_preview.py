#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Jots Contributors
"""
Generate GitHub Social Preview image (1280x640) for Jots by compositing
the three screenshot variants (Light, Vibrant Dark, Ultra-Dark) with
seamless diagonal cuts through the sticky notes.
"""

import argparse
import os
import sys
from PIL import Image, ImageDraw

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SCREENSHOTS_DIR = os.path.join(REPO_ROOT, 'data', 'screenshots')

DEFAULT_LIGHT_PATH = os.path.join(SCREENSHOTS_DIR, 'jots-light.png')
DEFAULT_DARK_PATH = os.path.join(SCREENSHOTS_DIR, 'jots-dark.png')
DEFAULT_ULTRA_PATH = os.path.join(SCREENSHOTS_DIR, 'jots-dark-ultra.png')
DEFAULT_OUTPUT_PATH = os.path.join(SCREENSHOTS_DIR, 'social-preview.png')

WIDTH = 1280
HEIGHT = 640
SCALE = 4  # 4x supersampling for ultra-smooth antialiased diagonal seams

LANCZOS = getattr(Image, 'Resampling', Image).LANCZOS


def prepare_base_image(image_path, target_w, target_h):
    """Crop and resize screenshot uniformly to fill target dimensions."""
    img = Image.open(image_path).convert('RGBA')
    img_w, img_h = img.size

    scale = target_w / img_w
    new_h = int(img_h * scale)
    if new_h < target_h:
        scale = target_h / img_h
        new_w = int(img_w * scale)
        img_resized = img.resize((new_w, target_h), LANCZOS)
        left = (new_w - target_w) // 2
        return img_resized.crop((left, 0, left + target_w, target_h))
    else:
        new_w = target_w
        img_resized = img.resize((new_w, new_h), LANCZOS)
        top = (new_h - target_h) // 2
        return img_resized.crop((0, top, target_w, top + target_h))


def create_composite(
    light_img,
    dark_img,
    ultra_img,
    cut1_top=0.18,
    cut1_bottom=0.09,
    cut2_top=0.35,
    cut2_bottom=0.26,
    divider_width=0,
    divider_color=(255, 255, 255, 90)
):
    """
    Composite 3 images with diagonal cuts and antialiasing across all notes.
    """
    w_hi = WIDTH * SCALE
    h_hi = HEIGHT * SCALE

    # Scaled coordinates
    t1 = int(cut1_top * w_hi)
    b1 = int(cut1_bottom * w_hi)
    t2 = int(cut2_top * w_hi)
    b2 = int(cut2_bottom * w_hi)

    # Hi-res scaled source images
    img1 = light_img.resize((w_hi, h_hi), LANCZOS)
    img2 = dark_img.resize((w_hi, h_hi), LANCZOS)
    img3 = ultra_img.resize((w_hi, h_hi), LANCZOS)

    # Base: slice 1 (Light)
    composite = img1.copy()

    # Slice 2 (Vibrant Dark)
    mask2 = Image.new('L', (w_hi, h_hi), 0)
    draw2 = ImageDraw.Draw(mask2)
    poly2 = [(t1, 0), (t2, 0), (b2, h_hi), (b1, h_hi)]
    draw2.polygon(poly2, fill=255)
    composite.paste(img2, (0, 0), mask2)

    # Slice 3 (Ultra-Dark)
    mask3 = Image.new('L', (w_hi, h_hi), 0)
    draw3 = ImageDraw.Draw(mask3)
    poly3 = [(t2, 0), (w_hi, 0), (w_hi, h_hi), (b2, h_hi)]
    draw3.polygon(poly3, fill=255)
    composite.paste(img3, (0, 0), mask3)

    # Optional divider lines
    if divider_width > 0:
        draw_comp = ImageDraw.Draw(composite, 'RGBA')
        scaled_div = divider_width * SCALE
        
        shadow_color = (0, 0, 0, 120)
        draw_comp.line([(t1 + scaled_div, 0), (b1 + scaled_div, h_hi)], fill=shadow_color, width=scaled_div + 2)
        draw_comp.line([(t2 + scaled_div, 0), (b2 + scaled_div, h_hi)], fill=shadow_color, width=scaled_div + 2)

        draw_comp.line([(t1, 0), (b1, h_hi)], fill=divider_color, width=scaled_div)
        draw_comp.line([(t2, 0), (b2, h_hi)], fill=divider_color, width=scaled_div)

    # Downsample for seamless antialiased seams
    return composite.resize((WIDTH, HEIGHT), LANCZOS)


def main():
    parser = argparse.ArgumentParser(description="Generate GitHub Social Preview banner for Jots")
    parser.add_argument('--light', default=DEFAULT_LIGHT_PATH, help="Path to light screenshot")
    parser.add_argument('--dark', default=DEFAULT_DARK_PATH, help="Path to dark screenshot")
    parser.add_argument('--ultra', default=DEFAULT_ULTRA_PATH, help="Path to ultra-dark screenshot")
    parser.add_argument('--output', default=DEFAULT_OUTPUT_PATH, help="Output PNG path")
    parser.add_argument('--cut1-top', type=float, default=0.18, help="Top ratio for cut 1")
    parser.add_argument('--cut1-bottom', type=float, default=0.09, help="Bottom ratio for cut 1")
    parser.add_argument('--cut2-top', type=float, default=0.35, help="Top ratio for cut 2")
    parser.add_argument('--cut2-bottom', type=float, default=0.26, help="Bottom ratio for cut 2")
    parser.add_argument('--divider', type=int, default=0, help="Divider line width in px (0 for seamless)")
    args = parser.parse_args()

    for p in [args.light, args.dark, args.ultra]:
        if not os.path.exists(p):
            print(f"Error: Screenshot file not found: {p}", file=sys.stderr)
            sys.exit(1)

    print("Cropping and resizing source screenshots...")
    light_img = prepare_base_image(args.light, WIDTH, HEIGHT)
    dark_img = prepare_base_image(args.dark, WIDTH, HEIGHT)
    ultra_img = prepare_base_image(args.ultra, WIDTH, HEIGHT)

    print(f"Compositing diagonal slices across notes into {WIDTH}x{HEIGHT}...")
    result = create_composite(
        light_img,
        dark_img,
        ultra_img,
        cut1_top=args.cut1_top,
        cut1_bottom=args.cut1_bottom,
        cut2_top=args.cut2_top,
        cut2_bottom=args.cut2_bottom,
        divider_width=args.divider
    )

    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    result.save(args.output, 'PNG', optimize=True)
    file_size_kb = os.path.getsize(args.output) / 1024
    print(f"Successfully generated social preview: {args.output} ({file_size_kb:.1f} KB)")


if __name__ == '__main__':
    main()
