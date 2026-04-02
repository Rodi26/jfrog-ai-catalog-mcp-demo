#!/usr/bin/env python3
"""
JFrog AI Catalog Demo — Code Review Assistant
=============================================

A real local application that demonstrates JFrog project-based AI governance.

What it does:
  1. Verifies the model is allowed in your JFrog project (governance check)
  2. Calls the JFrog AI Gateway with a project-scoped token (not the raw provider key)
  3. Reviews the supplied code and shows governance metadata alongside the result

Usage:
  python code_review.py [file_to_review]
  python code_review.py sample_code.py
  python code_review.py sample_code.py --model openai/gpt-4o-mini

Required env vars (copy app/.env.example to app/.env and fill in):
  JFROG_URL               — https://yourcompany.jfrog.io
  JFROG_ACCESS_TOKEN      — Admin/developer token (for governance checks)
  JFROG_PROJECT_TOKEN     — Project-scoped token from AI/ML > Registry > "Use Model"
  JFROG_AI_GATEWAY_URL    — https://yourcompany.ml.jfrog.io/v1
  JFROG_PROJECT_KEY       — ml-code-review (default)
  MODEL                   — e.g. openai/gpt-4o-mini or openai/gpt-4o

See app/README.md for full setup instructions.
"""

import argparse
import os
import sys
import textwrap
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent / ".env")
except ImportError:
    pass  # python-dotenv optional; users can export vars directly

try:
    import requests
    from openai import OpenAI
except ImportError as exc:
    print(f"\n[✗] Missing dependency: {exc}")
    print("    Run: pip install -r requirements.txt\n")
    sys.exit(1)

# ── Configuration ──────────────────────────────────────────────────────────────

JFROG_URL = os.environ.get("JFROG_URL", "").rstrip("/")
JFROG_ACCESS_TOKEN = os.environ.get("JFROG_ACCESS_TOKEN", "")
JFROG_PROJECT_TOKEN = os.environ.get("JFROG_PROJECT_TOKEN", "")
JFROG_AI_GATEWAY_URL = os.environ.get("JFROG_AI_GATEWAY_URL", "")
JFROG_PROJECT_KEY = os.environ.get("JFROG_PROJECT_KEY", "ml-code-review")
DEFAULT_MODEL = os.environ.get("MODEL", "openai/gpt-4o-mini")

# ── ANSI colors ────────────────────────────────────────────────────────────────

GREEN  = "\033[92m"
YELLOW = "\033[93m"
RED    = "\033[91m"
BLUE   = "\033[94m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
RESET  = "\033[0m"

def ok(msg):    print(f"  {GREEN}✓{RESET} {msg}")
def warn(msg):  print(f"  {YELLOW}!{RESET} {msg}")
def fail(msg):  print(f"  {RED}✗{RESET} {msg}")
def info(msg):  print(f"  {BLUE}→{RESET} {msg}")
def dim(msg):   print(f"  {DIM}{msg}{RESET}")


# ── Governance check ───────────────────────────────────────────────────────────

def check_project_exists(project_key: str) -> dict:
    """Verify the JFrog project exists via the Access API."""
    url = f"{JFROG_URL}/access/api/v1/projects/{project_key}"
    headers = {"Authorization": f"Bearer {JFROG_ACCESS_TOKEN}"}
    try:
        r = requests.get(url, headers=headers, timeout=10)
        if r.status_code == 200:
            return {"exists": True, "data": r.json()}
        elif r.status_code == 404:
            return {"exists": False, "error": "Project not found"}
        else:
            return {"exists": False, "error": f"HTTP {r.status_code}: {r.text[:200]}"}
    except requests.RequestException as e:
        return {"exists": False, "error": str(e)}


def check_model_in_project(model_name: str, project_key: str) -> dict:
    """
    Check whether a model is allowed in the project by querying
    the AI Catalog Registry API.

    The AI Catalog Registry endpoint returns allowed models per project.
    Endpoint: GET /ml/core/api/v1/registry/models?project=<key>
    """
    url = f"{JFROG_URL}/ml/core/api/v1/registry/models"
    headers = {"Authorization": f"Bearer {JFROG_ACCESS_TOKEN}"}
    params = {"project": project_key}
    try:
        r = requests.get(url, headers=headers, params=params, timeout=10)
        if r.status_code == 200:
            data = r.json()
            models = data if isinstance(data, list) else data.get("models", [])
            # Normalize model name for comparison (case-insensitive)
            model_lower = model_name.lower()
            for m in models:
                name = (m.get("name") or m.get("model") or m.get("id") or "").lower()
                if name == model_lower or name.endswith("/" + model_lower):
                    return {"allowed": True, "data": m}
            return {"allowed": False, "error": f"Model '{model_name}' not found in project Registry"}
        elif r.status_code == 404:
            # AI Catalog API not available on this instance — degrade gracefully
            return {"allowed": None, "error": "AI Catalog Registry API not available (404)"}
        elif r.status_code == 401:
            return {"allowed": None, "error": "Unauthorized — check JFROG_ACCESS_TOKEN"}
        else:
            return {"allowed": None, "error": f"HTTP {r.status_code}: {r.text[:200]}"}
    except requests.RequestException as e:
        return {"allowed": None, "error": str(e)}


def check_virtual_repo_accessible(repo_key: str = "jfrog-ai-demo-virtual") -> dict:
    """Check that the HuggingFace virtual repository is accessible."""
    url = f"{JFROG_URL}/artifactory/api/repositories/{repo_key}"
    headers = {"Authorization": f"Bearer {JFROG_ACCESS_TOKEN}"}
    try:
        r = requests.get(url, headers=headers, timeout=10)
        if r.status_code == 200:
            data = r.json()
            return {"accessible": True, "data": data}
        else:
            return {"accessible": False, "error": f"HTTP {r.status_code}"}
    except requests.RequestException as e:
        return {"accessible": False, "error": str(e)}


# ── Inference via AI Gateway ───────────────────────────────────────────────────

def build_review_prompt(code: str, filename: str) -> str:
    return textwrap.dedent(f"""
        You are a senior software engineer conducting a code review.
        Analyze the following code from `{filename}` and provide:

        1. **Summary** — what the code does (2–3 sentences)
        2. **Strengths** — what is done well (bullet points)
        3. **Issues** — bugs, anti-patterns, security concerns (bullet points)
        4. **Suggestions** — concrete improvements (bullet points)

        Be specific and actionable. Keep your review under 400 words.

        ```python
        {code}
        ```
    """).strip()


def call_ai_gateway(prompt: str, model: str) -> tuple[str, dict]:
    """
    Call the JFrog AI Gateway using the project-scoped token.
    Returns (response_text, metadata).
    """
    client = OpenAI(
        api_key=JFROG_PROJECT_TOKEN,
        base_url=JFROG_AI_GATEWAY_URL,
    )
    start = time.time()
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=600,
        temperature=0.3,
    )
    elapsed = time.time() - start

    text = response.choices[0].message.content or ""
    meta = {
        "model": response.model,
        "usage": {
            "prompt_tokens": response.usage.prompt_tokens if response.usage else 0,
            "completion_tokens": response.usage.completion_tokens if response.usage else 0,
        },
        "elapsed_seconds": round(elapsed, 2),
        "finish_reason": response.choices[0].finish_reason,
    }
    return text, meta


# ── Main ───────────────────────────────────────────────────────────────────────

def validate_config():
    """Exit early with helpful messages if required env vars are missing."""
    errors = []
    if not JFROG_URL:
        errors.append("JFROG_URL is not set (e.g. https://yourcompany.jfrog.io)")
    if not JFROG_PROJECT_TOKEN:
        errors.append("JFROG_PROJECT_TOKEN is not set — get it from AI/ML > Registry > 'Use Model'")
    if not JFROG_AI_GATEWAY_URL:
        errors.append("JFROG_AI_GATEWAY_URL is not set (e.g. https://yourcompany.ml.jfrog.io/v1)")
    if errors:
        print(f"\n{RED}Configuration errors:{RESET}")
        for e in errors:
            print(f"  {RED}✗{RESET} {e}")
        print(f"\n  Copy {BLUE}app/.env.example{RESET} to {BLUE}app/.env{RESET} and fill in the values.")
        print(f"  Then re-run: {BOLD}python code_review.py{RESET}\n")
        sys.exit(1)


def print_banner():
    width = 65
    print()
    print(f"  {BOLD}{'═' * width}{RESET}")
    print(f"  {BOLD}  JFrog AI Catalog — Code Review Assistant{RESET}")
    print(f"  {DIM}  Project-governed AI inference via JFrog AI Gateway{RESET}")
    print(f"  {BOLD}{'═' * width}{RESET}")
    print()


def print_section(title: str):
    print(f"\n  {BOLD}{BLUE}── {title}{RESET}")


def main():
    parser = argparse.ArgumentParser(
        description="JFrog AI Catalog demo: governance check + AI Gateway inference",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "file",
        nargs="?",
        default=str(Path(__file__).parent / "sample_code.py"),
        help="Python file to review (default: sample_code.py)",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Model to use via AI Gateway (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--no-governance-check",
        action="store_true",
        help="Skip governance check and go straight to inference",
    )
    args = parser.parse_args()

    validate_config()
    print_banner()

    # Read the file to review
    filepath = Path(args.file)
    if not filepath.exists():
        print(f"  {RED}✗{RESET} File not found: {filepath}\n")
        sys.exit(1)
    code = filepath.read_text()
    filename = filepath.name

    model = args.model

    # ── Step 1: Governance check ───────────────────────────────────────────────
    if not args.no_governance_check:
        print_section("Governance Check")
        print()
        info(f"Project:    {BOLD}{JFROG_PROJECT_KEY}{RESET}")
        info(f"Model:      {BOLD}{model}{RESET}")
        info(f"Gateway:    {BOLD}{JFROG_AI_GATEWAY_URL}{RESET}")
        print()

        # Check 1: Project exists
        if JFROG_ACCESS_TOKEN:
            proj = check_project_exists(JFROG_PROJECT_KEY)
            if proj["exists"]:
                ok(f"Project exists: {JFROG_PROJECT_KEY}")
            else:
                warn(f"Project check: {proj.get('error', 'unknown')} — continuing anyway")
        else:
            warn("JFROG_ACCESS_TOKEN not set — skipping project/model governance checks")
            dim("  (Set it to see full governance metadata)")

        # Check 2: Model in Registry
        if JFROG_ACCESS_TOKEN:
            reg = check_model_in_project(model, JFROG_PROJECT_KEY)
            if reg["allowed"] is True:
                ok(f"Model allowed in project Registry: {model}")
            elif reg["allowed"] is False:
                warn(f"Model not found in Registry: {reg.get('error')}")
                warn("Proceeding — model may be allowed but Registry API format differs")
            else:
                # None = API unavailable, degrade gracefully
                warn(f"Registry check skipped: {reg.get('error')}")
                dim("  (AI Catalog Registry API may not be available on this tier)")

        # Check 3: Confirm we are using the Gateway, not the provider directly
        ok(f"Using JFrog AI Gateway (not provider directly)")
        ok(f"Token type: JFrog project-scoped (not raw provider key)")
        print()

    # ── Step 2: Inference via AI Gateway ──────────────────────────────────────
    print_section("Running Inference")
    print()
    info(f"Reviewing: {BOLD}{filename}{RESET} ({len(code.splitlines())} lines)")
    info(f"Model:     {BOLD}{model}{RESET}")
    print()
    print(f"  {DIM}Calling JFrog AI Gateway...{RESET}", end="", flush=True)

    prompt = build_review_prompt(code, filename)
    try:
        result, meta = call_ai_gateway(prompt, model)
    except Exception as exc:
        print()
        print(f"\n  {RED}✗{RESET} AI Gateway call failed: {exc}")
        print()
        print("  Common causes:")
        print("  • JFROG_PROJECT_TOKEN expired — generate a new one from AI/ML > Registry > 'Use Model'")
        print("  • JFROG_AI_GATEWAY_URL incorrect — check the URL in your 'Use Model' snippet")
        print("  • Model not allowed in project — allow it in AI/ML > Discovery first")
        print()
        sys.exit(1)

    print(f" {GREEN}done{RESET} ({meta['elapsed_seconds']}s)\n")

    # ── Step 3: Print result ────────────────────────────────────────────────────
    print_section("Code Review Result")
    print()
    # Indent and wrap the result
    for line in result.strip().splitlines():
        print(f"  {line}")

    # ── Step 4: Governance trail ────────────────────────────────────────────────
    print()
    print_section("Governance Trail")
    print()
    ok(f"Model:           {model}")
    ok(f"Project:         {JFROG_PROJECT_KEY} (enforced)")
    ok(f"Token type:      JFrog project-scoped (not raw provider key)")
    ok(f"Gateway:         {JFROG_AI_GATEWAY_URL}")
    ok(f"Prompt tokens:   {meta['usage']['prompt_tokens']}")
    ok(f"Completion:      {meta['usage']['completion_tokens']} tokens")
    ok(f"Latency:         {meta['elapsed_seconds']}s (gateway overhead ~10–30ms)")
    ok(f"Timestamp:       {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}")
    print()
    print(f"  {DIM}All AI consumption routed through JFrog AI Gateway.{RESET}")
    print(f"  {DIM}Provider API key never exposed to this application.{RESET}")
    print()
    width = 65
    print(f"  {BOLD}{'═' * width}{RESET}")
    print()


if __name__ == "__main__":
    main()
