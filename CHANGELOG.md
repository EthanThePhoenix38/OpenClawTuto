# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Versioning Sémantique](https://semver.org/lang/fr/).

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
  - `namespace.yaml` : Namespace isolé openclaw
  - `deployment.yaml` : Déploiement OpenClaw sécurisé
  - `service.yaml` : Services ClusterIP et NodePort
  - `configmap.yaml` : Configuration OpenClaw
  - `secrets.yaml` : Gestion des secrets chiffrés
  - `network-policy.yaml` : Politiques réseau restrictives

- **Configuration Docker**
  - `Dockerfile` : Image OpenClaw durcie
  - `docker-compose.yml` : Stack complète avec proxy
  - `squid.conf` : Proxy whitelist configuré

- **Scripts d'automatisation**
  - `install-k3s.sh` : Installation k3s sur macOS
  - `deploy-openclaw.sh` : Déploiement complet
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
