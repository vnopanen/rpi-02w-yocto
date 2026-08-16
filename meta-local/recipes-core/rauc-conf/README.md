# RAUC Keys & Configuration Guide

This directory manages the RAUC update system configuration and target keyring.

---

## 1. Key Storage Location

All signing keys and certificates for local development are stored in the git-ignored `keys/` directory:

```text
rpi-02w-yocto/
├── keys/
│   ├── ca.key.pem          <-- Private signing key
│   └── ca.cert.pem         <-- Public certificate
```

---

## 2. Generating Development Keys

To generate a key pair for RAUC update bundle signing and target verification:

```bash
mkdir -p keys
openssl req -x509 -newkey rsa:4096 -nodes -keyout keys/ca.key.pem -out keys/ca.cert.pem -days 3650 -subj "/CN=Development CA"
```
