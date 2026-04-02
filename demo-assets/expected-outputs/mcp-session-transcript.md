# MCP Session Transcript — Offline Fallback

Use this as the fallback reference if live MCP calls are not available during the demo.
Read this aloud or display it as if Claude were responding in real time.

**Note to presenter:** When using the offline mode, narrate: *"What you're seeing is a recorded session from our demo environment. I'll show you a live version once we have network access, or we can schedule a follow-up."*

---

## Act 1 — Model Discovery

**Presenter:** *(Pastes the Act 1 prompt)*

> I need to find Hugging Face models suitable for code summarization. Show me what's available in JFrog, check their curation status, and flag any known vulnerabilities.

---

**Claude:** I'll check what Hugging Face models are available in your JFrog instance and evaluate their security status.

*Calling `jfrog_get_package_info`...*

Found 3 HuggingFace models available in your JFrog Artifactory:

| Model | Size | Package Type | Last Updated |
|-------|------|-------------|--------------|
| `facebook/bart-large-cnn` | 2.3 GB | Machine Learning | 2026-03-15 |
| `microsoft/codebert-base` | 499 MB | Machine Learning | 2026-03-10 |
| `salesforce/codet5-base` | 892 MB | Machine Learning | 2026-03-12 |

Now checking curation status for each...

*Calling `jfrog_get_package_curation_status` (facebook/bart-large-cnn)...*
*Calling `jfrog_get_package_curation_status` (microsoft/codebert-base)...*
*Calling `jfrog_get_package_curation_status` (salesforce/codet5-base)...*

**Curation Status:**

| Model | Status | Reason |
|-------|--------|--------|
| `facebook/bart-large-cnn` | ✅ **APPROVED** | Clean — passes all policies |
| `microsoft/codebert-base` | 🚫 **BLOCKED** | Security violation detected |
| `salesforce/codet5-base` | ✅ **APPROVED** | Clean — passes all policies |

`microsoft/codebert-base` is blocked — checking vulnerability details...

*Calling `jfrog_get_package_version_vulnerabilities` (microsoft/codebert-base)...*

**Vulnerability Report — `microsoft/codebert-base`:**

```
Severity:    Critical (CVSS 9.3)
Type:        Malicious Code
Category:    Pickle Deserialization
File:        pytorch_model.bin
Vector:      Deserialization → Arbitrary Code Execution
Description: A malicious pickle payload was detected in the model
             binary. Loading this model with torch.load() would
             execute the embedded payload with the privileges of
             the calling process.
Policy:      block-malicious-ai-models (auto-blocked on ingest)
Discovered:  2026-03-10T14:23:11Z
```

**Summary:**

For code summarization, I recommend either:
- **`facebook/bart-large-cnn`** (APPROVED) — 2.3 GB, strong summarization performance
- **`salesforce/codet5-base`** (APPROVED) — 892 MB, lighter footprint, optimized for code

Avoid `microsoft/codebert-base` — it is blocked due to a critical malicious code finding. JFrog's curation policy prevented it from being downloadable.

---

## Act 1 — Follow-up (Security Deep-Dive Extension)

**Presenter:** *(Pastes the follow-up prompt)*

> Tell me more about the security issues with microsoft/codebert-base. What exactly was found, what's the attack vector, and why was it blocked?

---

**Claude:** Let me pull the detailed security evidence for `microsoft/codebert-base`.

*Calling `jfrog_get_package_version_vulnerabilities` (microsoft/codebert-base, detailed)...*
*Calling `jfrog_get_package_curation_status` (microsoft/codebert-base)...*

**Detailed Security Report — `microsoft/codebert-base`:**

**What was found:**
The model's primary weights file (`pytorch_model.bin`) contains a Python pickle payload embedded within the serialized object. Pickle is Python's built-in serialization format — PyTorch uses it via `torch.load()`. The payload triggers on deserialization.

**Attack Vector:**
```
Stage 1: Developer runs: model = torch.load("pytorch_model.bin")
Stage 2: Python deserializes the object graph
Stage 3: Malicious __reduce__ method executes during deserialization
Stage 4: Arbitrary code runs with the calling process's privileges
         (potentially: data exfiltration, backdoor installation,
          lateral movement within the ML training environment)
```

**JFrog's Detection:**
JFrog's PickleScan engine inspected the serialized object graph and identified a `__reduce__` override that does not correspond to any legitimate PyTorch tensor or model component. The 96% evidence threshold was met — this is not a false positive.

**Why It Was Blocked:**
Curation policy `block-malicious-ai-models` evaluates all models on ingest:
- Condition: `maliciousCode = true`
- Action: `blockDownload: true`
- Result: Model was flagged at ingest time and never served to any developer

The model cannot be downloaded from `jfrog-ai-demo-virtual` — JFrog returns a 403 with a curation policy violation message.

**Recommendation:** Do not use this model. Use `facebook/bart-large-cnn` or `salesforce/codet5-base` instead.

---

## Act 3 — MCP Project Setup

**Presenter:** *(Pastes the Act 3 prompt)*

> Create a new JFrog project called "ml-code-review" and set up repositories for a Python ML pipeline: a local repository for storing approved models, a remote HuggingFace proxy repository, and a virtual repository that aggregates both with "ml-" prefix. Use appropriate settings for a machine learning project.

---

**Claude:** I'll create the `ml-code-review` project and set up the ML pipeline repositories.

*Calling `create_project`...*

✅ **Project created:** `ml-code-review`
- Project key: `ml-code-review`
- Display name: ML Code Review
- Admin privileges: enabled
- Storage quota: default (inherits organization limit)

Now creating the repositories...

*Calling `create_local_repository`...*

✅ **Local repository created:** `ml-models-local`
- Package type: Machine Learning
- Project: ml-code-review
- Xray indexing: enabled
- Description: Approved ML models for code review pipeline

*Calling `create_remote_repository`...*

✅ **Remote repository created:** `ml-huggingface-remote`
- Remote URL: https://huggingface.co
- Package type: Machine Learning
- Project: ml-code-review
- Caching: enabled (local store)
- Xray indexing: enabled
- Description: HuggingFace Hub proxy for ML code review pipeline

*Calling `create_virtual_repository`...*

✅ **Virtual repository created:** `ml-models-virtual`
- Includes: ml-models-local, ml-huggingface-remote
- Default deployment: ml-models-local
- Project: ml-code-review
- Description: Unified governed access for ML code review models

---

**Your ML pipeline infrastructure is ready.**

Developers should pull models from:
```
https://yourcompany.jfrog.io/artifactory/ml-models-virtual/
```

**Python usage example:**
```python
import os
from huggingface_hub import snapshot_download

# Configure HuggingFace to use JFrog as the endpoint
os.environ["HF_ENDPOINT"] = "https://yourcompany.jfrog.io/artifactory/ml-models-virtual"

# Download via the governed proxy — Xray scanning happens automatically
model_path = snapshot_download("facebook/bart-large-cnn")
```

The curation and Xray policies from the organization default will automatically apply to all models pulled through `ml-models-virtual`.

---

## End of Offline Transcript

*If you need to demonstrate Act 4 (Shadow AI), use the screenshots in `demo-assets/screenshots/` and narrate using the talking points in `docs/talking-points.md`.*
