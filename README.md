# Hardened AI Security Gateway & Container Sandbox Ecosystem
**Created and Maintained by: minhtfresh**  
*License: Apache 2.0*

An enterprise-grade, deterministic **AI Firewall and Secure Reverse Proxy** engineered to protect downstream LLMs, databases, and enterprise services from advanced malicious exploits, prompt injections, and data exfiltration vectors.

---

## 1. System Architecture

The gateway acts as an **Inline Inspection Layer** implementing a zero-trust model for all data transitions. Every request passes through a multi-stage security pipeline before hitting downstream resources.



[ Hacker Request ]

       │ 
       ▼


 ──► [ Layer 1: Network mTLS ]───────► Drops connection if no signed Client Cert is present.

 ──► [ Layer 2: Redis Rate Limiter ] ─► Throttles token-exhaustion and brute-force floods.

 ──► [ Layer 3: Input Filter RegEx ] ─► Identifies prompt injections

 ──► [ TRIGGERS ALERTS ]

 ──► [ Layer 4: Docker Sandbox ] ────► Runs execution blocks in unprivileged boxes with NO internet.
 
──► [ Layer 5: Output Scrubbing ] ──► Cleans leaked system instructions before transmission.
