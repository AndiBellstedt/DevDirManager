# Security Policy

This document describes how to report security vulnerabilities for **DevDirManager** and what to expect from the maintainers.

DevDirManager is a PowerShell module that inventories, exports/imports, restores, synchronizes, and publishes Git repository metadata across machines (including optional GitHub Gist integration).

---

## Supported Versions

Security fixes are provided for:

- The **latest released version** published to the PowerShell Gallery and/or GitHub Releases.
- The **current release line** (if multiple supported release lines exist).

> Notes:
> - Pre-release builds and arbitrary commits on branches are not considered supported for security updates.
> - If you are unsure whether your version is supported, include your module version and installation method in the report.

---

## Reporting a Vulnerability

### Preferred: GitHub Private Vulnerability Reporting
Please report security issues **privately** using GitHub Security Advisories / Private Vulnerability Reporting for this repository:

- https://github.com/AndiBellstedt/DevDirManager/security

**Do not** open a public GitHub issue for suspected vulnerabilities.

### What to Include
To help triage quickly, include:

- A clear description of the issue and potential impact
- Steps to reproduce (proof-of-concept if possible)
- Affected versions (e.g., `1.5.0`)
- Your environment:
  - PowerShell version (Windows PowerShell 5.1 / PowerShell 7+)
  - OS
  - Git version (if relevant)
- Any relevant logs **with secrets removed**
- Suggested remediation (optional)

### Sensitive Data Handling
Do **not** include any of the following in reports or logs:

- GitHub Personal Access Tokens (PATs), OAuth tokens, API keys
- Credentials
- Private repository URLs that reveal internal infrastructure
- Any personal data you are not authorized to share

---

## Response & Disclosure Process

We follow coordinated vulnerability disclosure principles.

### Targets (Best-Effort)
- **Acknowledgement**: within **14 days**
- **Initial triage** (confirming scope/severity and whether we can reproduce): within **30 days**
- **Status updates**: when progress is made (or at least every **30–60 days** for active reports)
- **Fix & release**: depends on severity and complexity (critical issues are prioritized; lower-severity issues may take longer)

### Severity
Severity is determined by maintainers considering:
- Exploitability
- Impact (confidentiality, integrity, availability)
- Scope (local vs. remote, authenticated vs. unauthenticated)
- Availability of mitigations/workarounds

### Public Disclosure
- Please allow time for a fix to be developed and released before disclosing publicly.
- If a CVE is appropriate, we may request one or coordinate issuance through GitHub.

---

## Security Scope

### In Scope
- The **DevDirManager** PowerShell module code in this repository
- Module installation script(s) shipped with the repo (e.g., `install.ps1`)
- CI/CD definitions and build scripts included in this repository (e.g., Azure Pipelines configuration)
- Localization resources and type/format definition files shipped with the module

### Out of Scope (Examples)
- Vulnerabilities in **Git** itself
- Vulnerabilities in **PowerShell** / the runtime
- Issues in third-party services (e.g., GitHub, GitHub Gist) unless caused by DevDirManager’s implementation
- Social engineering, phishing, or physical attacks

If a report is out of scope but relevant, we may still suggest mitigations or upstream reporting paths.

---

## Project-Specific Security Considerations

DevDirManager performs file operations, process execution (Git), and optional remote publication (GitHub Gist). The following are security-sensitive areas:

### Tokens & Secrets (GitHub Gist)
- Treat GitHub tokens as secrets at all times.
- Prefer secure secret storage solutions (for example Windows Credential Manager, SecretManagement vaults, or other OS-native secret stores).
- Avoid placing tokens in scripts, console history, CI logs, or configuration files.

### Logging
- DevDirManager uses PSFramework logging.
- Security reports should assume logs might be collected for diagnostics—**secrets must never be logged**.
- If you believe the module logs sensitive data, report it as a vulnerability.

### Path Handling / Traversal
- Repository list entries and destination paths can be attacker-controlled in some workflows (shared lists, network shares).
- The module includes protections against unsafe relative paths; please report any bypass.

### Scheduled Tasks / Automation
- Auto-sync workflows may involve Windows Task Scheduler.
- Report any scenario where task registration or execution could be abused for privilege escalation or unintended command execution.

---

## Safe Harbor for Good-Faith Research

We support good-faith security research and coordinated disclosure.

When conducting research:
- Do not degrade service availability (DoS), destroy data, or exfiltrate data
- Only test against systems and data you own or are explicitly authorized to test
- Use the private reporting channel above and avoid public disclosure until coordinated

---

## Security Updates

When a security issue is confirmed:
- A fix will be released as a new module version.
- Release notes will describe the issue and mitigation guidance, avoiding exploit details when appropriate.

---

## Acknowledgements

We appreciate responsible disclosure. With your permission, we may acknowledge your contribution in release notes or advisories.

Thank you for helping keep DevDirManager secure.