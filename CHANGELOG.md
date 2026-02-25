# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Versioning Sémantique](https://semver.org/lang/fr/).

## [Unreleased]

### Ajouté

- Chapitres FR:
  - `book/fr/05-maintenir/04-durcissement-pods-et-orphelins.md`
  - `book/fr/03-securiser/08-pods-modulaires-networkpolicy-rollback.md`
- Chapitres EN:
  - `book/en/05-maintain/04-pod-hardening-and-orphan-cleanup.md`
  - `book/en/03-secure/08-modular-pods-networkpolicy-and-rollback.md`

### Modifié

- Alignement de nomenclature pods/agents vers une convention stable:
  - `phoenix-router`
  - `phoenix-planner`
  - `phoenix-implementer`
  - `phoenix-qa`
  - `phoenix-security`
  - `phoenix-messaging`
- `index.html`:
  - correction des liens de chapitres vers des cibles réelles (`book/fr/*`, `kubernetes/`, `scripts/`)
  - affichage explicite côté EN: `translation pending` tant que la version FR n'est pas figée

## [2.0.0] - 2026-02-13

### Ajouté

- **Architecture multi-profil** : 3 modes de déploiement exclusifs
  - 🏠 `local` : Docker simple, LLM locaux, pas de proxy
  - 🛡️ `k3d` : Docker + Squid proxy whitelist + Prometheus/Grafana (Zero-Trust)
  - ☁️ `koyeb` : Cloud Koyeb, API keys obligatoires, pas de LLM local

- **Installation one-click** (`scripts/setup.sh`)
  - Onboarding interactif avec vérification des prérequis
  - Génération automatique du fichier `.env` sécurisé (chmod 600)
  - Token gateway généré automatiquement (openssl rand -hex 32)
  - Lancement automatique de la stack après configuration

- **Fichier `.env.koyeb`** : référence de configuration pour déploiement cloud Koyeb

- **Support API supplémentaires** : Google AI (Gemini), Mistral AI

### Sécurité

- ⚠️ **Patch CVE-2026-25253** (CSRF → RCE, CVSS 8.8) : image minimale 2026.1.29
- **Token d'authentification gateway obligatoire** (`PHOENIX_AUTH_MODE=token`)
- **Bind localhost** (`127.0.0.1`) par défaut pour modes local et k3d
- **mDNS désactivé** en production (`PHOENIX_MDNS_MODE=off`)
- **Control UI sécurisé** (`PHOENIX_CONTROL_UI_INSECURE_AUTH=false`)
- **Sandbox per-agent** (`PHOENIX_SANDBOX_SCOPE=agent`)
- **PID limits** (256) : protection anti fork-bomb
- **Filesystem read-only** avec tmpfs ciblés
- **`no-new-privileges`** + `cap_drop: ALL` sur tous les containers
- **DM en mode pairing** : couplage sécurisé obligatoire
- **7 couches de sécurité** documentées (Layer 0-6)

### Modifié

- `docker-compose.yml` : refonte complète avec Docker Compose profiles
- `.env.example` : restructuré avec toutes les options de sécurité documentées
- `README.md` : mis à jour avec profils, one-click, et tableau de sécurité par profil
- Badge CVE-2026-25253 ajouté au README
- Structure des dossiers mise à jour dans la documentation

---

## [1.0.0] - 2026-02-02

### Ajouté

- **Documentation complète** (24 chapitres bilingues FR/EN)
  - Partie 1 : Comprendre (3 chapitres)
  - Partie 2 : Installer (6 chapitres)
  - Partie 3 : Sécuriser (7 chapitres)
  - Partie 4 : Utiliser (5 chapitres)
  - Partie 5 : Maintenir (3 chapitres)
  - Annexes (glossaire, commandes, ressources)

- **Configuration Kubernetes complète**
  - `namespace.yaml` : Namespace isolé phoenix
  - `deployment.yaml` : Déploiement Phoenix sécurisé
  - `service.yaml` : Services ClusterIP et NodePort
  - `configmap.yaml` : Configuration Phoenix
  - `secrets.yaml` : Gestion des secrets chiffrés
  - `network-policy.yaml` : Politiques réseau restrictives

- **Configuration Docker**
  - `Dockerfile` : Image Phoenix durcie
  - `docker-compose.yml` : Stack complète avec proxy
  - `squid.conf` : Proxy whitelist configuré

- **Scripts d'automatisation**
  - `install-k3s.sh` : Installation k3s sur macOS
  - `deploy-phoenix.sh` : Déploiement complet
  - `setup-ollama.sh` : Installation Ollama native
  - `backup.sh` : Sauvegarde automatique

- **Interface web**
  - `index.html` : GitBook-style viewer interactif
  - Navigation responsive mobile-first
  - Mode sombre/clair automatique
  - Accessibilité WCAG 2.1 AA

- **Métadonnées**
  - `CITATION.cff` : Citation académique avec ORCID
  - `README.md` : Documentation bilingue avec badges
  - `LICENSE` : MIT License

### Sécurité

- Architecture Zero Trust
- Network policies deny-all par défaut
- Proxy Squid obligatoire pour accès internet
- Sandbox strict pour agents non-principaux
- Audit CVE/OWASP/NIST documenté
- Pas de secrets en dur (Kubernetes Secrets)

### Conformité

- WCAG 2.1 AA (accessibilité)
- RGPD (protection données)
- OWASP Top 10 (sécurité web)
- SOLID/DRY/OOP (qualité code)

---

## Types de changements

- **Ajouté** : nouvelles fonctionnalités
- **Modifié** : changements de fonctionnalités existantes
- **Déprécié** : fonctionnalités bientôt supprimées
- **Supprimé** : fonctionnalités supprimées
- **Corrigé** : corrections de bugs
- **Sécurité** : corrections de vulnérabilités
