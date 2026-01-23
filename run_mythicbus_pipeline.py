import argparse
import subprocess
import sys
import zipfile
from pathlib import Path

from convert_box_images import convert_box_images

BASE_DIR = Path(__file__).resolve().parent
SUPPORT_DIR = BASE_DIR / "Support_files"
MYTHICBUS_DIR = BASE_DIR / "Mythicbus"
IMAGE_SRC_DIR = SUPPORT_DIR / "box_images"
IMAGE_DST_DIR = MYTHICBUS_DIR / "Images" / "box_images"
SIZE_JSON = BASE_DIR / "box_image_sizes.json"
SIZE_LUA = MYTHICBUS_DIR / "ImageSizes.lua"

DEFAULT_INPUT_CSV = SUPPORT_DIR / "wowhead-class-spec-urls.csv"
DEFAULT_OUTPUT_CSV = SUPPORT_DIR / "wowhead_table_results.csv"
DEFAULT_LUA = MYTHICBUS_DIR / "Talents.lua"
DEFAULT_ZIP = BASE_DIR / "Mythicbus.zip"

GENERATOR_SCRIPT = BASE_DIR / "Generate Lua Table.py"


def run_scraper(python_exe, input_csv, output_csv, headless=True):
    args = [
        python_exe,
        str(BASE_DIR / "wowhead_table_scraper.py"),
        "--input-csv",
        str(input_csv),
        "--output-csv",
        str(output_csv),
    ]
    if headless:
        args.append("--headless")
    else:
        args.append("--no-headless")
    subprocess.check_call(args)


def run_generator(python_exe, input_csv, output_lua, generator_script):
    args = [
        python_exe,
        str(generator_script),
        "--input-csv",
        str(input_csv),
        "--output-lua",
        str(output_lua),
    ]
    subprocess.check_call(args)


def zip_addon(src_dir, zip_path):
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for p in src_dir.rglob("*"):
            if p.is_dir():
                continue
            rel = p.relative_to(src_dir.parent)
            zf.write(p, rel)


def clear_dir(path: Path):
    if not path.exists():
        return
    for item in path.iterdir():
        if item.is_file():
            try:
                item.unlink()
            except Exception:
                pass


def main():
    parser = argparse.ArgumentParser(description="Run Wowhead scrape + Lua generation + zip.")
    parser.add_argument("--input-csv", default=str(DEFAULT_INPUT_CSV))
    parser.add_argument("--output-csv", default=str(DEFAULT_OUTPUT_CSV))
    parser.add_argument("--output-lua", default=str(DEFAULT_LUA))
    parser.add_argument("--zip-path", default=str(DEFAULT_ZIP))
    parser.add_argument("--generator", default=str(GENERATOR_SCRIPT))
    parser.add_argument("--no-headless", action="store_true")
    args = parser.parse_args()

    input_csv = Path(args.input_csv)
    output_csv = Path(args.output_csv)
    output_lua = Path(args.output_lua)
    zip_path = Path(args.zip_path)
    generator_script = Path(args.generator)

    SUPPORT_DIR.mkdir(parents=True, exist_ok=True)
    MYTHICBUS_DIR.mkdir(parents=True, exist_ok=True)

    run_scraper(sys.executable, input_csv, output_csv, headless=not args.no_headless)
    clear_dir(IMAGE_DST_DIR)
    try:
        sizes = convert_box_images(
            src_dir=IMAGE_SRC_DIR,
            out_dir=IMAGE_DST_DIR,
            size_json=SIZE_JSON,
            size_lua=SIZE_LUA,
            delete_png=False,
        )
    except RuntimeError as exc:
        print(str(exc))
        return
    run_generator(sys.executable, output_csv, output_lua, generator_script)
    zip_addon(MYTHICBUS_DIR, zip_path)

    print(f"CSV: {output_csv}")
    print(f"Lua: {output_lua}")
    print(f"Zip: {zip_path}")


if __name__ == "__main__":
    main()
