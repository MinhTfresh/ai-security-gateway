# Hardened AI Security Gateway & Container Sandbox Ecosystem
**Created and Maintained by: minhtfresh**  
*License: Apache 2.0*

An enterprise-grade, deterministic **AI Firewall and Secure Reverse Proxy** engineered to protect downstream LLMs, databases, and enterprise services from advanced malicious exploits, prompt injections, and data exfiltration vectors.

---

Python AI Defense Block is a self-healing autonomous security ecosystem:


Continuous Deployment (GitHub CI/CD): Validates code updates automatically via regression penetration tests on every push.

Threat Coverage


1. What Assets Are Being Protected?
Your Core Large Language Models (LLMs): Shields your proprietary or commercial model endpoints from being hijacked, forced into unauthorized persona overrides, or tricked into revealing system prompts.


Backend Databases & Corporate APIs: Protects sensitive internal SQL/NoSQL databases, user account records, and financial transaction endpoints from being queried or wiped by compromised AI tool calls.


Cloud Infrastructure & Host Nodes: Defends your underlying cloud cluster (e.g., AWS EC2/ECS nodes) from being compromised via container escape vulnerabilities.


API Budgets & Compute Resources: Safeguards your financial balance from "denial-of-wallet" attacks where automated botnets flood your model with millions of expensive tokens.


2. What Specific Threats Does It Block?
Threat Vector

Defense Mechanism in Your Gateway

Protection Outcome

Direct Prompt Injections

Regex Heuristics & Custom Llama Guard Taxonomy (Layer 3)

Instantly drops user prompts attempting commands like "ignore previous instructions" or jailbreak role-plays before they reach the LLM.
Indirect Prompt Injections

Isolated External Data Scanning (Layer 3)

Intercepts untrusted files, web scrapes, or emails and strips out hidden malicious instructions before they poison the agent's context window.

Agent / Shell Escapes

Celery Docker MicroVM Sandbox (network_mode="none")
If an AI agent attempts to run malicious code or unauthorized system tools (os.system), it is trapped in an unprivileged container with zero network access.

Data Exfiltration & Leaks

Outbound DLP Scrubbing (Layer 5)

Programmatically scans model outputs and redacts exposed API keys (sk-), passwords, or PII (like Social Security Numbers) before transmission.
Brute-Force & DDoS Floods

Redis Sliding-Window Rate Limiter (Layer 2)

Throttles and drops high-frequency request floods from single users or automated script-kiddie tools.

Unauthenticated Net Probes

Application Load Balancer mTLS Verification (Layer 1)

Cryptographically rejects any network connection that does not present a valid, signed corporate client certificate at the socket layer.

Persistent Attacker IPs

CloudWatch -> AWS Lambda -> AWS WAF Automation

Automatically blacklists an attacker's IP address at the cloud border within seconds if they trigger multiple injection alarms.


Mutual TLS Layer (mTLS): Validates trusted client identities via mandatory cryptographic handshakes at the edge.


Structured API Block (FastAPI Gate): Intercepts script injections, processes queries asynchronously via background Redis/Celery tasks, and redacts outgoing data leaks.


Isolated Docker Sandbox (EC2 Worker): Safely isolates and terminates unprivileged code executions with zero network access.


Real-time Incident Alerting (Slack/SNS): Instantly notifies your engineering team of active exploit vectors.


Active Perimeter Defense (AWS WAF Blocklist): Dynamically extracts the attacker's IP address and completely blacklists them at the cloud border.

