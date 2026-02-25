# 🦞 Phoenix Secure Kubernetes Deployment

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-24.0+-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3-000000?logo=apple&logoColor=white)](https://www.apple.com/mac/)
[![Security](https://img.shields.io/badge/Security-Zero%20Trust-red?logo=shield&logoColor=white)](https://en.wikipedia.org/wiki/Zero_trust_security_model)
[![ORCID](https://img.shields.io/badge/ORCID-0009--0008--9839--5763-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0009-0008-9839-5763)
[![CVE-2026-25253](https://img.shields.io/badge/CVE--2026--25253-Patched-brightgreen?logo=security&logoColor=white)](https://nvd.nist.gov/vuln/detail/CVE-2026-25253)

[![WCAG 2.1 AA](https://img.shields.io/badge/WCAG-2.1%20AA-blue.svg)](https://www.w3.org/WAI/WCAG21/quickref/)
[![Security: OWASP](https://img.shields.io/badge/Security-OWASP%20Top%2010-red.svg)](https://owasp.org/www-project-top-ten/)
[![RGPD](https://img.shields.io/badge/RGPD-Compliant-green.svg)](https://gdpr.eu/)

---

### 💖 Support This Project / Soutenir ce Projet

[![PayPal](https://img.shields.io/badge/PayPal-Donate_€5-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/VanessaBernier)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy_me_a_coffee-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/EthanThePhoenix)

*Every contribution helps! / Chaque contribution compte !* 🙏

---

**🇫🇷 [Version Française](#-guide-complet-fr) | 🇬🇧 [English Version](#-complete-guide-en)**

</div>

---

## 📖 Table of Contents / Sommaire

- [🇫🇷 Guide Complet (FR)](#-guide-complet-fr)
- [🇬🇧 Complete Guide (EN)](#-complete-guide-en)
- [🏗️ Architecture](#️-architecture)
- [🚀 Quick Start](#-quick-start)
- [📚 Documentation](#-documentation)
- [🛡️ Security Features](#️-security-features)
- [📊 Monitoring](#-monitoring)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)
- [💖 Support](#-support)

---

# 🇫🇷 Guide Complet (FR)

## Déployer Phoenix de manière Sécurisée sur Mac Studio M3 Ultra

### 📋 À propos

Ce guide complet vous accompagne pas à pas dans l'installation, la sécurisation et l'utilisation d'**Phoenix** sur un Mac Studio M3 Ultra. L'architecture propose **3 modes de déploiement** (local, k3d, cloud Koyeb) avec une installation **one-click** via un script d'onboarding interactif, tout en conservant l'accès natif au GPU M3 pour les LLM locaux (Ollama, LM Studio).

> ⚠️ **Sécurité** : Cette configuration intègre les correctifs post-**CVE-2026-25253** (RCE critique, CVSS 8.8). Image minimale requise : **2026.1.29**.

### 🎯 Objectifs

- ✅ **Installation one-click** : script d'onboarding interactif (`setup.sh`)
- ✅ **3 profils de déploiement** : local (Docker), k3d (Zero-Trust), cloud (Koyeb)
- ✅ Déploiement ultra-sécurisé post-CVE-2026-25253
- ✅ Utilisation optimale du GPU Apple Silicon (M1/M2/M3)
- ✅ Architecture Zero-Trust avec proxy Squid whitelist (mode k3d)
- ✅ Monitoring avec Prometheus et Grafana (mode k3d)
- ✅ Sauvegardes automatisées avec stratégie 3-2-1
- ✅ Conformité OWASP, CVE, RGPD, WCAG
- ✅ Token d'authentification gateway obligatoire
- ✅ Containers non-root, read-only, PID limits

### 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MAC STUDIO M3 ULTRA                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      KUBERNETES (k3s)                                │   │
│  │                                                                      │   │
│  │  ┌─────────────────┐      ┌─────────────────┐                       │   │
│  │  │    Phoenix     │─────▶│   Squid Proxy   │─────▶ Internet        │   │
│  │  │     :18789      │      │     :3128       │      (whitelist)      │   │
│  │  │   (Isolé)       │      │  (Whitelist)    │                       │   │
│  │  └────────┬────────┘      └─────────────────┘                       │   │
│  │           │                                                          │   │
│  │           │ host.docker.internal                                     │   │
│  │           ▼                                                          │   │
│  └───────────┼──────────────────────────────────────────────────────────┘   │
│              │                                                              │
│  ┌───────────▼──────────┐                                                  │
│  │       OLLAMA         │◀── GPU Metal (192GB Unified Memory)              │
│  │       :11434         │                                                  │
│  │   (Natif macOS)      │    Modèles: Llama 3.1 70B, Qwen, Mistral...     │
│  └──────────────────────┘                                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📦 Prérequis

| Composant | Version Minimum | Recommandé |
|-----------|-----------------|------------|
| macOS | 13.0 (Ventura) | 14.0+ (Sonoma) |
| RAM | 8 GB (Docker) | 64-192 GB (LLM locaux) |
| Stockage | 100 GB SSD | 500 GB+ NVMe |
| Docker Desktop | 4.25+ | Dernière version |
| Ollama | 0.3+ (optionnel) | Dernière version |
| Phoenix | **≥ 2026.1.29** | 2026.1.30 |

### 🚀 Installation Rapide (One-Click)

```bash
# 1. Cloner le projet
git clone https://github.com/EthanThePhoenix38/Phoenix.git && cd Phoenix

# 2. Lancer l'onboarding interactif (génère .env + lance la stack)
./scripts/setup.sh
```

Le script `setup.sh` vous guide à travers :
1. **Vérification des prérequis** (Docker, RAM, architecture)
2. **Choix du profil** : 🏠 local · 🛡️ k3d · ☁️ koyeb
3. **Configuration sécurité** (token gateway, auth, sandbox)
4. **Clés API** (Anthropic, OpenAI, Google, Mistral)
5. **Lancement automatique** de la stack

#### Installation manuelle

```bash
cd docker
cp .env.example .env
# Éditer .env (OBLIGATOIRE : changer PHOENIX_GATEWAY_TOKEN et GRAFANA_PASSWORD)
docker compose --profile <local|k3d|koyeb> up -d
```

### 🔄 Profils de Déploiement

| Profil | Usage | Proxy Squid | LLM Locaux | Monitoring | API Keys |
|--------|-------|-------------|------------|------------|----------|
| 🏠 `local` | Dev / Usage personnel | ❌ | ✅ Ollama, LM Studio | ❌ | Optionnelles |
| 🛡️ `k3d` | Production locale / Zero-Trust | ✅ Whitelist stricte | ✅ Ollama, LM Studio | ✅ Prometheus + Grafana | Optionnelles |
| ☁️ `koyeb` | Cloud Koyeb | ❌ | ❌ | ❌ | **Obligatoires** |

### 📚 Documentation Complète

📖 **[Ouvrir le guide interactif](./index.html)** (GitBook-style viewer)

| Partie | Chapitres | Description |
|--------|-----------|-------------|
| **Partie 1** | Chapitres 1-5 | Fondations : Introduction, Prérequis, Architecture |
| **Partie 2** | Chapitres 6-10 | Kubernetes : Installation k3s, Namespaces, Pods |
| **Partie 3** | Chapitres 11-15 | Sécurité : NetworkPolicies, Secrets, Proxy Squid |
| **Partie 4** | Chapitres 16-20 | Opérations : Monitoring, Alertes, Sauvegardes |
| **Partie 5** | Chapitres 21-24 | Avancé : HA, Scaling, Troubleshooting |
| **Annexes** | A-C | Glossaire, Commandes, Ressources |

---

# 🇬🇧 Complete Guide (EN)

## Deploy Phoenix Securely on Mac Studio M3 Ultra

### 📋 About

This comprehensive guide walks you through installing, securing, and using **Phoenix** on a Mac Studio M3 Ultra. The architecture provides **3 deployment profiles** (local, k3d, cloud Koyeb) with a **one-click** interactive onboarding script, while maintaining native M3 GPU access for local LLMs (Ollama, LM Studio).

> ⚠️ **Security**: This configuration includes post-**CVE-2026-25253** hardening (critical RCE, CVSS 8.8). Minimum image version: **2026.1.29**.

### 🎯 Goals

- ✅ **One-click installation**: interactive onboarding script (`setup.sh`)
- ✅ **3 deployment profiles**: local (Docker), k3d (Zero-Trust), cloud (Koyeb)
- ✅ Ultra-secure deployment post-CVE-2026-25253
- ✅ Optimal use of Apple Silicon GPU (M1/M2/M3)
- ✅ Zero-Trust architecture with Squid proxy whitelist (k3d mode)
- ✅ Monitoring with Prometheus and Grafana (k3d mode)
- ✅ Automated backups with 3-2-1 strategy
- ✅ OWASP, CVE, GDPR, WCAG compliance
- ✅ Mandatory gateway authentication tokens
- ✅ Non-root containers, read-only fs, PID limits

### 🚀 Quick Start (One-Click)

```bash
# 1. Clone the project
git clone https://github.com/EthanThePhoenix38/Phoenix.git && cd Phoenix

# 2. Run the interactive onboarding (generates .env + launches the stack)
./scripts/setup.sh
```

The `setup.sh` script guides you through:
1. **Prerequisites check** (Docker, RAM, architecture)
2. **Profile selection**: 🏠 local · 🛡️ k3d · ☁️ koyeb
3. **Security configuration** (gateway token, auth, sandbox)
4. **API keys** (Anthropic, OpenAI, Google, Mistral)
5. **Automatic stack launch**

### 🔄 Deployment Profiles

| Profile | Use Case | Squid Proxy | Local LLMs | Monitoring | API Keys |
|---------|----------|-------------|------------|------------|----------|
| 🏠 `local` | Dev / Personal use | ❌ | ✅ Ollama, LM Studio | ❌ | Optional |
| 🛡️ `k3d` | Local production / Zero-Trust | ✅ Strict whitelist | ✅ Ollama, LM Studio | ✅ Prometheus + Grafana | Optional |
| ☁️ `koyeb` | Koyeb cloud | ❌ | ❌ | ❌ | **Required** |

### 📚 Full Documentation

📖 **[Open interactive guide](./index.html)** (GitBook-style viewer)

| Part | Chapters | Description |
|------|----------|-------------|
| **Part 1** | Chapters 1-5 | Foundations: Introduction, Prerequisites, Architecture |
| **Part 2** | Chapters 6-10 | Kubernetes: k3s Installation, Namespaces, Pods |
| **Part 3** | Chapters 11-15 | Security: NetworkPolicies, Secrets, Squid Proxy |
| **Part 4** | Chapters 16-20 | Operations: Monitoring, Alerts, Backups |
| **Part 5** | Chapters 21-24 | Advanced: HA, Scaling, Troubleshooting |

---

## 🏗️ Architecture

### Security Layers / Couches de Sécurité (v2.0 — post-CVE-2026-25253)

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 0: Authentication                       │
│                    Gateway Token (mandatory), mDNS off           │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 1: Network Isolation                    │
│                    Bind 127.0.0.1, NetworkPolicies (k3d)        │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 2: Proxy Control (k3d only)             │
│                    Squid Proxy (domain whitelist)                │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 3: Container Security                   │
│                    Non-root, read-only fs, PID limits, no caps  │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 4: Secrets Management                   │
│                    .env (chmod 600), no hardcoded credentials    │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 5: Sandbox Isolation                    │
│                    Per-agent sandbox, non-main thread            │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 6: Monitoring & Audit (k3d)             │
│                    Prometheus, Grafana, security audit --deep    │
└─────────────────────────────────────────────────────────────────┘
```

### Directory Structure / Structure des Dossiers

```
PhoenixBook/
├── 📁 book/                      # Documentation (24 chapitres)
│   ├── 📁 fr/                    # Documentation française
│   └── 📁 en/                    # English documentation
├── 📁 kubernetes/
│   ├── namespace.yaml            # Namespace isolé
│   ├── deployment.yaml           # Deployment sécurisé
│   ├── service.yaml              # Services ClusterIP
│   ├── configmap.yaml            # Configurations
│   ├── secrets.yaml              # Template secrets
│   └── network-policy.yaml       # Policies Zero-Trust
├── 📁 docker/
│   ├── Dockerfile                # Multi-stage build sécurisé
│   ├── docker-compose.yml        # Stack multi-profil (local/k3d/koyeb)
│   ├── squid.conf                # Config proxy whitelist (k3d)
│   ├── .env.example              # Template config ultra-sécurisé
│   └── .env.koyeb                # Référence config cloud Koyeb
├── 📁 scripts/
│   ├── setup.sh                  # 🚀 Onboarding one-click interactif
│   ├── install-k3s.sh            # Installation k3s
│   ├── deploy-phoenix.sh        # Déploiement K8s
│   ├── setup-ollama.sh           # Config Ollama
│   └── backup.sh                 # Sauvegardes 3-2-1
├── 📁 PRODUCTION/                # Fichiers de production
├── 📁 assets/                    # Assets (images, etc.)
├── README.md                     # Ce fichier
├── CHANGELOG.md                  # Historique des changements
├── CITATION.cff                  # Citation académique
├── LICENSE                       # MIT License
└── index.html                    # GitBook viewer interactif
```

---

## 🛡️ Security Features / Fonctionnalités de Sécurité

> 🔒 Configuration conforme aux recommandations post-**CVE-2026-25253** (CSRF → RCE, CVSS 8.8)

| Feature | Description (FR/EN) | Profil |
|---------|---------------------|--------|
| **Gateway Auth Token** | Token obligatoire pour toute connexion / Mandatory token for all connections | Tous |
| **mDNS Disabled** | Découverte réseau désactivée / Network discovery disabled | Tous |
| **Secure Control UI** | Auth non-sécurisée interdite / Insecure auth disabled | Tous |
| **Bind localhost** | Port exposé uniquement sur 127.0.0.1 / Port bound to localhost only | local, k3d |
| **DM Pairing** | Couplage sécurisé obligatoire / Secure pairing required | Tous |
| **Zero-Trust Network** | Trafic bloqué par défaut / All traffic blocked by default | k3d |
| **Proxy Whitelist** | Seuls les domaines approuvés accessibles / Only approved domains accessible | k3d |
| **Non-root Containers** | User non-privilégié (UID 1000) / Unprivileged user (UID 1000) | Tous |
| **Read-only Filesystem** | FS en lecture seule + tmpfs ciblés / Read-only fs + targeted tmpfs | Tous |
| **No Capabilities** | `cap_drop: ALL` + `no-new-privileges` / All capabilities dropped | Tous |
| **PID Limits** | Anti fork-bomb (256 PIDs) / Fork bomb protection | Tous |
| **Sandbox Isolation** | Scope per-agent, thread non-main / Per-agent scope, non-main thread | Tous |
| **Secret Management** | `.env` chmod 600, jamais en dur / Never hardcoded, restricted permissions | Tous |
| **Audit Logging** | `phoenix security audit --deep` / Deep security audit | Tous |
| **Resource Limits** | CPU/Memory/PID limits / Prevent resource exhaustion | Tous |

---

## 📊 Monitoring

### Prometheus & Grafana

```bash
# Accéder à Prometheus / Access Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Accéder à Grafana / Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

---

## 📚 Citation

Si vous utilisez ce guide, merci de le citer / If you use this guide, please cite it:

```bibtex
@misc{bernier2026phoenix,
  author = {Bernier, Ethan},
  title = {Phoenix Secure K8s Guide},
  year = {2026},
  publisher = {GitHub},
  url = {https://github.com/EthanThePhoenix38/Phoenix}
}
```

Voir [CITATION.cff](./CITATION.cff) pour plus de détails.

---

## 🤝 Contributing / Contribuer

Les contributions sont bienvenues ! / Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📜 License / Licence

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 👤 Author / Auteur

**Ethan Bernier**

- 🆔 ORCID: [0009-0008-9839-5763](https://orcid.org/0009-0008-9839-5763)
- 🐙 GitHub: [@EthanThePhoenix38](https://github.com/EthanThePhoenix38)
- 📧 Email: ethan.bernier.data@gmail.com

---

## 💖 Support / Soutenir

Ce guide est gratuit et open source. Si vous le trouvez utile :

This guide is free and open source. If you find it useful:

<div align="center">

| Platform | Link |
|----------|------|
| ☕ Ko-fi | [ko-fi.com/EthanThePhoenix](https://ko-fi.com/EthanThePhoenix) |
| 💳 PayPal | [paypal.me/VanessaBernier](https://paypal.me/VanessaBernier) |
| ⭐ GitHub | Star this repo! / Donnez une étoile ! |

[![PayPal](https://img.shields.io/badge/PayPal-Donate_€5-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/VanessaBernier)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy_me_a_coffee-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/EthanThePhoenix)

</div>

---

## 🔗 Resources / Ressources

- [Phoenix Official](https://phoenix.ai/)
- [Phoenix Docs](https://docs.phoenix.ai/)
- [k3s Documentation](https://docs.k3s.io/)
- [Ollama](https://ollama.ai/)
- [LM Studio](https://lmstudio.ai/)

---

<div align="center">

**Made with ❤️ by Ethan Bernier**

*🦞 Phoenix Secure Kubernetes Deployment - Version 1.0.0 - 2026*

</div>
