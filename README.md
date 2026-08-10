# Mythicbus Addon Packager

Automates pulling Wowhead talent builds, generating `Talents.lua`, and zipping the Mythicbus addon.

## Requirements
- Python 3.10+
- Google Chrome (or Chromium)
- ChromeDriver compatible with your Chrome version
- Python packages: `selenium`, `Pillow`

Install deps:
```bash
python -m pip install selenium Pillow
```

Or using the repo venv + requirements:
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Files and Folders
- `wowhead_table_scraper.py` -> scrapes Wowhead and writes `Support_files/wowhead_table_results.csv`
- `Generate Lua Table.py` -> converts CSV to `Mythicbus/Talents.lua`
- `run_mythicbus_pipeline.py` -> runs the full pipeline and creates `Mythicbus.zip`
- `Support_files/` -> input/output CSVs and scrape artifacts

## Run Locally
```bash
python run_mythicbus_pipeline.py
```

Optional flags:
```bash
python run_mythicbus_pipeline.py --no-headless
python run_mythicbus_pipeline.py --input-csv Support_files/wowhead-class-spec-urls.csv
python run_mythicbus_pipeline.py --output-csv Support_files/wowhead_table_results.csv
python run_mythicbus_pipeline.py --output-lua Mythicbus/Talents.lua
python run_mythicbus_pipeline.py --zip-path Mythicbus.zip
python run_mythicbus_pipeline.py --discord-channel-id 1451759197677944906
python run_mythicbus_pipeline.py --no-discord-upload
```

## Release to CurseForge
The GitHub Actions workflow uploads to CurseForge when a `v*` tag is pushed.
To automate the local build, commit, push, and tag step, add a GitHub token to
`.env`:

```bash
github_token=YOUR_GITHUB_TOKEN
```

Then run:

```bash
python release_mythicbus.py 0.1.1
```

This runs the addon pipeline, commits the generated files, pushes the current
branch, and pushes `v0.1.1`. The pushed tag triggers the CurseForge workflow.
If `.venv/bin/python` exists, the release script uses it for the addon pipeline
so Selenium and Pillow do not need to be installed globally.

To upload a CurseForge beta build without running talent collection, use a
`-beta` version tag:

```bash
python release_mythicbus.py 0.1.2-beta.1 --skip-build --allow-empty
```

Tags containing `-beta` upload to CurseForge with `releaseType: "beta"`.
Normal tags upload with `releaseType: "release"`, for example:

```bash
python release_mythicbus.py 0.1.2 --skip-build --allow-empty
```

The workflow sends a Discord bot message with the addon zip attached after
CurseForge accepts the upload when these GitHub repository secrets are set:

```bash
DISCORD_TOKEN
DISCORD_CHANNEL_ID
```

The CurseForge upload defaults to `gameVersionNames: ["12.1.0"]`. To override
that without changing the workflow, set this GitHub repository variable:

```bash
CURSEFORGE_GAME_VERSION_NAMES
```

Use a comma-separated value for multiple supported versions, for example
`12.1.0,12.1.5`.

## Discord Upload
After the zip is built, the pipeline can post it to Discord as a bot attachment.

Create a `.env` file in the repo root:
```bash
discord_token=YOUR_BOT_TOKEN
discord_channel_id=1451759197677944906
```

Notes:
- `discord_token` is required for upload.
- `discord_channel_id` is optional; default is `1451759197677944906`.
- You can override channel at runtime with `--discord-channel-id`.
- Use `--no-discord-upload` to skip Discord posting.

## Cron (Debian Example)
Edit crontab:
```bash
crontab -e
```

Run daily at 3:15 AM:
```bash
15 3 * * * cd /path/to/Mythicbus_addon_packager && /usr/bin/python3 run_mythicbus_pipeline.py >> cron.log 2>&1
```

## Notes
- `Support_files/chrome_selenium_profile/` is ignored by git.
- If Chrome is not found on Linux, ensure `chromedriver` and `google-chrome` (or `chromium`) are installed and on `PATH`.
