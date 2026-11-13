#!/usr/bin/env python3
"""Draws the Chipload app icon: a fluted end mill with a curling chip peeling off the cut, on a
dark shop-floor gradient with a warm amber glow. Recognizable at a glance as a machining tool, not
a generic calculator icon.

    python tools/make_icon.py

Writes assets/icon.png and App/Shared/Assets.xcassets/AppIcon.appiconset (1024 universal, for iOS).
"""
import json
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "App", "Shared", "Assets.xcassets")
ICONSET = os.path.join(OUT, "AppIcon.appiconset")
SIZE = 1024
SS = 3
S = SIZE * SS

CHARCOAL_LIGHT = (58, 56, 54)
CHARCOAL = (30, 28, 27)
CHARCOAL_DEEP = (12, 11, 10)
STEEL = (210, 212, 216)
STEEL_SHADOW = (120, 122, 128)
AMBER = (255, 149, 36)
AMBER_DEEP = (214, 96, 16)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def background():
    small = Image.new("RGB", (256, 256))
    px = small.load()
    for y in range(256):
        for x in range(256):
            t = (x * 0.35 + y * 0.65) / 255
            if t < 0.55:
                c = lerp(CHARCOAL_LIGHT, CHARCOAL, t / 0.55)
            else:
                c = lerp(CHARCOAL, CHARCOAL_DEEP, (t - 0.55) / 0.45)
            px[x, y] = c
    img = small.resize((S, S), Image.BICUBIC)

    # a warm amber glow low in the frame, like a shop light catching the swarf
    glow = Image.new("L", (S, S), 0)
    gd = ImageDraw.Draw(glow)
    cx, cy, r = int(S * 0.62), int(S * 0.70), int(S * 0.55)
    gd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(S // 6))
    amber_layer = Image.new("RGB", (S, S), AMBER_DEEP)
    img = Image.composite(amber_layer, img, glow.point(lambda v: int(v * 0.35)))
    return img


def draw_endmill(canvas):
    """A fluted end mill, shank at upper-left, cutting tip at lower-right, with a chip curling off
    the tip. Drawn as a rotated capsule (shank) + tapered tip with helical flute lines."""
    d = ImageDraw.Draw(canvas, "RGBA")
    u = S / 100

    # Work in an unrotated local frame (tool pointing straight down), then rotate the whole layer.
    tool = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(tool)
    cx = S // 2
    shank_w = 18 * u
    shank_top = 8 * u
    shank_bottom = 50 * u
    tip_bottom = 82 * u

    # Shank: a rounded rectangle with a vertical highlight for a metallic look.
    td.rounded_rectangle(
        [cx - shank_w / 2, shank_top, cx + shank_w / 2, shank_bottom],
        radius=shank_w / 2, fill=STEEL_SHADOW + (255,)
    )
    hi_w = shank_w * 0.32
    td.rounded_rectangle(
        [cx - shank_w / 2 + shank_w * 0.14, shank_top + 2 * u, cx - shank_w / 2 + shank_w * 0.14 + hi_w, shank_bottom - 2 * u],
        radius=hi_w / 2, fill=STEEL + (255,)
    )

    # Tip: tapers slightly, with 3 helical flute grooves (dark diagonal bands).
    tip_w_top, tip_w_bottom = shank_w, shank_w * 0.78
    td.polygon([
        (cx - tip_w_top / 2, shank_bottom), (cx + tip_w_top / 2, shank_bottom),
        (cx + tip_w_bottom / 2, tip_bottom), (cx - tip_w_bottom / 2, tip_bottom),
    ], fill=STEEL + (255,))
    # flat cutting end
    td.ellipse([cx - tip_w_bottom / 2, tip_bottom - 3 * u, cx + tip_w_bottom / 2, tip_bottom + 3 * u], fill=STEEL_SHADOW + (255,))

    # Flutes: simple evenly-spaced diagonal hatch marks across the tapered tip -- a flat line-art
    # drill bit, not an attempted 3D helix (which crossed into an unreadable X at this size).
    flute_h = tip_bottom - shank_bottom
    n_notches = 6
    for i in range(n_notches):
        frac = (i + 0.5) / n_notches
        y = shank_bottom + flute_h * frac
        w = (tip_w_top + (tip_w_bottom - tip_w_top) * frac) / 2
        td.line(
            [(cx - w * 0.95, y - 3 * u), (cx + w * 0.95, y + 3 * u)],
            fill=STEEL_SHADOW + (190,), width=max(2, int(2.0 * u))
        )

    rotated = tool.rotate(-34, resample=Image.BICUBIC, center=(cx, (shank_top + tip_bottom) / 2))
    canvas.alpha_composite(rotated) if canvas.mode == "RGBA" else canvas.paste(rotated, (0, 0), rotated)
    return d


def draw_chip(canvas):
    """A curling comma-shaped chip (swarf) peeling away from the cutting tip, in warm amber to read
    as hot metal, distinct from the cool steel of the tool."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    u = S / 100
    cx, cy = int(60 * u), int(68 * u)

    # A smooth curl, drawn as overlapping filled circles (a "stamp" brush) rather than PIL's
    # width-only line, which has no round joins and turns sharp corners into spikes.
    points = []
    turns = 1.35
    steps = 160
    for s in range(steps + 1):
        frac = s / steps
        angle = frac * turns * 2 * math.pi
        radius = (3 + frac * 13) * u
        x = cx + math.cos(angle) * radius
        y = cy - math.sin(angle) * radius * 1.05
        points.append((x, y))
    width_start, width_end = 9 * u, 2.2 * u
    for i, (x, y) in enumerate(points):
        frac = i / (len(points) - 1)
        w = width_start + (width_end - width_start) * frac
        color = lerp(AMBER, AMBER_DEEP, frac) + (255,)
        r = w / 2
        ld.ellipse([x - r, y - r, x + r, y + r], fill=color)
    canvas.alpha_composite(layer)


def draw():
    img = background().convert("RGBA")
    draw_endmill(img)
    draw_chip(img)
    return img.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)


def main():
    os.makedirs(ICONSET, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "assets"), exist_ok=True)
    master = draw()
    master.save(os.path.join(ROOT, "assets", "icon.png"))
    master.save(os.path.join(ICONSET, "icon-1024.png"))

    images = [{"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}]
    with open(os.path.join(ICONSET, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
    with open(os.path.join(OUT, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
    print("wrote", ICONSET)


if __name__ == "__main__":
    main()
