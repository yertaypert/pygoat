# pygoat/secret_store.py
import os


def _from_vault(name):
    addr = os.getenv("VAULT_ADDR")
    if not addr:
        return None
    import hvac  # imported lazily so the app works without hvac when Vault isn't used
    client = hvac.Client(url=addr, token=os.getenv("VAULT_TOKEN"))
    data = client.secrets.kv.v2.read_secret_version(
        path="pygoat", mount_point="secret"
    )["data"]["data"]
    return data.get(name)


def get_secret(name, default=None):
    # 1. Centralized: Vault
    val = _from_vault(name)
    if val:
        return val
    # 2. File: NAME_FILE=/path/to/file (Docker/K8s secrets style)
    path = os.getenv(f"{name}_FILE")
    if path and os.path.exists(path):
        with open(path) as f:
            return f.read().strip()
    # 3. Environment variable
    val = os.getenv(name, default)
    if val is None:
        raise RuntimeError(f"Secret {name} is not configured")
    return val
