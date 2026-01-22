import argparse
import csv
import os
import time
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException, WebDriverException, StaleElementReferenceException


BASE_DIR = Path(__file__).resolve().parent
SUPPORT_DIR = BASE_DIR / "Support_files"

DEFAULT_INPUT_CSV = str(SUPPORT_DIR / "wowhead-class-spec-urls.csv")
DEFAULT_OUTPUT_CSV = str(SUPPORT_DIR / "wowhead_table_results.csv")
DEFAULT_TABLE_XPATH = "/html/body/div[6]/div/div[3]/div/div[3]/div[2]/div/div[2]/div[2]/div[9]/div"

COPY_PREFIX = "Copy"
PAGE_LOAD_TIMEOUT = 35
READY_WAIT_TIMEOUT = 12
SCRIPT_TIMEOUT = 8
CLICK_SLEEP = 0.25
HOOK_TIMEOUT = 2.5
HOOK_POLL_SLEEP = 0.05
GET_RETRIES = 2
GET_BACKOFF_SECONDS = (1.0, 2.5)
URL_ATTEMPTS = 3


def ensure_support_dir():
    SUPPORT_DIR.mkdir(parents=True, exist_ok=True)


def sniff_url_column(rows, fieldnames):
    url_col = None
    for c in fieldnames or []:
        sample = next((row.get(c, "") for row in rows if row.get(c)), "")
        if "http" in (sample or ""):
            url_col = c
            break
    if url_col is None and fieldnames:
        url_col = fieldnames[0]
    return url_col


def read_input_rows(path):
    with open(path, "r", newline="", encoding="utf-8-sig") as f:
        r = csv.DictReader(f)
        rows = list(r)
        if not rows:
            return [], None
        url_col = sniff_url_column(rows, r.fieldnames or [])
        return rows, url_col


def build_driver(headless=True):
    chrome_opts = Options()
    if headless:
        chrome_opts.add_argument("--headless=new")
    chrome_opts.page_load_strategy = "none"
    chrome_opts.add_argument("--window-size=1400,900")
    chrome_opts.add_argument("--disable-dev-shm-usage")
    chrome_opts.add_argument("--disable-gpu")
    chrome_opts.add_argument("--ignore-certificate-errors")
    chrome_opts.add_argument("--ignore-ssl-errors=yes")
    chrome_opts.add_argument("--disable-extensions")
    chrome_opts.add_argument("--disable-sync")
    chrome_opts.add_argument("--disable-background-networking")
    chrome_opts.add_argument("--disable-client-side-phishing-detection")
    chrome_opts.add_argument("--disable-component-update")
    chrome_opts.add_argument("--no-first-run")
    chrome_opts.add_argument("--no-default-browser-check")
    chrome_opts.add_argument("--log-level=3")
    chrome_opts.add_argument("--disable-logging")
    chrome_opts.add_argument("--disable-features=Translate,MediaRouter,BackForwardCache")

    try:
        service = Service(log_output=os.devnull)
    except TypeError:
        service = Service()
    driver = webdriver.Chrome(service=service, options=chrome_opts)
    driver.set_page_load_timeout(PAGE_LOAD_TIMEOUT)
    driver.set_script_timeout(SCRIPT_TIMEOUT)
    return driver


def install_copy_hook(driver):
    driver.execute_script(
        r"""
        (function(){
          if (window.__mbus_hook_installed) return;
          window.__mbus_hook_installed = true;
          window.__mbus_lastCopied = "";
          window.__mbus_lastCopiedAt = 0;
          function setCopy(txt){
            try{
              txt = (txt || "").toString();
              if (!txt) return;
              window.__mbus_lastCopied = txt;
              window.__mbus_lastCopiedAt = Date.now();
            }catch(e){}
          }
          function pickCandidate(){
            try{
              let s = "";
              try { s = (window.getSelection && window.getSelection().toString()) || ""; } catch(e){}
              s = (s || "").trim();
              if (s && s.length >= 10) return s;

              const ae = document.activeElement;
              if (ae && (ae.tagName === "TEXTAREA" || ae.tagName === "INPUT")) {
                const v = (ae.value || "");
                const ss = (typeof ae.selectionStart === "number") ? ae.selectionStart : 0;
                const ee = (typeof ae.selectionEnd === "number") ? ae.selectionEnd : v.length;
                const sub = (v.substring(ss, ee) || "").trim();
                if (sub && sub.length >= 10) return sub;
                const vv = v.trim();
                if (vv && vv.length >= 10) return vv;
              }

              const tas = Array.from(document.querySelectorAll("textarea"));
              let best = "";
              for (const t of tas) {
                const v = ((t && t.value) ? t.value : "").trim();
                if (v.length > best.length) best = v;
              }
              if (best && best.length >= 10) return best;
              return "";
            }catch(e){
              return "";
            }
          }

          document.addEventListener("copy", function(e){
            try{
              const txt = pickCandidate();
              if (txt && txt.length >= 10) {
                setCopy(txt);
                try{
                  if (e && e.clipboardData) {
                    e.clipboardData.setData("text/plain", txt);
                    e.preventDefault();
                  }
                }catch(_){}
              }
            }catch(_){}
          }, true);

          try{
            const origExec = document.execCommand ? document.execCommand.bind(document) : null;
            if (origExec) {
              document.execCommand = function(cmd){
                const res = origExec(cmd);
                try{
                  if ((cmd||"").toLowerCase() === "copy") {
                    const txt = pickCandidate();
                    if (txt && txt.length >= 10) setCopy(txt);
                  }
                }catch(_){}
                return res;
              };
            }
          }catch(e){}

          try{
            const orig = navigator.clipboard && navigator.clipboard.writeText
              ? navigator.clipboard.writeText.bind(navigator.clipboard)
              : null;
            if (navigator.clipboard && navigator.clipboard.writeText) {
              navigator.clipboard.writeText = function(txt){
                setCopy(txt);
                try { return Promise.resolve(); } catch(e){}
                if (orig) return orig(txt);
                return Promise.resolve();
              };
            }
          }catch(e){}
        })();
        """
    )


def clear_last_copied(driver):
    try:
        driver.execute_script("window.__mbus_lastCopied=''; window.__mbus_lastCopiedAt=0;")
    except Exception:
        pass


def read_last_copied(driver):
    try:
        v = driver.execute_script("return window.__mbus_lastCopied || '';")
        return (v or "").strip()
    except Exception:
        return ""


def click_and_read(driver, btn):
    clear_last_copied(driver)
    try:
        driver.execute_script("arguments[0].scrollIntoView({block:'center'});", btn)
        time.sleep(0.05)
        driver.execute_script("arguments[0].click();", btn)
    except (WebDriverException, StaleElementReferenceException):
        return ""

    time.sleep(CLICK_SLEEP)
    end = time.time() + HOOK_TIMEOUT
    while time.time() < end:
        v = read_last_copied(driver)
        if v and len(v) >= 10:
            return v
        time.sleep(HOOK_POLL_SLEEP)
    return ""


def collect_table_buttons(driver, table_xpath, fallback=False):
    try:
        table = driver.find_element(By.XPATH, table_xpath)
        buttons = table.find_elements(By.CSS_SELECTOR, "button")
    except Exception:
        if not fallback:
            buttons = []
        else:
            buttons = driver.find_elements(By.CSS_SELECTOR, "#guide-body button")

    out = []
    for b in buttons:
        try:
            label = (b.text or "").strip()
        except Exception:
            label = ""
        if label.startswith(COPY_PREFIX):
            out.append(b)
    return out


def collect_buttons_fallback(driver):
    # Fallback: search any table within #guide-body, else any button in #guide-body
    try:
        tables = driver.find_elements(By.CSS_SELECTOR, "#guide-body table")
    except Exception:
        tables = []
    for t in tables:
        try:
            buttons = t.find_elements(By.CSS_SELECTOR, "button")
        except Exception:
            continue
        out = []
        for b in buttons:
            try:
                label = (b.text or "").strip()
            except Exception:
                label = ""
            if label.startswith(COPY_PREFIX):
                out.append(b)
        if out:
            return out
    try:
        return collect_table_buttons(driver, "//invalid-xpath", fallback=True)
    except Exception:
        return []


def safe_get(driver, url):
    last_err = None
    for attempt in range(1, GET_RETRIES + 1):
        try:
            driver.get(url)
            return True
        except WebDriverException as e:
            last_err = e
            time.sleep(GET_BACKOFF_SECONDS[min(attempt - 1, len(GET_BACKOFF_SECONDS) - 1)])
    if last_err:
        raise last_err
    return False


def wait_for_table_or_guide(driver, table_xpath):
    def _ready(d):
        try:
            d.find_element(By.XPATH, table_xpath)
            return True
        except Exception:
            pass
        try:
            d.find_element(By.CSS_SELECTOR, "#guide-body")
            return True
        except Exception:
            return False
    try:
        WebDriverWait(driver, READY_WAIT_TIMEOUT).until(_ready)
    except TimeoutException:
        pass


def process_url(driver, url, table_xpath):
    ok = safe_get(driver, url)
    if not ok:
        return []
    wait_for_table_or_guide(driver, table_xpath)
    install_copy_hook(driver)
    buttons = collect_table_buttons(driver, table_xpath, fallback=False)
    if not buttons:
        buttons = collect_buttons_fallback(driver)
    rows = []
    for idx, b in enumerate(buttons, start=1):
        try:
            label = (b.text or "").strip()
        except Exception:
            label = ""
        try:
            talent = click_and_read(driver, b)
        except Exception:
            talent = ""
        rows.append((idx, label, talent))
    return rows


def main():
    parser = argparse.ArgumentParser(description="Test scraper for Wowhead talent table.")
    parser.add_argument("--input-csv", default=DEFAULT_INPUT_CSV)
    parser.add_argument("--output-csv", default=DEFAULT_OUTPUT_CSV)
    parser.add_argument("--url", default="")
    parser.add_argument("--table-xpath", default=DEFAULT_TABLE_XPATH)
    parser.add_argument("--headless", action="store_true", default=True)
    parser.add_argument("--no-headless", action="store_false", dest="headless")
    args = parser.parse_args()

    ensure_support_dir()

    rows = []
    url_rows = []
    url_col = "URL"
    input_urls = []
    output_urls = set()

    if args.url:
        url_rows = [{"URL": args.url}]
    else:
        url_rows, url_col = read_input_rows(args.input_csv)
    input_urls = [((r.get(url_col, "") or "").strip()) for r in url_rows if (r.get(url_col, "") or "").strip()]

    def process_url_list(driver, url_rows, url_col):
        out_rows = []
        out_urls = set()
        for r in url_rows:
            url = (r.get(url_col, "") or "").strip()
            if not url:
                continue
            table_rows = []
            for attempt in range(1, URL_ATTEMPTS + 1):
                try:
                    table_rows = process_url(driver, url, args.table_xpath)
                except WebDriverException:
                    try:
                        driver.quit()
                    except Exception:
                        pass
                    driver = build_driver(headless=args.headless)
                    table_rows = []
                except Exception:
                    table_rows = []
                if table_rows:
                    break
            for idx, label, talent in table_rows:
                out_rows.append({
                    "Class": r.get("Class", ""),
                    "Spec": r.get("Spec", ""),
                    "Role": r.get("Role", ""),
                    "RowIndex": idx,
                    "ButtonLabel": label,
                    "TalentString": talent,
                    "URL": url,
                })
                out_urls.add(url)
        return out_rows, out_urls, driver

    driver = build_driver(headless=args.headless)
    try:
        first_rows, first_urls, driver = process_url_list(driver, url_rows, url_col)
        rows.extend(first_rows)
        output_urls.update(first_urls)

        missed = [u for u in input_urls if u not in output_urls]
        if missed:
            missed_rows = [{url_col: u} for u in missed]
            retry_rows, retry_urls, driver = process_url_list(driver, missed_rows, url_col)
            rows.extend(retry_rows)
            output_urls.update(retry_urls)
    finally:
        try:
            driver.quit()
        except Exception:
            pass

    fieldnames = ["Class", "Spec", "Role", "RowIndex", "ButtonLabel", "TalentString", "URL"]
    with open(args.output_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

    print(f"Wrote {len(rows)} rows to: {args.output_csv}")
    if input_urls:
        missed = [u for u in input_urls if u not in output_urls]
        missed_path = SUPPORT_DIR / "missed_urls.csv"
        with open(missed_path, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["missed_url"])
            for u in missed:
                w.writerow([u])
        print(f"Wrote {len(missed)} missed URLs to: {missed_path}")


if __name__ == "__main__":
    main()
