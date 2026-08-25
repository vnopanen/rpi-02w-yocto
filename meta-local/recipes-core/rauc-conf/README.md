# RAUC keys and configuration guide

This directory manages the RAUC update system configuration and target keyring.

---

## 1. Key storage location

The public certificate is committed with the layer. Only the private signing key is stored in the git-ignored `keys/` directory:

```text
rpi-02w-yocto/
├── keys/
│   └── ca.key.pem                         <-- Private signing key
└── meta-local/recipes-core/rauc-conf/files/
    └── ca.cert.pem                        <-- Public certificate
```

The private key is required only when generating an update bundle. It must never be committed.

---

## 2. Generating development keys

To generate a development key pair for RAUC update bundle signing and target verification:

```bash
mkdir -p keys
openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout keys/ca.key.pem \
    -out meta-local/recipes-core/rauc-conf/files/ca.cert.pem \
    -days 3650 -subj "/CN=Development CA"
```
