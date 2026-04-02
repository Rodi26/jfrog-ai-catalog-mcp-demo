"""
Sample code for the JFrog AI Catalog Demo — Code Review Assistant.

This file is intentionally written with a mix of good practices and
issues so the AI review produces interesting, varied output.

Run the review with:
    python code_review.py sample_code.py
"""

import hashlib
import os
import sqlite3


# ── User authentication ────────────────────────────────────────────────────────

def authenticate_user(username, password):
    """Authenticate a user against the database."""
    conn = sqlite3.connect("users.db")
    cursor = conn.cursor()
    # BUG: SQL injection vulnerability — never interpolate user input directly
    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    cursor.execute(query)
    user = cursor.fetchone()
    conn.close()
    return user is not None


def hash_password(password):
    """Hash a password for storage."""
    # ISSUE: MD5 is cryptographically broken — use bcrypt or argon2 instead
    return hashlib.md5(password.encode()).hexdigest()


# ── Configuration loader ───────────────────────────────────────────────────────

def load_config(config_path="config.json"):
    """Load application configuration."""
    import json
    # ISSUE: no error handling — will crash if file missing or malformed
    with open(config_path) as f:
        config = json.load(f)
    # ISSUE: hardcoded fallback secret exposed in source code
    config.setdefault("secret_key", "super-secret-key-12345")
    return config


# ── Data processing ────────────────────────────────────────────────────────────

def process_user_data(users: list) -> dict:
    """
    Process a list of user dicts and return a summary.

    Args:
        users: List of dicts with keys 'name', 'age', 'email'

    Returns:
        Summary dict with counts and averages.
    """
    if not users:
        return {"total": 0, "avg_age": 0, "emails": []}

    total = len(users)
    # STYLE: could use statistics.mean() for clarity
    avg_age = sum(u.get("age", 0) for u in users) / total
    emails = [u["email"] for u in users if "email" in u]

    return {
        "total": total,
        "avg_age": round(avg_age, 1),
        "emails": emails,
        "active_count": sum(1 for u in users if u.get("active", False)),
    }


# ── File handling ──────────────────────────────────────────────────────────────

def read_log_file(filepath):
    """Read and return log file contents."""
    # ISSUE: no path traversal protection — user-supplied path is dangerous
    # ISSUE: reads entire file into memory — bad for large files
    with open(filepath) as f:
        return f.read()


def write_output(data, output_dir="/tmp/output"):
    """Write processed data to a file."""
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "result.txt")
    with open(output_path, "w") as f:
        # ISSUE: serializing arbitrary data without sanitization
        f.write(str(data))
    return output_path


# ── Entry point ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Quick smoke test
    sample_users = [
        {"name": "Alice", "age": 30, "email": "alice@example.com", "active": True},
        {"name": "Bob",   "age": 25, "email": "bob@example.com",   "active": False},
        {"name": "Carol", "age": 35, "email": "carol@example.com", "active": True},
    ]

    summary = process_user_data(sample_users)
    print("User summary:", summary)

    config = load_config.__doc__  # just printing docstring, not calling it
    print("Config loader doc:", config)
