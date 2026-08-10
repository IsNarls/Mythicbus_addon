import argparse
import json
import subprocess
import sys
import zipfile
from pathlib import Path

import urllib3

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
DEFAULT_DISCORD_CHANNEL_ID = "1451759197677944906"

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
            if any(part.startswith(".") or part == "__pycache__" for part in p.parts):
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


def load_env_file(env_path: Path):
    values = {}
    if not env_path.exists():
        return values
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if value and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]
        values[key] = value
    return values


def get_discord_token(env_values):
    return (
        env_values.get("discord_token")
        or env_values.get("DISCORD_TOKEN")
        or ""
    ).strip()


def get_discord_channel_id(env_values, cli_value):
    if cli_value:
        return str(cli_value).strip()
    return (
        env_values.get("discord_channel_id")
        or env_values.get("DISCORD_CHANNEL_ID")
        or DEFAULT_DISCORD_CHANNEL_ID
    ).strip()


def upload_zip_to_discord(zip_path: Path, token: str, channel_id: str):
    if not zip_path.exists():
        raise RuntimeError(f"Zip does not exist: {zip_path}")
    http = urllib3.PoolManager()
    response = http.request(
        "POST",
        f"https://discord.com/api/v10/channels/{channel_id}/messages",
        headers={"Authorization": f"Bot {token}"},
        fields={
            "content": f"Mythicbus build: {zip_path.name}",
            "files[0]": (zip_path.name, zip_path.read_bytes(), "application/zip"),
        },
        timeout=urllib3.Timeout(connect=10.0, read=120.0),
    )
    if response.status not in (200, 201):
        body = response.data.decode("utf-8", errors="replace")
        err = body
        try:
            parsed = json.loads(body)
            err = parsed.get("message", body)
        except Exception:
            pass
        raise RuntimeError(
            f"Discord upload failed ({response.status}): {err}"
        )


def main():
    parser = argparse.ArgumentParser(description="Run Wowhead scrape + Lua generation + zip.")
    parser.add_argument("--input-csv", default=str(DEFAULT_INPUT_CSV))
    parser.add_argument("--output-csv", default=str(DEFAULT_OUTPUT_CSV))
    parser.add_argument("--output-lua", default=str(DEFAULT_LUA))
    parser.add_argument("--zip-path", default=str(DEFAULT_ZIP))
    parser.add_argument("--generator", default=str(GENERATOR_SCRIPT))
    parser.add_argument("--no-headless", action="store_true")
    parser.add_argument("--discord-channel-id", default="")
    parser.add_argument("--no-discord-upload", action="store_true")
    args = parser.parse_args()

    input_csv = Path(args.input_csv)
    output_csv = Path(args.output_csv)
    output_lua = Path(args.output_lua)
    zip_path = Path(args.zip_path)
    generator_script = Path(args.generator)
    env_values = load_env_file(BASE_DIR / ".env")
    discord_token = get_discord_token(env_values)
    discord_channel_id = get_discord_channel_id(env_values, args.discord_channel_id)

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
    if args.no_discord_upload:
        print("Discord upload skipped (--no-discord-upload).")
        return
    if not discord_token:
        print("Discord upload skipped: discord_token not found in .env.")
        return
    try:
        upload_zip_to_discord(zip_path, discord_token, discord_channel_id)
    except RuntimeError as exc:
        print(str(exc))
        return
    print(f"Discord upload complete (channel {discord_channel_id}).")


if __name__ == "__main__":
    main()
