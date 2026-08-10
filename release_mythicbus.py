import argparse
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote
from urllib.parse import urlparse
from urllib.parse import urlunparse

from run_mythicbus_pipeline import BASE_DIR
from run_mythicbus_pipeline import load_env_file


DEFAULT_RELEASE_PATHS = [
    ".github/workflows/curseforge-release.yml",
    ".gitignore",
    "Mythicbus",
    "Mythicbus.zip",
    "README.md",
    "Support_files",
    "box_image_sizes.json",
    "convert_box_images.py",
    "requirements.txt",
    "release_mythicbus.py",
    "run_mythicbus_pipeline.py",
    "wowhead_table_scraper.py",
]


def run(args, *, check=True, capture_output=False):
    return subprocess.run(
        args,
        cwd=BASE_DIR,
        check=check,
        text=True,
        capture_output=capture_output,
    )


def get_output(args):
    return run(args, capture_output=True).stdout.strip()


def sanitize_text(value, secrets):
    text = str(value)
    for secret in secrets:
        if secret:
            text = text.replace(secret, "<redacted>")
            text = text.replace(quote(secret, safe=""), "<redacted>")
    return text


def get_github_token():
    env_values = load_env_file(BASE_DIR / ".env")
    return (
        os.environ.get("GITHUB_TOKEN")
        or os.environ.get("GH_TOKEN")
        or env_values.get("github_token")
        or env_values.get("GITHUB_TOKEN")
        or env_values.get("GH_TOKEN")
        or ""
    ).strip()


def get_pipeline_python():
    venv_python = BASE_DIR / ".venv" / "bin" / "python"
    if venv_python.exists():
        return str(venv_python)
    return sys.executable


def make_authenticated_remote(remote_url, token):
    parsed = urlparse(remote_url)
    if parsed.scheme != "https" or parsed.hostname != "github.com":
        raise RuntimeError(
            "origin must be an HTTPS GitHub remote, for example "
            "https://github.com/owner/repo.git"
        )
    safe_token = quote(token, safe="")
    netloc = f"x-access-token:{safe_token}@{parsed.hostname}"
    return urlunparse(parsed._replace(netloc=netloc))


def push_ref(push_url, refspec, token):
    result = run(["git", "push", push_url, refspec], check=False, capture_output=True)
    if result.returncode == 0:
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        return
    details = "\n".join(part for part in [result.stdout, result.stderr] if part)
    raise RuntimeError(sanitize_text(f"git push {refspec} failed:\n{details}", [token]))


def ensure_clean_index():
    staged = get_output(["git", "diff", "--cached", "--name-only"])
    if staged:
        raise RuntimeError("There are already staged files. Commit or unstage them first.")


def normalize_tag(version):
    version = version.strip()
    if not version:
        raise ValueError("Version cannot be empty.")
    return version if version.startswith("v") else f"v{version}"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build, commit, push, and tag a Mythicbus CurseForge release."
    )
    parser.add_argument("version", help="Release version, for example 0.1.1 or v0.1.1.")
    parser.add_argument(
        "--branch",
        default="",
        help="Branch to push. Defaults to the current branch.",
    )
    parser.add_argument(
        "--message",
        default="",
        help="Commit message. Defaults to 'Release Mythicbus VERSION'.",
    )
    parser.add_argument(
        "--skip-build",
        action="store_true",
        help="Skip run_mythicbus_pipeline.py and release the current files.",
    )
    parser.add_argument(
        "--no-discord-upload",
        action="store_true",
        help="Deprecated; local Discord uploads are skipped by default.",
    )
    parser.add_argument(
        "--with-local-discord-upload",
        action="store_true",
        help="Allow run_mythicbus_pipeline.py to post the local zip to Discord before release.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would happen without committing, pushing, or tagging.",
    )
    parser.add_argument(
        "--push-only",
        action="store_true",
        help="Push the current HEAD and existing tag without building or committing.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    tag = normalize_tag(args.version)
    version = tag[1:]
    branch = args.branch or get_output(["git", "branch", "--show-current"])
    if not branch:
        raise RuntimeError("Could not determine the current branch. Pass --branch.")

    token = get_github_token()
    if not token and not args.dry_run:
        raise RuntimeError("Missing GitHub token. Set GITHUB_TOKEN, GH_TOKEN, or github_token in .env.")

    ensure_clean_index()

    if args.push_only:
        tag_exists = run(
            ["git", "rev-parse", "-q", "--verify", f"refs/tags/{tag}"],
            check=False,
            capture_output=True,
        )
        if tag_exists.returncode != 0:
            raise RuntimeError(f"Tag does not exist locally: {tag}")
        if get_output(["git", "status", "--short"]):
            raise RuntimeError("Working tree has changes. Commit or stash them before --push-only.")
    elif not args.skip_build:
        build_cmd = [get_pipeline_python(), str(BASE_DIR / "run_mythicbus_pipeline.py")]
        if not args.with_local_discord_upload:
            build_cmd.append("--no-discord-upload")
        print("Running addon pipeline...")
        if args.dry_run:
            print(" ".join(build_cmd))
        else:
            run(build_cmd)

    if not args.push_only:
        tag_exists = run(
            ["git", "rev-parse", "-q", "--verify", f"refs/tags/{tag}"],
            check=False,
            capture_output=True,
        )
        if tag_exists.returncode == 0:
            raise RuntimeError(f"Tag already exists locally: {tag}")

        changed = get_output(["git", "status", "--short"])
        if not changed:
            raise RuntimeError("No changes to release.")

        print("Staging release paths...")
        if args.dry_run:
            print("\n".join(DEFAULT_RELEASE_PATHS))
            return

        run(["git", "add", "--", *DEFAULT_RELEASE_PATHS])
        staged = get_output(["git", "diff", "--cached", "--name-only"])
        if not staged:
            raise RuntimeError("No release files were staged.")

        message = args.message or f"Release Mythicbus {version}"
        run(["git", "commit", "-m", message])
        run(["git", "tag", tag])

    remote_url = get_output(["git", "remote", "get-url", "origin"])
    push_url = make_authenticated_remote(remote_url, token)

    print(f"Pushing {branch} and {tag} to origin...")
    push_ref(push_url, f"HEAD:{branch}", token)
    push_ref(push_url, tag, token)
    print(f"Release tag pushed: {tag}")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"release failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
