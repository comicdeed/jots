# Sticky note color palettes

This palette defines the 12 note colors used in Jots. It is designed to be easy to recognize, easy to remember, and highly readable across both light and dark themes.

This document reflects the design source in [ColorPalettes.md](ColorPalettes.md) and the browser preview in [sticky-note-color-palettes.html](sticky-note-color-palettes.html).

## Design rationale

The palette uses familiar object names instead of abstract technical labels. Names such as Banana, Tangerine, Ocean, and Mint are easier to remember and help users associate a note color with a concept quickly.

The set balances warm, cool, and neutral tones:

- Warm colors: Banana, Tangerine, Peach, Watermelon
- Cool colors: Bubblegum, Lavender, Ocean, Sea Glass, Mint
- Neutral colors: Pear, Pebble, Graphite

This spread helps users build a clear mental map without creating visual collisions between adjacent note colors.

## Accessibility

Accessibility is a primary requirement of this system. Each background and text pairing is tuned to meet WCAG 2.1 Level AAA contrast for standard-sized text, with a target of at least 7:1.

### Light mode

Light mode uses soft pastel backgrounds with dark, saturated text. This keeps the notes visually light while preserving strong legibility.

### Dark mode

Dark mode uses deeper, richer backgrounds with light text. This preserves the original hue identity without producing muddy or low-contrast tones.

### Picker chip

Each palette also includes a vivid picker chip. This color is meant for selection controls and swatches, not for large background areas or text.

## Palette reference

The table below lists the full palette set for both light and dark themes, along with the picker chip color used in the UI.

| Theme | Light background | Light text | Dark background | Dark text | Picker chip |
| --- | --- | --- | --- | --- | --- |
| Banana | `#FFF59D` | `#3A3300` | `#423700` | `#FFFBE6` | `#FFB300` |
| Tangerine | `#FFCC80` | `#4A1A00` | `#5C2800` | `#FFF1E6` | `#FF6D00` |
| Peach | `#FFCCBC` | `#421202` | `#662D29` | `#FFEDED` | `#FF5252` |
| Watermelon | `#FFCDD2` | `#470505` | `#5E121E` | `#FFEDF0` | `#D50000` |
| Bubblegum | `#F8BBD0` | `#36041F` | `#5C153E` | `#FDE6F2` | `#F50057` |
| Lavender | `#E1BEE7` | `#1F0442` | `#3D1B63` | `#F2E6FC` | `#AA00FF` |
| Ocean | `#BBDEFB` | `#031B40` | `#0D3057` | `#E6F0FA` | `#2979FF` |
| Sea Glass | `#B2DFDB` | `#00211B` | `#093D38` | `#E6F9F6` | `#00BFA5` |
| Mint | `#C8E6C9` | `#08290D` | `#0E421C` | `#E8F7EC` | `#00C853` |
| Pear | `#F0F4C3` | `#142B09` | `#38450C` | `#F4FCE6` | `#AEEA00` |
| Pebble | `#F5F5F5` | `#292929` | `#292929` | `#F2F2F2` | `#9E9E9E` |
| Graphite | `#B0BEC5` | `#10171A` | `#151E24` | `#E3EAEF` | `#546E7A` |

## Usage guidelines

- Keep each theme pair intact. The light and dark values are designed to work together as a single note system.
- Use the picker chip only for selection controls and swatches, not for text or large background areas.
- Do not replace the text colors with pure black or pure white unless a separate accessibility review confirms that the change is still readable.
- Preserve the naming pattern when adding or referring to new note color entries.

## Summary

This palette system balances memorable naming, balanced hue selection, and careful contrast tuning. The result is a set of note colors that is easy to recognize, comfortable to read, and consistent across both light and dark interfaces.
