# Repository Helper Scripts

This directory contains development utilities and asset-generation scripts for Jots.

---

## `generate_social_preview.py`

Generates the GitHub repository Open Graph social preview banner ([`data/screenshots/social-preview.png`](../data/screenshots/social-preview.png)) by compositing three screenshot variants (**Light**, **Vibrant Dark**, and **Ultra-Dark**) with seamless diagonal cuts.

### What it does
* Reads the three theme screenshot variants from `data/screenshots/`.
* Uniformly scales and crops the screenshots to GitHub's standard social preview resolution (`1280 × 640 px`, 2:1 aspect ratio).
* Applies antialiased polygon masking at 4× supersampling to create smooth diagonal cuts across the sticky notes cluster.
* Outputs an optimized static PNG under 1 MB suitable for upload to GitHub repository settings.

### Assumptions about input images
1. **Source Paths**: Defaults to:
   * `data/screenshots/jots-light.png` (Light mode)
   * `data/screenshots/jots-dark.png` (Vibrant Dark mode)
   * `data/screenshots/jots-dark-ultra.png` (Ultra-Dark mode)
2. **Resolution & Alignment**:
   * All three screenshots must share the **exact same resolution** (e.g. `1277 × 699 px`).
   * Window positions and desktop framing must be **identical across all three captures** so that note boundaries, text lines, and UI controls align seamlessly across the diagonal seams.
3. **Environment**:
   * Requires Python 3 with `Pillow` (`PIL`).

### Usage

Run with default paths and settings:
```bash
./scripts/generate_social_preview.py
```

Customize inputs, outputs, or cut positions:
```bash
# Specify custom image paths or output destination
./scripts/generate_social_preview.py \
  --light path/to/light.png \
  --dark path/to/dark.png \
  --ultra path/to/ultra.png \
  --output custom-preview.png

# Adjust cut positions (0.0 to 1.0 ratios across width)
./scripts/generate_social_preview.py \
  --cut1-top 0.18 --cut1-bottom 0.09 \
  --cut2-top 0.35 --cut2-bottom 0.26

# Optional: Add divider lines between slices (e.g., 2px wide)
./scripts/generate_social_preview.py --divider 2
```

---

## Other Scripts in this Directory

* **`generate_icons.py`**: Generates multi-size icon assets across build-time icon variants (default, devel, seasonal).
* **`render_pngs.py`**: Rasterizes SVG icons to target PNG resolutions inside packaging and sandbox builds.
