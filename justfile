set shell := ["bash", "-euo", "pipefail", "-c"]

sstate_dir := "build/sstate-cache"

[private]
default:
    @just --choose --unsorted

# Build the image with kas-container.
build:
    ./kas-container build kas-project.yml

# Build only the RAUC update bundle.
update-bundle:
    ./kas-container shell kas-project.yml -c 'bitbake update-bundle'

# Copy and install the RAUC update bundle on the board.
update-install board_ip:
    scp build/tmp/deploy/images/raspberrypi0-2w-64/update-bundle-raspberrypi0-2w-64.raucb \
        root@{{board_ip}}:/tmp/update.raucb && \
        ssh root@{{board_ip}} 'rauc install /tmp/update.raucb && reboot'

# Report individual sstate archive sizes.
sstate-report:
    python3 scripts/sstate_size_report.py {{sstate_dir}}

# Remove orphan .siginfo files from the sstate cache.
sstate-clean-orphans:
    python3 openembedded-core/scripts/sstate-cache-management.py \
        --cache-dir {{sstate_dir}} \
        --remove-orphans \
        --yes \
        --verbose

# Validate sstate archive/signature pairs and Zstandard integrity.
sstate-validate:
    python3 scripts/sstate_validate.py {{sstate_dir}}
    find {{sstate_dir}} -type f -name '*.tar.zst' -print0 | xargs -0 -r zstd -q -t

# Summarize the longest tasks from the latest buildstats directory.
buildstats:
    buildstats_dir=$(ls -td build/tmp/buildstats/*/ 2>/dev/null | head -n 1); \
    python3 openembedded-core/scripts/buildstats-summary --sort duration "$buildstats_dir"
