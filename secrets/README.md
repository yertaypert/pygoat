# Encrypted application secrets (SOPS + age)

`secrets/pygoat.enc.yaml` holds `DJANGO_SECRET_KEY` and `DATABASE_URL` encrypted
with [SOPS](https://getsops.io/) using [age](https://age-encryption.org/). The
ciphertext is safe to commit; only the age private key can decrypt it.

## Key location

The private key is **not** in this repository. Put it at the standard path:

```
~/.config/sops/age/keys.txt
```

or point SOPS at it explicitly:

```bash
export SOPS_AGE_KEY_FILE=/path/to/keys.txt
```

The matching public recipient is in `.sops.yaml`.

## Run the app with the decrypted values

```bash
sops exec-env secrets/pygoat.enc.yaml '.venv/bin/python manage.py check'
sops exec-env secrets/pygoat.enc.yaml '.venv/bin/python manage.py runserver'
```

Values are decrypted into the child process environment only; they are not
written to disk.

## Update a secret

```bash
sops secrets/pygoat.enc.yaml   # opens $EDITOR on the decrypted document
```

## Add a recipient / rotate the file key

```bash
sops updatekeys secrets/pygoat.enc.yaml
```

## Rules

- Never commit `secrets/*.plain.yaml` or the age private key (`key.txt`).
- Never paste `sops --decrypt` output into issues, logs, or reports.
- The encrypted file contains *demo* values for this exercise. Real deployments
  should encrypt the production values and keep the private key in a dedicated
  secret store.
