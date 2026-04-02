# Code Review Assistant — Runnable Demo App

A real Python application that demonstrates JFrog project-based AI governance:
calls the JFrog AI Gateway with a project-scoped token to review code.

---

## What It Does

1. **Governance check** — verifies the model is allowed in your JFrog project
2. **Inference** — calls the JFrog AI Gateway (not the provider directly)
3. **Governance trail** — shows token type, gateway URL, latency, and token usage

```
  ═════════════════════════════════════════════════════════════════
    JFrog AI Catalog — Code Review Assistant
    Project-governed AI inference via JFrog AI Gateway
  ═════════════════════════════════════════════════════════════════

  ── Governance Check

  → Project:    ml-code-review
  → Model:      openai/gpt-4o-mini
  → Gateway:    https://yourcompany.ml.jfrog.io/v1

  ✓ Project exists: ml-code-review
  ✓ Model allowed in project Registry: openai/gpt-4o-mini
  ✓ Using JFrog AI Gateway (not provider directly)
  ✓ Token type: JFrog project-scoped (not raw provider key)

  ── Running Inference

  → Reviewing: sample_code.py (72 lines)
  → Model:     openai/gpt-4o-mini
  Calling JFrog AI Gateway... done (1.4s)

  ── Code Review Result

  **Summary**
  This module implements user authentication, configuration loading,
  data processing, and file I/O utilities. It contains several
  security vulnerabilities that should be addressed before production.

  **Strengths**
  - `process_user_data` is well-structured with clear docstring
  - Graceful handling of empty input in `process_user_data`
  ...

  ── Governance Trail

  ✓ Model:           openai/gpt-4o-mini
  ✓ Project:         ml-code-review (enforced)
  ✓ Token type:      JFrog project-scoped (not raw provider key)
  ✓ Gateway:         https://yourcompany.ml.jfrog.io/v1
  ✓ Prompt tokens:   312
  ✓ Completion:      287 tokens
  ✓ Latency:         1.4s (gateway overhead ~10–30ms)
```

---

## Prerequisites

- Python 3.10+
- A JFrog SaaS instance with AI Catalog enabled
- At least one model allowed in your project's Registry
- The setup from the main repo completed (`./scripts/setup.sh`)

---

## Setup

### 1. Install dependencies

```bash
cd app
pip install -r requirements.txt
```

### 2. Get your project-scoped token

This is the key step that makes the demo work. In the JFrog UI:

1. Navigate to **AI/ML → Registry**
2. Filter by your project: `ml-code-review`
3. Click on a model (e.g. `openai/gpt-4o-mini`)
4. Click **"Use Model"**
5. Authenticate with your JFrog credentials
6. Copy the **token** and the **base_url** (AI Gateway URL)

### 3. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in:
- `JFROG_URL` — your JFrog platform URL
- `JFROG_PROJECT_TOKEN` — from the "Use Model" step above
- `JFROG_AI_GATEWAY_URL` — the base_url from "Use Model" (e.g. `https://yourcompany.ml.jfrog.io/v1`)
- `JFROG_ACCESS_TOKEN` — optional, enables project/model existence checks

### 4. Run

```bash
# Review the included sample file
python code_review.py

# Review your own file
python code_review.py path/to/your/code.py

# Use a specific model
python code_review.py sample_code.py --model openai/gpt-4o
```

---

## The Governance Story

This app demonstrates the JFrog AI Catalog governance model in action:

| What you see | What it proves |
|-------------|----------------|
| `api_key=JFROG_PROJECT_TOKEN` | Developer never holds the raw provider API key |
| `base_url=JFROG_AI_GATEWAY_URL` | All calls route through the JFrog AI Gateway |
| Governance check: project + model status | Model is authorized at the project level, not globally |
| Token type shown in output | JFrog token → project-scoped, revocable, auditable |

**If you try to call OpenAI directly with the project token, it will fail** — the token only works with the JFrog AI Gateway. That's the governance in action.

---

## Troubleshooting

### "AI Gateway call failed: 401 Unauthorized"
- `JFROG_PROJECT_TOKEN` is wrong or expired
- Get a new one: AI/ML → Registry → your model → "Use Model"

### "AI Gateway call failed: 404 Not Found"
- `JFROG_AI_GATEWAY_URL` is incorrect
- Check the `base_url` in the "Use Model" snippet

### "Model not found in Registry"
- The model hasn't been allowed in your project yet
- Go to AI/ML → Discovery → find the model → Allow → select `ml-code-review`

### "Project check: Project not found"
- `JFROG_PROJECT_KEY` doesn't match a real project
- Run `./scripts/setup.sh` to create the `ml-code-review` project

### Governance checks skipped
- Set `JFROG_ACCESS_TOKEN` to enable project/Registry API checks
- Inference still works without it (only `JFROG_PROJECT_TOKEN` is required)

---

## Files

| File | Purpose |
|------|---------|
| `code_review.py` | Main application |
| `sample_code.py` | Sample Python code to review (intentionally has issues) |
| `requirements.txt` | Python dependencies |
| `.env.example` | Environment variable template |
| `README.md` | This file |
