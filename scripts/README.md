# Repository Helper Scripts

This directory contains development utilities and asset-generation scripts for Jots.

---

## `generate_social_preview.py`

Generates the GitHub repository Open Graph social preview banner ([`data/screenshots/social-preview.png`](../data/screenshots/social-preview.png)) by compositing theme screenshot variants (**Light**, **Vibrant Dark**, and **Ultra-Dark**) with seamless diagonal cuts across note windows while respecting GitHub's 40pt safe area template.

### What it does
* **Assembled Mode (`--assemble`)**: Takes individual transparent window captures (notes, preferences dialog) and composites them cleanly onto day and night wallpapers within GitHub's 40pt safe margins.
* **Full-Desktop Screenshot Mode (Default)**: Uniformly scales and crops full-desktop screenshot captures to GitHub's standard resolution (`1280 × 640 px`, 2:1 aspect ratio).
* Applies antialiased polygon masking at 4× supersampling to create smooth diagonal cuts across the sticky notes cluster.
* Outputs an optimized static PNG under 1 MB suitable for upload to GitHub repository settings.

### Assumptions about input images

#### 1. Individual Window Captures (`--assemble`)
* **Window PNGs**: Transparent RGBA captures with native GTK4 drop shadows:
  * `light1.png` (Green note / active checklist, Light)
  * `light2.png` (Orange note / scribble text, Light)
  * `vibrant1.png` (Orange note, Vibrant Dark)
  * `vibrant2.png` (Green note, Vibrant Dark)
  * `ultra-dark1.png` (Orange note, Ultra-Dark)
  * `ultra-dark2.png` (Green note, Ultra-Dark)
  * `preference.png` (Preferences dialog)
* **Wallpapers**:
  * Light / daytime wallpaper image
  * Dark / nighttime wallpaper image

#### 2. Full-Desktop Screenshot Mode
* **Source Paths**: `data/screenshots/jots-light.png`, `jots-dark.png`, `jots-dark-ultra.png`.
* All captures must share the **exact same resolution and window placement** so note boundaries align across diagonal seams.

### Usage

Run with default repository screenshots:
```bash
./scripts/generate_social_preview.py
```

Assemble from individual window captures and wallpapers:
```bash
./scripts/generate_social_preview.py \
  --assemble \
  --windows-dir path/to/windows/ \
  --day-wallpaper path/to/day-wallpaper.png \
  --night-wallpaper path/to/night-wallpaper.png \
  --output custom-preview.png
```

Adjust diagonal cut ratios across the canvas (0.0 to 1.0):
```bash
./scripts/generate_social_preview.py \
  --cut1-top 0.23 --cut1-bottom 0.13 \
  --cut2-top 0.42 --cut2-bottom 0.32
```

Optional: Add divider lines between slices (e.g., 2px wide):
```bash
./scripts/generate_social_preview.py --divider 2
```

---

## Other Scripts in this Directory

* **`generate_icons.py`**: Generates multi-size icon assets across build-time icon variants (default, devel, seasonal).
* **`render_pngs.py`**: Rasterizes SVG icons to target PNG resolutions inside packaging and sandbox builds.
