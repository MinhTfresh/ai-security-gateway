# Contributing to the AI Security Gateway Ecosystem

Thank you for your interest in helping protect AI systems! We welcome community contributions, bug fixes, and optimization improvements. 

Because this is a security-focused project, we maintain a strict verification workflow to ensure all code integrations remain secure, stable, and unencumbered by intellectual property disputes.

---

## 1. Code of Conduct & Legal Affirmation

By submitting a Pull Request (PR) to this project, you agree that your contribution is covered under the terms of our project's **Apache License 2.0**. 

Specifically, you affirm that:
1. You authored the code yourself or have the legal right to submit it under an open-source model.
2. You grant the project repository and its users a perpetual, worldwide, non-exclusive, royalty-free, irrevocable patent and copyright license to reproduce and distribute your modifications.

---

## 2. Our Development & Contribution Workflow

To keep the pipeline organized, please follow these steps before submitting updates:

1. **Check Existing Issues:** Search our GitHub issue board to make sure no one else is already working on the same optimization or bug patch.
2. **Fork the Repository:** Create a personal copy of the repository on your GitHub account.
3. **Create a Feature Branch:** Work out of a cleanly named topic branch (e.g., `feature/optimize-regex-filters`).
4. **Write Clean, Structured Code:** Follow Python PEP 8 style standards. Ensure any security configurations fail-closed by default.

---

## 3. Mandatory Security Testing & Code Standards

Every Pull Request must pass our local security validation and regression test matrix before a maintainer can review it.

* **Run Local Pentests:** Ensure your modifications do not break the baseline security boundaries. Run the test harness before committing:
  ```bash
  python -m pytest tests/test_security_gateways.py -v
  ```
* **No Inline Secrets:** Double-check your code layers to ensure no developer tokens, test keys, or raw corporate certificates are committed to the codebase history.

---

## 4. Reporting Security Vulnerabilities (Responsible Disclosure)

**CRITICAL RULE:** If you discover a zero-day exploit, a bypass trick for our regex patterns, or a sandbox escape vector within this software, **do not open a public GitHub issue.** 

Please report all security vulnerabilities responsibly by sending a detailed technical write-up to our security team at: **security@[your-domain].com**. We will work with you to patch the vulnerability quickly and coordinate a responsible release disclosure.
