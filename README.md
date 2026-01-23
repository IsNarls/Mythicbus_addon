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
```

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
