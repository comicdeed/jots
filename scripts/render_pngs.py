import os
import sys
import gi
gi.require_version('Rsvg', '2.0')
from gi.repository import Rsvg
import cairo

VARIANTS = ['default', 'devel', 'halloween', 'pride', 'classic']
SIZES = [16, 24, 32, 48, 64, 128, 256, 512]

def render_svg_to_png(svg_path, png_path, width, height):
    handle = Rsvg.Handle.new_from_file(svg_path)
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, width, height)
    ctx = cairo.Context(surface)

    # Scale viewport to target resolution
    dim = handle.get_dimensions()
    ctx.scale(width / dim.width, height / dim.height)
    handle.render_cairo(ctx)

    surface.write_to_png(png_path)

def main():
    print("Rasterizing PNG icon assets inside Flatpak sandbox...")
    for variant in VARIANTS:
        vdir = os.path.join('data', 'icons', variant)
        for sz in SIZES:
            svg_path = os.path.join(vdir, f'{sz}.svg')
            
            # @1x PNG
            png_1x = os.path.join(vdir, 'hicolor', f'{sz}.png')
            render_svg_to_png(svg_path, png_1x, sz, sz)

            # @2x PNG (HiDPI)
            png_2x = os.path.join(vdir, 'hicolor@2', f'{sz}@2.png')
            render_svg_to_png(svg_path, png_2x, sz * 2, sz * 2)

        print(f"  [OK] Rendered PNGs for {variant}")

if __name__ == '__main__':
    main()
