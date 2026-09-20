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
Wi-Fi credentials are injected in flash step. Create `~/rpi-02w-yocto.env` before flashing:

```env
WIFI_SSID="YourWiFiSSID"
WIFI_PSK="YourWiFiPassword"
```

### RAUC keys
Generate a development key pair for RAUC update bundle signing and target verification with:

```bash
mkdir -p keys
openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout keys/ca.key.pem \
    -out keys/ca.cert.pem \
    -days 3650 -subj "/CN=Development CA"
```

Keep both keys in the git-ignored `keys/` directory.

---

## Build

Ensure you have Docker/Podman installed. Run the build using `kas-container`:

```bash
just build
```

For RAUC update bundle:

```bash
just update-bundle
```

---

## Flash

```bash
just flash
# or explicitly if not using defaults:
just flash /dev/mmcblk0 ~/rpi-02w-yocto.env
```
