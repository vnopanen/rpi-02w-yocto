# Yocto for Raspberry Pi Zero 2 W

This repository contains the setup for building a lightweight Yocto image (`core-image-minimal`) for the **Raspberry Pi Zero 2 W** (64-bit) using `kas`.

---

## Secrets

### Root user
- **Username**: `root`
- **Password**: `root` (default)

#### How to modify the root password in the build:
The root password hash is defined in [kas-project.yml](./kas-project.yml):

```yaml
local_conf_header:
  minimal-config: |
    ...
    EXTRA_USERS_PARAMS = "usermod -p '<HASH>' root;"
```

To update the password, generate a yescrypt password hash:

```bash
# Using mkpasswd (libxcrypt / whois package)
mkpasswd -m yescrypt your_new_password

# Or using python
python3 -c 'import crypt; print(crypt.crypt("your_new_password", crypt.mkhash(crypt.METHOD_YESCRYPT)))'
```

Then replace the hash string inside `EXTRA_USERS_PARAMS` and rebuild the image.

### Wi-Fi configuration (`.env`)
Wi-Fi credentials are read dynamically from a `.env` file at the root of this workspace (`meta-local/recipes-core/images/core-image-minimal.bbappend`).

Create a `.env` file in the project root before building:

```env
WIFI_SSID="YourWiFiSSID"
WIFI_PSK="YourWiFiPassword"
```

*(Note: Ensure `.env` is kept private and listed in `.gitignore` so secrets are not committed).*

---

## Build

Ensure you have Docker/Podman installed. Run the build using `kas-container`:

```bash
./kas-container build kas-project.yml
```

---

## Flash

*(Note: Replace `/dev/mmcblk0` with your actual SD card device name)*

```bash
sudo bmaptool copy build/tmp/deploy/images/raspberrypi0-2w-64/core-image-minimal-raspberrypi0-2w-64.rootfs.wic.zst /dev/mmcblk0
```
