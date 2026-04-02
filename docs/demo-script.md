# Detailed Demo Script

Presenter reference with exact prompts, expected outputs, and talking points for each step.

---

## Setup (Before Audience Arrives)

1. Run `./scripts/validate.sh` — confirm all green
2. Open Claude Desktop — confirm JFrog tools visible
3. Open JFrog AI Catalog in browser — log in, navigate to Packages
4. Open `scripts/demo-prompts.txt` in a side window for copy-paste
5. Run `./scripts/reset.sh` if this is not the first run of the day

---

## Introduction (1 minute)

**Spoken:**

> "AI models are the new open-source packages. They carry the same supply chain risks — malicious payloads, license violations, vulnerable dependencies — and most organizations have zero governance over them. A data scientist pulls a model directly from Hugging Face. A developer hardcodes an OpenAI API key. An agent downloads an MCP server from a random GitHub repo. JFrog AI Catalog changes that."

> "Today I'm going to show you a 12-minute demo of how JFrog governs the AI supply chain — from the model you pull from Hugging Face, to the MCP server your agent calls, to the shadow AI your infrastructure is already consuming. We'll do it using the JFrog MCP Server, which lets an AI assistant like Claude query and control JFrog entirely through natural language."

**Transition:** *"Let's start with discovery."*

---

## Act 1 — Model Discovery via MCP

### Step 1.1 — Send discovery prompt

**Switch to:** Claude Desktop

**Paste** (from `demo-prompts.txt`, Act 1 — Discovery):
```
I need to find Hugging Face models suitable for code summarization.
Show me what's available in JFrog, check their curation status, 
and flag any known vulnerabilities.
```

**While Claude is running:**

> *"Claude is now making real API calls to JFrog through the MCP Server. You'll see the tool calls appear in real-time."*

### Expected Claude output (summary):

```
I'll check what Hugging Face models are available in your JFrog 
instance and evaluate their security status.

[Tool: jfrog_get_package_info]
Found 3 HuggingFace models available:
- facebook/bart-large-cnn (2.3 GB)  
- microsoft/codebert-base (499 MB)
- salesforce/codet5-base (892 MB)

[Tool: jfrog_get_package_curation_status]
Curation status:
- facebook/bart-large-cnn: ✅ APPROVED
- microsoft/codebert-base: 🚫 BLOCKED (security violation)  
- salesforce/codet5-base: ✅ APPROVED

[Tool: jfrog_get_package_version_vulnerabilities]
microsoft/codebert-base: 1 critical vulnerability
- CVE details: Malicious pickle payload detected
- CVSS: 9.3 (Critical)
- Vector: Deserialization → Remote Code Execution
```

**Spoken:**

> *"Three models found. Two approved, one blocked. Notice: the AI didn't just list available models — it automatically checked their governance status and surfaced the security issue. That's the power of having JFrog as a tool in your AI assistant."*

> *"Let's look at that blocked model in more detail."*

---

## Act 2 — Security Deep-Dive

### Step 2.1 — Navigate to AI Catalog

**Switch to:** Browser (JFrog AI Catalog tab)

**Navigate to:** AI Catalog → Packages → filter: HuggingFace

**Point out:**
- The model list showing microsoft/codebert-base with a red security indicator
- The BLOCKED status badge

**Spoken:**

> *"This is the AI Catalog — JFrog's system of record for all AI assets. You can see the blocked model right here."*

### Step 2.2 — Open the blocked model

**Click:** `microsoft/codebert-base` (blocked model)

**Navigate to:** Security tab / Scan Evidence

**Point out:**
- File scan result: `.pkl` file detected
- Payload: Code execution via pickle deserialization
- Severity: Critical
- Discovered: [date]

**Spoken:**

> *"JFrog's security engine found a pickle payload inside this model. Pickle is Python's serialization format — and it can execute arbitrary code when loaded. This is exactly the attack vector JFrog's researchers discovered in real Hugging Face models in 2025, with a CVSS of 9.3."*

### Step 2.3 — Show the curation policy

**Navigate to:** Curation Policy (link from the model evidence, or navigate to AI Catalog → Policies)

**Point out:**
- Policy name: `block-malicious-ai-models`
- Condition: Critical security severity OR known malicious payload
- Action: Block

**Spoken:**

> *"This curation policy is what prevented this model from ever reaching a developer's machine. The policy evaluated it automatically when it was first fetched — and blocked it before it could be cached or used."*

### Step 2.4 — Switch to the approved model

**Navigate back to:** AI Catalog → Packages → `facebook/bart-large-cnn`

**Point out:**
- Clean scan evidence: no vulnerabilities
- License: Apache 2.0 (approved)
- Governance trail: when pulled, scanned, approved
- Curation status: Approved

**Spoken:**

> *"The clean model has a complete evidence trail. When it was pulled, what was scanned, what policy applied, who approved it. This is auditable lineage for every AI asset — exactly what security and compliance teams need."*

---

## Act 3 — MCP Project Setup

### Step 3.1 — Send project creation prompt

**Switch to:** Claude Desktop

**Paste** (from `demo-prompts.txt`, Act 3 — Project Setup):
```
Create a new JFrog project called "ml-code-review" and set up 
repositories for a Python ML pipeline:
- a local repository for storing approved models
- a remote HuggingFace proxy repository 
- a virtual repository that aggregates both with "ml-" prefix

Use appropriate settings for a machine learning project.
```

**While Claude is running:**

> *"Claude is now calling JFrog's admin APIs through MCP. Watch the tool calls — you'll see it creating real infrastructure."*

### Expected Claude output:

```
I'll create the ml-code-review project and set up the ML pipeline 
repositories.

[Tool: create_project]
✅ Project "ml-code-review" created
   - Key: ml-code-review
   - Admin privileges: enabled

[Tool: create_local_repository]  
✅ Local repository "ml-models-local" created
   - Package type: Machine Learning
   - Project: ml-code-review
   - Description: Approved ML models for code review pipeline

[Tool: create_remote_repository]
✅ Remote repository "ml-huggingface-remote" created  
   - URL: https://huggingface.co
   - Package type: Machine Learning
   - Caching: enabled
   - Project: ml-code-review

[Tool: create_virtual_repository]
✅ Virtual repository "ml-models-virtual" created
   - Includes: ml-models-local, ml-huggingface-remote
   - Default deployment: ml-models-local
   - Project: ml-code-review

Your ML pipeline infrastructure is ready. Developers should pull 
models from: https://yourcompany.jfrog.io/ml-models-virtual
```

**Spoken:**

> *"Four tool calls. One conversation turn. A complete ML pipeline infrastructure — fully governed, project-scoped, with the right package types and caching settings."*

> *"What just happened would normally take 6 manual steps across 3 UI screens. And everything is still governed — repos created with the right policies inherited from the project."*

> *"This is the vision: AI tooling governing AI infrastructure. The JFrog MCP Server is itself an AI-native interface to a platform designed for AI governance."*

---

## Act 4 — Shadow AI

### Step 4.1 — Navigate to Shadow AI

**Switch to:** Browser (JFrog AI Catalog tab)

**Navigate to:** AI Catalog → Shadow AI (or AI Gateway → Shadow AI panel)

**Point out:**
- "3 unmanaged AI providers detected" (or your seeded count)
- Service account: direct OpenAI API calls (production service)
- CI/CD job: Anthropic API calls (build-time code generation)
- Developer workstation: Gemini API calls

**Spoken:**

> *"Before AI Catalog, these were invisible. A service account in production is making direct OpenAI API calls. A CI job is calling Anthropic. A developer is using Gemini. All outside any governance, policy, or visibility."*

> *"This is the same sprawl JFrog solved for open-source packages a decade ago. Every team was pulling dependencies from different sources, with no inventory and no control. Artifactory became the single governed source. AI Catalog does the same for AI."*

### Step 4.2 — Show governance action

**Point out:** "Route through AI Gateway" action on one of the shadow AI entries

**Spoken:**

> *"One click routes this to the AI Gateway — now it's governed, metered, and policy-enforced. Same experience developers already have with Artifactory."*

---

## Closing (1 minute)

**Spoken:**

> *"Let's recap what we just saw:"*
>
> *"Act 1: An AI assistant queried JFrog for Hugging Face models — live — checking curation status and vulnerabilities in one conversation."*
>
> *"Act 2: We saw a model with a real pickle payload, blocked automatically by Xray and a curation policy. And the clean model with complete governance lineage."*
>
> *"Act 3: Natural language created a complete ML pipeline infrastructure in one conversation — project, local repo, HuggingFace proxy, virtual repo."*
>
> *"Act 4: Shadow AI surfaced three unmanaged AI providers your team is already using, ready to be governed."*
>
> *"JFrog AI Catalog extends the same supply chain trust model that protects your software today — to AI. One platform. One policy. Total visibility."*

---

## Q&A Prep

See [`docs/faq.md`](faq.md) for anticipated questions and answers.

Key questions to expect:
- "How does this differ from just using Hugging Face directly?"
- "What happens if our models are private / internal?"
- "Does the MCP Server need to be self-hosted?"
- "How does Shadow AI detection work technically?"
- "What's the licensing model for AI Catalog?"
