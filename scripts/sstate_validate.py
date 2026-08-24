#!/usr/bin/env python3
"""Validate Zstandard sstate archive and signature pairs."""

import argparse
import sys
from pathlib import Path


def validate(cache_dir: Path) -> int:
    archives = set(cache_dir.rglob("*.tar.zst"))
    siginfos = set(cache_dir.rglob("*.tar.zst.siginfo"))

    missing_siginfo = sorted(
        archive
        for archive in archives
        if archive.with_name(archive.name + ".siginfo") not in siginfos
    )
    orphan_siginfo = sorted(
        siginfo
        for siginfo in siginfos
        if siginfo.with_name(siginfo.name.removesuffix(".siginfo")) not in archives
    )

    print(f"Zstandard archives: {len(archives)}")
    print(f"Zstandard signatures: {len(siginfos)}")

    if missing_siginfo:
        print("Archives missing .siginfo:", file=sys.stderr)
        for path in missing_siginfo:
            print(f"  {path}", file=sys.stderr)

    if orphan_siginfo:
        print("Orphan .siginfo files:", file=sys.stderr)
        for path in orphan_siginfo:
            print(f"  {path}", file=sys.stderr)

    return 1 if missing_siginfo or orphan_siginfo else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Zstandard sstate archive and .siginfo pairs."
    )
    parser.add_argument("cache_dir", type=Path, help="sstate cache directory")
    args = parser.parse_args()

    if not args.cache_dir.is_dir():
        parser.error(f"cache directory does not exist: {args.cache_dir}")

    return validate(args.cache_dir)


if __name__ == "__main__":
    raise SystemExit(main())
