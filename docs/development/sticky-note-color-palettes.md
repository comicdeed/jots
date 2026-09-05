# Sticky note color palettes

This palette defines the 12 note colors used in Jots. The names are practical and memorable, and the colors are tuned for strong contrast across light and dark app themes.

This document reflects the browser preview in [sticky-note-color-palettes.html](sticky-note-color-palettes.html).

## Design rationale

The palette uses familiar object names instead of abstract technical labels. Names such as Banana, Tangerine, Ocean, and Mint are easy to remember and give users a clear visual cue before they read the note itself.

The set balances warm, cool, and neutral tones:

- Warm: Banana, Tangerine, Peach, Watermelon
- Cool: Bubblegum, Lavender, Ocean, Sea Glass, Mint
- Neutral: Pear, Pebble, Graphite

This spread helps users group notes by meaning without creating visual collisions between adjacent colors.

## Theme mapping

The app follows a simple default rule:

- Light app UI uses the pastel note values.
- Dark app UI uses the vibrant mid-tone values by default.
- If the user enables the Ultra Dark note override, the app uses the deeper dark values only while the app UI is dark.

This keeps the default experience intuitive while preserving a lower-glare option for users who prefer a dimmer note surface in dark mode.

## Accessibility

Accessibility is a key requirement of the palette system. Each note pair is tuned for WCAG 2.1 Level AAA contrast for standard text, with a target of at least 7:1.

### Light UI

Light UI uses soft pastel backgrounds with dark, saturated text. This keeps the notes visually light while preserving strong legibility.

### Dark UI

Dark UI defaults to richer mid-tones with darker text. This keeps the original hue identity visible without making colors look muddy or low-contrast.

### Ultra Dark override

The Ultra Dark override uses deeply toned backgrounds with near-white text. This option is intended for low-light environments where glare reduction matters more than a bright, saturated note surface.

### Picker chip

Each palette includes a vivid picker chip. The chip is used for selection controls and swatches, not for large background areas or text.

## Palette reference

The table below lists the full palette set for light, vibrant dark, and Ultra Dark note modes, along with the picker chip color used in the UI.

| Theme | Light background | Light text | Vibrant dark background | Vibrant dark text | Ultra Dark background | Ultra Dark text | Picker chip |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Banana | `#FFF59D` | `#3A3300` | `#F0B429` | `#2E1E00` | `#423700` | `#FFFBE6` | `#FFB300` |
| Tangerine | `#FFCC80` | `#4A1A00` | `#ED7D31` | `#330C00` | `#5C2800` | `#FFF1E6` | `#FF6D00` |
| Peach | `#FFCCBC` | `#421202` | `#E66057` | `#360502` | `#662D29` | `#FFEDED` | `#FF5252` |
| Watermelon | `#FFCDD2` | `#470505` | `#D14354` | `#360009` | `#5E121E` | `#FFEDF0` | `#D50000` |
| Bubblegum | `#F8BBD0` | `#36041F` | `#D15E93` | `#360017` | `#5C153E` | `#FDE6F2` | `#F50057` |
| Lavender | `#E1BEE7` | `#1F0442` | `#9973C2` | `#25054A` | `#3D1B63` | `#F2E6FC` | `#AA00FF` |
| Ocean | `#BBDEFB` | `#031B40` | `#5C9DDE` | `#031B38` | `#0D3057` | `#E6F0FA` | `#2979FF` |
| Sea Glass | `#B2DFDB` | `#00211B` | `#3BA89B` | `#002B25` | `#093D38` | `#E6F9F6` | `#00BFA5` |
| Mint | `#C8E6C9` | `#08290D` | `#2BB063` | `#002B0F` | `#0E421C` | `#E8F7EC` | `#00C853` |
| Pear | `#F0F4C3` | `#142B09` | `#B8C74E` | `#1F2900` | `#38450C` | `#F4FCE6` | `#AEEA00` |
| Pebble | `#F5F5F5` | `#292929` | `#9E9E9E` | `#141414` | `#292929` | `#F2F2F2` | `#9E9E9E` |
| Graphite | `#B0BEC5` | `#10171A` | `#6F8A99` | `#06151F` | `#151E24` | `#E3EAEF` | `#546E7A` |

## Usage guidelines

- Keep each theme pair intact. The light, dark, and Ultra Dark values are designed to work together as one note system.
- Use the picker chip only for selection controls and swatches, not for text or large background areas.
- Do not replace text colors with pure black or pure white unless an accessibility review confirms that the change remains readable.
- Preserve the current naming pattern when adding new note colors or referring to existing ones.

## Summary

This palette system balances memorable naming, clear hue identity, and careful contrast tuning. The result is a set of note colors that is easy to recognize, comfortable to read, and adaptable to both light and dark app interfaces.
