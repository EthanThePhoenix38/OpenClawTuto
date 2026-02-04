# 🦞 OpenClaw Secure Kubernetes Deployment

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-24.0+-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3-000000?logo=apple&logoColor=white)](https://www.apple.com/mac/)
[![Security](https://img.shields.io/badge/Security-Zero%20Trust-red?logo=shield&logoColor=white)](https://en.wikipedia.org/wiki/Zero_trust_security_model)
[![ORCID](https://img.shields.io/badge/ORCID-0009--0008--9839--5763-A6CE39?logo=orcid&logoColor=white)](https://orcid.org/0009-0008-9839-5763)

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

## Déployer OpenClaw de manière Sécurisée sur Mac Studio M3 Ultra avec Kubernetes

### 📋 À propos

Ce guide complet vous accompagne pas à pas dans l'installation, la sécurisation et l'utilisation d'**OpenClaw** sur un Mac Studio M3 Ultra. L'architecture proposée utilise Kubernetes (k3s) pour l'isolation maximale, tout en conservant l'accès natif au GPU M3 pour les LLM locaux (Ollama, LM Studio).

### 🎯 Objectifs

- ✅ Déploiement sécurisé avec isolation réseau complète
- ✅ Utilisation optimale du GPU Apple Silicon (M1/M2/M3)
- ✅ Architecture Zero-Trust avec NetworkPolicies
- ✅ Proxy Squid avec whitelist stricte
- ✅ Monitoring avec Prometheus et Grafana
- ✅ Sauvegardes automatisées avec stratégie 3-2-1
- ✅ Conformité OWASP, CVE, RGPD, WCAG

### 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MAC STUDIO M3 ULTRA                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      KUBERNETES (k3s)                                │   │
│  │                                                                      │   │
│  │  ┌─────────────────┐      ┌─────────────────┐                       │   │
│  │  │    OpenClaw     │─────▶│   Squid Proxy   │─────▶ Internet        │   │
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
| RAM | 32 GB | 64-192 GB |
| Stockage | 100 GB SSD | 500 GB+ NVMe |
| Docker Desktop | 4.25+ | Dernière version |
| Homebrew | 4.0+ | Dernière version |

### 🚀 Installation Rapide

```bash
git clone https://github.com/EthanThePhoenix38/Openclaw.git && cd Openclaw && ./scripts/install-k3s.sh && ./scripts/setup-ollama.sh && ./scripts/deploy-openclaw.sh && kubectl get pods -n openclaw
```

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

## Deploy OpenClaw Securely on Mac Studio M3 Ultra with Kubernetes

### 📋 About

This comprehensive guide walks you through installing, securing, and using **OpenClaw** on a Mac Studio M3 Ultra. The proposed architecture uses Kubernetes (k3s) for maximum isolation while maintaining native M3 GPU access for local LLMs (Ollama, LM Studio).

### 🎯 Goals

- ✅ Secure deployment with complete network isolation
- ✅ Optimal use of Apple Silicon GPU (M1/M2/M3)
- ✅ Zero-Trust architecture with NetworkPolicies
- ✅ Squid proxy with strict whitelist
- ✅ Monitoring with Prometheus and Grafana
- ✅ Automated backups with 3-2-1 strategy
- ✅ OWASP, CVE, GDPR, WCAG compliance

### 🚀 Quick Start

```bash
git clone https://github.com/EthanThePhoenix38/Openclaw.git && cd Openclaw && ./scripts/install-k3s.sh && ./scripts/setup-ollama.sh && ./scripts/deploy-openclaw.sh && kubectl get pods -n openclaw
```

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

### Security Layers / Couches de Sécurité

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 1: Network Isolation                    │
│                    NetworkPolicies (deny-all + whitelist)        │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 2: Proxy Control                        │
│                    Squid Proxy (domain whitelist)                │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 3: Container Security                   │
│                    Non-root, read-only fs, no capabilities       │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 4: Secrets Management                   │
│                    K8s Secrets, no hardcoded credentials         │
├─────────────────────────────────────────────────────────────────┤
│                    LAYER 5: Monitoring & Audit                   │
│                    Prometheus, Grafana, audit logs               │
└─────────────────────────────────────────────────────────────────┘
```

### Directory Structure / Structure des Dossiers

```
clawdbot-secure-k8s/
├── 📁 docs/
│   ├── 📁 fr/                    # Documentation française (24 chapitres)
│   └── 📁 en/                    # English documentation (24 chapters)
├── 📁 kubernetes/
│   ├── namespace.yaml            # Namespace isolé
│   ├── deployment.yaml           # Deployment sécurisé
│   ├── service.yaml              # Services ClusterIP
│   ├── configmap.yaml            # Configurations
│   ├── secrets.yaml              # Template secrets
│   └── network-policy.yaml       # Policies Zero-Trust
├── 📁 docker/
│   ├── Dockerfile                # Multi-stage build
│   ├── docker-compose.yml        # Stack complète
│   ├── squid.conf                # Config proxy
│   └── .env.example              # Variables template
├── 📁 scripts/
│   ├── install-k3s.sh            # Installation k3s
│   ├── deploy-openclaw.sh        # Déploiement K8s
│   ├── setup-ollama.sh           # Config Ollama
│   └── backup.sh                 # Sauvegardes 3-2-1
├── 📁 monitoring/
│   ├── prometheus.yml            # Métriques
│   └── grafana-dashboard.json    # Dashboards
├── README.md                     # Ce fichier
├── CITATION.cff                  # Citation académique
├── LICENSE                       # MIT License
└── index.html                    # GitBook viewer
```

---

## 🛡️ Security Features / Fonctionnalités de Sécurité

| Feature | Description (FR/EN) |
|---------|---------------------|
| **Zero-Trust Network** | Tout le trafic bloqué par défaut / All traffic blocked by default |
| **Proxy Whitelist** | Seuls les domaines approuvés accessibles / Only approved domains accessible |
| **Non-root Containers** | Tous les containers en user non-privilégié / All containers run unprivileged |
| **Read-only Filesystem** | Systèmes de fichiers en lecture seule / Read-only container filesystems |
| **No Capabilities** | Toutes les capabilities Linux supprimées / All Linux capabilities dropped |
| **Secret Management** | Kubernetes Secrets, jamais en dur / Never hardcoded |
| **Audit Logging** | Toutes les actions journalisées / All actions logged |
| **Resource Limits** | Limites CPU/Memory / CPU/Memory limits prevent exhaustion |

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
@misc{bernier2026openclaw,
  author = {Bernier, Ethan},
  title = {OpenClaw Secure K8s Guide},
  year = {2026},
  publisher = {GitHub},
  url = {https://github.com/EthanThePhoenix38/Openclaw}
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

- [OpenClaw Official](https://openclaw.ai/)
- [OpenClaw Docs](https://docs.openclaw.ai/)
- [k3s Documentation](https://docs.k3s.io/)
- [Ollama](https://ollama.ai/)
- [LM Studio](https://lmstudio.ai/)

---

<div align="center">

**Made with ❤️ by Ethan Bernier**

*🦞 OpenClaw Secure Kubernetes Deployment - Version 1.0.0 - 2026*

</div>
