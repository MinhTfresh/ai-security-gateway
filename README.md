# Hardened AI Security Gateway & Container Sandbox Ecosystem
**Created and Maintained by: minhtfresh**  
*License: Apache 2.0*

An enterprise-grade, deterministic **AI Firewall and Secure Reverse Proxy** engineered to protect downstream LLMs, databases, and enterprise services from advanced malicious exploits, prompt injections, and data exfiltration vectors.

---

## 1. System Architecture

The gateway acts as an **Inline Inspection Layer** implementing a zero-trust model for all data transitions. Every request passes through a multi-stage security pipeline before hitting downstream resources.

[ UNTRUSTED USER / EXT DATA ]│▼┌───────────────────────────┐│ 1. Network Edge (mTLS)    │  <-- Drops unsigned connections└─────────────┬─────────────┘│▼┌───────────────────────────┐│ 2. Rate Limiting (Redis)  │  <-- Mitigates DDoS and wallet floods└─────────────┬─────────────┘│▼┌───────────────────────────┐│ 3. Entrypoint Gate        │  <-- Heuristics & Custom Llama Guard└─────────────┬─────────────┘│▼┌───────────────────────────┐│ 4. Worker Sandbox Engine  │  <-- Network-isolated Docker MicroVM└───────────────────────────┘
---

## 2. Threat Coverage Matrix: What It Defends Against

| Threat Vector | Defense Layer in Gateway | Protection Outcome |
| :--- | :--- | :--- |
| **Direct Prompt Injections** | Regex Heuristics & Llama Guard (Layer 3) | Drops explicit semantic overrides and jailbreaks at the entrypoint. |
| **Indirect Prompt Injections** | External Data Scanning (Layer 3) | Sanitizes untrusted files, web scrapes, or emails before ingestion. |
| **Agent / Shell Escapes** | Celery Docker Sandbox (`network_mode="none"`) | Traps unprivileged code tool executions in a zero-network micro-container. |
| **Data Exfiltration & Leaks** | Outbound DLP Scrubbing (Layer 5) | Redacts API keys, passwords, and PII before client-side transmission. |
| **Brute-Force & Floods** | Redis Sliding-Window Rate Limiter (Layer 2) | Throttles high-frequency request bursts to prevent budget exhaustion. |
| **Unauthenticated Net Probes** | ALB mTLS Verification (Layer 1) | Cryptographically drops requests lacking valid client certificates. |
| **Persistent Attackers** | CloudWatch -> WAF Automation | Blacklists aggressive IP addresses at the cloud border within seconds. |

---

## 3. Architectural Blind Spots: What It Does NOT Protect Against

*No single proxy can protect against structural vulnerabilities that exist upstream or downstream from its inspection path. According to the OWASP Top 10 for LLMs, this gateway does not shield against:*

* **Training/Fine-Tuning Data Poisoning:** Cannot detect or alter backdoors baked into base model weights before deployment.
* **Vector and RAG Database Corruption:** Cannot inspect semantic poison injected directly into internal corporate embeddings databases post-ingress.
* **Excessive Agent Autonomy & Over-Permissioned APIs:** Cannot judge underlying business logic or prevent valid prompts from triggering dangerous API capabilities (e.g., destructive database actions).
* **Model Theft / Weight Extraction:** Cannot distinguish between high-frequency legitimate analysis and iterative model distillation queries.

---

## 4. Directory Layout & Requirements

```text
ai-security-gateway/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── security_vulnerability.md
│   └── workflows/
│       └── security-ci.yml
├── certs/
├── gateway_logs/
├── tests/
├── alerts.py
├── backup_redis.sh
├── docker-compose.yml
├── Dockerfile
├── main.py
├── requirements.txt
├── tasks.py
├── LICENSE
├── NOTICE
└── README.md
```

### System Dependency Matrix (`requirements.txt`)
```text
fastapi==0.110.0
uvicorn[standard]==0.28.0
celery==5.3.6
redis==5.0.3
docker==7.0.0
httpx==0.27.0
pydantic==2.6.4
boto3==1.34.0
pytest==8.1.1
```

---

## 5. Quick Start Deployment

1. **Generate Certificates:** Run local PKI creation scripts inside `./certs`.
2. **Launch Infrastructure:**
   ```bash
   mkdir -p gateway_logs
   docker-compose up --build -d
   ```
3. **Verify Pipeline:** Execute the validation suite via `pytest`.

---

## 6. Responsible Disclosure & Security Issues
If you discover a zero-day exploit, bypass
