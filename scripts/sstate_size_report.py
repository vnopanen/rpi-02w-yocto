#!/usr/bin/env python3
import sys
import os
from pathlib import Path

def format_size(size_bytes):
    """Convert raw bytes into a human-readable string (KB, MB, GB)."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0 or unit == 'TB':
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0

def analyze_sstate(sstate_dir, top_n=10):
    sstate_path = Path(sstate_dir)
    if not sstate_path.exists():
        print(f"WARN: SState directory '{sstate_dir}' not found.", file=sys.stderr)
        return None

    total_size = 0
    file_count = 0
    artifact_sizes = []

    # Recursively traverse sstate-cache (handling hash subdirectories like ab/, 3f/, etc.)
    for path in sstate_path.glob("**/*"):
        if path.is_file():
            try:
                size = path.stat().st_size
                total_size += size
                file_count += 1
                
                # Track compression/archive payloads separately for individual sizing
                if path.suffix in ['.zst', '.gz', '.xz', '.tgz', '.tar'] or '.tar.' in path.name:
                    artifact_sizes.append((path.name, size))
            except OSError:
                continue

    # Sort largest packages first
    artifact_sizes.sort(key=lambda x: x[1], reverse=True)

    return {
        "total_size_human": format_size(total_size),
        "total_files": file_count,
        "largest_artifacts": artifact_sizes[:top_n]
    }

if __name__ == "__main__":
    sstate_dir = sys.argv[1] if len(sys.argv) > 1 else "build/sstate-cache"
    top_n = int(sys.argv[2]) if len(sys.argv) > 2 else 10

    data = analyze_sstate(sstate_dir, top_n)
    if data:
        print(f"### SState Cache Storage Analysis")
        print(f"- **Total Cache Footprint:** {data['total_size_human']} across `{data['total_files']}` total files")
        print("")
        print(f"#### Top {len(data['largest_artifacts'])} Largest Individual SState Packages:")
        print("| Size | Package Name |")
        print("| :--- | :--- |")
        for name, size in data['largest_artifacts']:
            print(f"| `{format_size(size)}` | `{name}` |")
          
