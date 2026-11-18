#!/usr/bin/env python3
"""Print non-reversible fingerprints of resolved secrets (safe for evidence)."""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pygoat.secret_store import get_secret  # noqa: E402

for name in ("DJANGO_SECRET_KEY", "DATABASE_URL"):
    value = get_secret(name, "")
    digest = hashlib.sha256(value.encode()).hexdigest()[:12] if value else "unset"
    print(f"{name}: len={len(value):>3} sha256_12={digest}")
