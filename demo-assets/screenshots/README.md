# Screenshots

This directory stores annotated screenshots showing expected UI state at each demo step.

---

## Required Screenshots

Capture these during a successful demo run or on a configured demo tenant.
Each screenshot should be annotated with arrows and callouts highlighting the key elements.

| Filename | When to Capture | Key Elements to Annotate |
|----------|----------------|--------------------------|
| `act1-discovery-results.png` | After Act 1 MCP prompt | Tool call names, model list, BLOCKED status badge |
| `act2-blocked-model.png` | Act 2, AI Catalog blocked model view | Red security indicator, BLOCKED badge, model name |
| `act2-scan-evidence.png` | Act 2, Xray scan evidence tab | File name, payload type, severity, CVE details |
| `act2-curation-policy.png` | Act 2, Curation policy detail | Policy name, conditions, action (blockDownload) |
| `act2-approved-model.png` | Act 2, Clean model in AI Catalog | APPROVED badge, license, governance trail |
| `act3-mcp-tool-calls.png` | During Act 3 MCP prompt | 4 tool calls visible: create_project, 3x create_repository |
| `act3-project-created.png` | After Act 3, Artifactory UI | ml-code-review project visible in project list |
| `act3-repositories.png` | After Act 3, Artifactory repo browser | 3 repositories: local, remote, virtual |
| `act4-shadow-ai.png` | Act 4, AI Catalog Shadow AI panel | 3 unmanaged providers, "Route to Gateway" button |

---

## Screenshot Guidelines

- Resolution: minimum 1920×1080
- Format: PNG (preferred) or JPEG
- Annotations: use red arrows and callout boxes
- Tool: Skitch, Monosnap, or similar

---

## Fallback Instructions

If you cannot capture screenshots from a live environment:
1. Use the offline transcript in `../expected-outputs/mcp-session-transcript.md` for the MCP portions
2. Reference JFrog official documentation screenshots where available
3. Create mockup screenshots using the AI Catalog UI documentation as reference

See [`docs/troubleshooting.md`](../../docs/troubleshooting.md) for offline fallback procedures.
