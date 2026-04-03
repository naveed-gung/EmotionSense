from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "icons"
WEB = ROOT / "web"

APP_ICON = ASSETS / "app_icon.png"
FAVICON = WEB / "favicon.png"
FONT = Path(
    "C:/Users/naveed/develop/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"
)

BG = "#0D0D1A"
BLUE_A = (77, 124, 254)
BLUE_B = (77, 124, 254, 153)
WHITE = (255, 255, 255)
ICON_CODEPOINT = "\uf72d"


def lerp(a, b, t):
    return int(a + (b - a) * t)


def gradient_circle(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = image.load()
    cx = cy = size / 2
    radius = size * 0.28
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            distance = (dx * dx + dy * dy) ** 0.5
            if distance <= radius:
                t = min(max((dx + dy + radius * 1.2) / (radius * 2.4), 0), 1)
                alpha = lerp(255, BLUE_B[3], t)
                px[x, y] = (BLUE_A[0], BLUE_A[1], BLUE_A[2], alpha)
    return image


def draw_mark(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), BG)
    circle = gradient_circle(size)
    canvas.alpha_composite(circle)

    draw = ImageDraw.Draw(canvas, "RGBA")
    font = ImageFont.truetype(str(FONT), round(size * 0.39))
    bbox = draw.textbbox((0, 0), ICON_CODEPOINT, font=font)
    glyph_w = bbox[2] - bbox[0]
    glyph_h = bbox[3] - bbox[1]
    x = (size - glyph_w) / 2 - bbox[0]
    y = (size - glyph_h) / 2 - bbox[1]
    draw.text((x, y), ICON_CODEPOINT, font=font, fill=WHITE)

    return canvas


def save_square(image: Image.Image, path: Path, size: int):
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.LANCZOS)
    resized.save(path)


def main():
    if not FONT.exists():
        raise FileNotFoundError(f"Material icon font not found: {FONT}")

    base = draw_mark(1024)
    save_square(base, APP_ICON, 1024)
    save_square(base, FAVICON, 64)
    print(f"Generated {APP_ICON}")
    print(f"Generated {FAVICON}")


if __name__ == "__main__":
    main()
