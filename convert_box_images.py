"""Convert Mythicbus box images from PNG to TGA without resizing."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict

def load_image_module():
    try:
        from PIL import Image
    except ImportError as exc:  # pragma: no cover - runtime guard
        raise RuntimeError(
            "Missing Pillow. Install with: python -m pip install Pillow"
        ) from exc
    return Image


BASE_DIR = Path(__file__).resolve().parent
SUPPORT_DIR = BASE_DIR / "Support_files"
ADDON_DIR = BASE_DIR / "Mythicbus"

SRC_DIR = SUPPORT_DIR / "box_images"
OUT_DIR = ADDON_DIR / "Images" / "box_images"
SIZE_PATH = BASE_DIR / "box_image_sizes.json"
SIZE_LUA = ADDON_DIR / "ImageSizes.lua"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert box images to TGA without resizing."
    )
    parser.add_argument(
        "--src-dir",
        default=str(SRC_DIR),
        help="Source directory for PNGs (default: Support_files/box_images).",
    )
    parser.add_argument(
        "--out-dir",
        default=str(OUT_DIR),
        help="Output directory for TGAs (default: Mythicbus/Images/box_images).",
    )
    parser.add_argument(
        "--size-json",
        default=str(SIZE_PATH),
        help="Output JSON path for image sizes.",
    )
    parser.add_argument(
        "--size-lua",
        default=str(SIZE_LUA),
        help="Output Lua path for image sizes.",
    )
    parser.add_argument(
        "--delete-png",
        action="store_true",
        help="Delete source PNG files after conversion.",
    )
    return parser.parse_args()


def convert_box_images(
    src_dir: Path,
    out_dir: Path,
    size_json: Path,
    size_lua: Path,
    delete_png: bool = False,
) -> Dict[str, Dict[str, int]]:
    if not src_dir.is_dir():
        raise FileNotFoundError(f"Source directory not found: {src_dir}")

    png_files = sorted(src_dir.glob("*.png"))
    if not png_files:
        return {}

    out_dir.mkdir(parents=True, exist_ok=True)

    sizes: Dict[str, Dict[str, int]] = {}
    Image = load_image_module()
    for png_path in png_files:
        with Image.open(png_path) as img:
            img = img.convert("RGBA")
            out_name = png_path.with_suffix(".tga").name
            out_path = out_dir / out_name
            img.save(out_path, compress=False)
            sizes[png_path.name] = {
                "width": img.width,
                "height": img.height,
            }
        if delete_png:
            png_path.unlink()

    size_json.write_text(
        json.dumps(sizes, indent=2, sort_keys=True),
        encoding="ascii",
    )

    lua_lines = ["Mythicbus_ImageSizes = {",]
    for name in sorted(sizes):
        info = sizes[name]
        lua_lines.append(
            f'  ["{name}"] = {{ width = {info["width"]}, height = {info["height"]} }},'
        )
    lua_lines.append("}")
    size_lua.write_text("\n".join(lua_lines) + "\n", encoding="ascii")

    return sizes


def main() -> int:
    args = parse_args()
    src_dir = Path(args.src_dir)
    out_dir = Path(args.out_dir)
    size_json = Path(args.size_json)
    size_lua = Path(args.size_lua)

    try:
        sizes = convert_box_images(
            src_dir=src_dir,
            out_dir=out_dir,
            size_json=size_json,
            size_lua=size_lua,
            delete_png=args.delete_png,
        )
    except FileNotFoundError as exc:
        print(str(exc))
        return 1

    if not sizes:
        print(f"No .png files found in {src_dir}")
        return 0

    print(f"Converted {len(sizes)} PNG files to TGA in {out_dir}")
    print(f"Wrote image sizes to {size_json}")
    print(f"Wrote image sizes to {size_lua}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
