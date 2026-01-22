import argparse
import csv
import os
import re
from pathlib import Path

# =========================
# INPUT / OUTPUT
# =========================
BASE_DIR = Path(__file__).resolve().parent
SUPPORT_DIR = BASE_DIR / "Support_files"
ADDON_DIR = BASE_DIR / "Mythicbus"

DEFAULT_INPUT_CSV = str(SUPPORT_DIR / "wowhead_table_results.csv")
DEFAULT_OUTPUT_LUA = str(ADDON_DIR / "Talents.lua")

# If your CSV has headers, we'll try to detect them.
# If it doesn't, we assume columns are:
# class, spec, role, group, label, talentString, url
FALLBACK_KEYS = ["class", "spec", "role", "group", "label", "talentString", "url"]

# Lua global/table name to write
LUA_TABLE_NAME = "Mythicbus_WowheadResults"


# =========================
# HELPERS
# =========================
def lua_escape(s: str) -> str:
    """Escape a Python string for safe inclusion in Lua double-quoted string literal."""
    if s is None:
        s = ""
    s = str(s)
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\r", "\\r").replace("\n", "\\n")
    return s


def sniff_dialect(path: str):
    """Try to detect delimiter (comma/tab/semicolon) via csv.Sniffer."""
    with open(path, "r", encoding="utf-8-sig", newline="") as f:
        sample = f.read(4096)
        f.seek(0)
        try:
            return csv.Sniffer().sniff(sample, delimiters=[",", "\t", ";", "|"])
        except csv.Error:
            return csv.get_dialect("excel")


def looks_like_header(row):
    """Heuristic: if row contains any of the common header words."""
    if not row:
        return False
    joined = " ".join([str(x).strip().lower() for x in row if x is not None])
    header_words = ["class", "spec", "role", "group", "label", "talent", "talentstring", "url", "build", "name"]
    return any(w in joined for w in header_words)


def normalize_key(k: str) -> str:
    """Normalize header keys to simple identifiers."""
    k = (k or "").strip()
    k = k.replace(" ", "_")
    k = re.sub(r"[^a-zA-Z0-9_]", "", k)
    if not k:
        k = "col"
    if re.match(r"^[0-9]", k):
        k = "_" + k
    return k


# =========================
# MAIN
# =========================
def read_rows(input_csv: str):
    dialect = sniff_dialect(input_csv)
    rows = []
    headers = None

    with open(input_csv, "r", encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f, dialect=dialect)
        first = next(reader, None)
        if first is None:
            return [], None

        if looks_like_header(first):
            headers = [normalize_key(h) for h in first]
        else:
            rows.append(first)

        for r in reader:
            if not r:
                continue
            if all((c is None or str(c).strip() == "") for c in r):
                continue
            rows.append(r)

    return rows, headers


def rows_to_dicts(rows, headers):
    out = []
    if headers:
        for r in rows:
            rr = list(r) + [""] * max(0, len(headers) - len(r))
            rr = rr[:len(headers)]
            d = {headers[i]: rr[i] for i in range(len(headers))}
            out.append(d)
    else:
        keys = FALLBACK_KEYS
        for r in rows:
            rr = list(r) + [""] * max(0, len(keys) - len(r))
            rr = rr[:len(keys)]
            d = {keys[i]: rr[i] for i in range(len(keys))}
            out.append(d)
    return out


def write_lua(dict_rows, output_lua: str, table_name: str):
    out_path = Path(output_lua)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- Auto-generated from wowhead_table_results.csv\n")
        f.write("-- Do not edit by hand; re-run the generator script.\n\n")
        f.write(f"{table_name} = {{\n")

        for i, row in enumerate(dict_rows, start=1):
            f.write(f"  [{i}] = {{\n")
            for k, v in row.items():
                k2 = normalize_key(k)
                v2 = lua_escape(v)
                f.write(f'    {k2} = "{v2}",\n')
            f.write("  },\n")

        f.write("}\n")


def main():
    parser = argparse.ArgumentParser(description="Generate Talents.lua from Wowhead CSV.")
    parser.add_argument("--input-csv", default=DEFAULT_INPUT_CSV)
    parser.add_argument("--output-lua", default=DEFAULT_OUTPUT_LUA)
    args = parser.parse_args()

    if not os.path.exists(args.input_csv):
        raise FileNotFoundError(f"Input CSV not found: {args.input_csv}")

    rows, headers = read_rows(args.input_csv)
    dict_rows = rows_to_dicts(rows, headers)
    write_lua(dict_rows, args.output_lua, LUA_TABLE_NAME)

    print(f"Loaded {len(dict_rows)} rows from:\n  {args.input_csv}")
    print(f"Wrote Lua table to:\n  {args.output_lua}")
    print(f"Lua global/table name: {LUA_TABLE_NAME}")


if __name__ == "__main__":
    main()
