#!/usr/bin/env python3
import sys
from pathlib import Path

def format_size(size_bytes):
    """Convert raw bytes into a human-readable string (KB, MB, GB)."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0 or unit == 'TB':
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0

def iter_sstate_artifacts(sstate_path):
    # Recursively traverse sstate-cache (handling hash subdirectories like ab/, 3f/, etc.)
    for path in sstate_path.glob("**/*"):
        if path.is_file():
            try:
                size = path.stat().st_size
                # Track compression/archive payloads separately for individual sizing
                if path.suffix in ['.zst', '.gz', '.xz', '.tgz', '.tar'] or '.tar.' in path.name:
                    yield (path.name, size)
            except OSError:
                continue


def analyze_sstate(sstate_dir):
    sstate_path = Path(sstate_dir)
    if not sstate_path.exists():
        print(f"WARN: SState directory '{sstate_dir}' not found.", file=sys.stderr)
        return None

    artifacts = iter_sstate_artifacts(sstate_path)
    return sorted(artifacts, key=lambda x: x[1])

if __name__ == "__main__":
    sstate_dir = sys.argv[1] if len(sys.argv) > 1 else "build/sstate-cache"

    data = analyze_sstate(sstate_dir)
    if data:
        for name, size in data:
            print(f"{format_size(size)}    {name}")
