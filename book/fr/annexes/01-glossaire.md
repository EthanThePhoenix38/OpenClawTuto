# 📚 Annexe A - Glossaire Technique

## A

### Agent
Programme autonome qui exécute des tâches pour le compte de l'utilisateur. Dans Phoenix, l'agent est le "cerveau" qui répond aux messages.

### API (Application Programming Interface)
Interface qui permet à deux programmes de communiquer. Exemple : l'API d'Anthropic permet à Phoenix d'utiliser Claude.

### ARIA (Accessible Rich Internet Applications)
Standard qui améliore l'accessibilité des applications web pour les lecteurs d'écran.

---

## B

### Base64
Encodage qui convertit des données binaires en texte. Utilisé pour stocker les secrets Kubernetes.

### Bridge (réseau)
Réseau virtuel qui connecte plusieurs containers entre eux tout en les isolant du réseau hôte.

---

## C

### Channel (canal)
Dans Phoenix, un canal est une plateforme de messagerie (WhatsApp, Telegram, Discord, etc.).

### CI/CD (Continuous Integration/Continuous Deployment)
Pratique d'automatisation qui teste et déploie le code automatiquement à chaque modification.

### CNI (Container Network Interface)
Standard Kubernetes pour configurer le réseau des containers.

### ConfigMap
Ressource Kubernetes pour stocker des configurations non-sensibles.

### Container (conteneur)
Environnement isolé qui contient une application et toutes ses dépendances.

### CPU (Central Processing Unit)
Processeur de l'ordinateur. Mesuré en "cores" ou "millicores" (m) dans Kubernetes.

### CRD (Custom Resource Definition)
Extension de Kubernetes pour créer de nouveaux types de ressources.

### CSP (Content Security Policy)
En-tête HTTP qui protège contre les attaques XSS en limitant les sources de contenu.

### CVE (Common Vulnerabilities and Exposures)
Identifiant unique pour une vulnérabilité de sécurité connue. Format : CVE-YYYY-NNNNN.

### CVSS (Common Vulnerability Scoring System)
Score de 0 à 10 qui mesure la gravité d'une vulnérabilité. >7 = critique.

### CWE (Common Weakness Enumeration)
Catalogue des types de faiblesses de sécurité dans le code.

---

## D

### Daemon
Programme qui tourne en arrière-plan de façon permanente.

### Deployment
Ressource Kubernetes qui gère le déploiement et la mise à jour d'une application.

### Docker
Plateforme de containerisation la plus populaire.

### Docker Compose
Outil pour définir et lancer des applications multi-containers.

### Dockerfile
Fichier qui décrit comment construire une image Docker.

### DOI (Digital Object Identifier)
Identifiant unique et permanent pour un document numérique.

### DRY (Don't Repeat Yourself)
Principe de développement : ne pas dupliquer le code.

---

## E

### Egress
Trafic réseau sortant (de l'intérieur vers l'extérieur).

### Endpoint
Point d'accès réseau (généralement une URL ou IP:port).

---

## F

### FIDO2
Standard d'authentification sans mot de passe utilisant des clés de sécurité.

---

## G

### Gateway
Point d'entrée central qui route les requêtes. Dans Phoenix, le Gateway gère tous les canaux.

### GPU (Graphics Processing Unit)
Processeur graphique, utilisé pour accélérer les calculs IA.

### Grafana
Outil de visualisation pour créer des dashboards de monitoring.

---

## H

### Health Check
Vérification périodique qu'une application fonctionne correctement.

### Helm
Gestionnaire de packages pour Kubernetes.

### Host
Machine physique ou virtuelle qui héberge des containers.

### HTTP/HTTPS
Protocoles de communication web. HTTPS = HTTP + chiffrement TLS.

---

## I

### Image (Docker)
Template immuable utilisé pour créer des containers.

### Ingress
Trafic réseau entrant (de l'extérieur vers l'intérieur). Aussi : ressource Kubernetes pour exposer des services.

### ISBN (International Standard Book Number)
Numéro unique qui identifie un livre.

---

## J

### JSON (JavaScript Object Notation)
Format de données léger et lisible. Exemple : `{"clé": "valeur"}`.

### JWT (JSON Web Token)
Token sécurisé pour l'authentification, encodé en Base64.

---

## K

### k3s
Distribution légère de Kubernetes, idéale pour un usage local.

### Kubectl
Outil en ligne de commande pour interagir avec Kubernetes.

### Kubernetes (K8s)
Plateforme d'orchestration de containers.

---

## L

### Latence
Délai entre l'envoi d'une requête et la réception de la réponse.

### LLM (Large Language Model)
Modèle d'IA de grande taille entraîné sur du texte. Exemples : Claude, GPT, Llama.

### LM Studio
Application pour faire tourner des LLM en local avec interface graphique.

### Liveness Probe
Vérification Kubernetes pour savoir si un container est "vivant".

---

## M

### Manifest
Fichier YAML décrivant une ressource Kubernetes.

### Metal (Apple)
API graphique d'Apple pour accéder au GPU sur Mac.

### MITRE ATT&CK
Framework de tactiques et techniques d'attaque utilisé en cybersécurité.

### MVC (Model-View-Controller)
Architecture qui sépare données (Model), interface (View) et logique (Controller).

---

## N

### Namespace
Isolation logique dans Kubernetes. Permet de séparer les ressources.

### Network Policy
Règles Kubernetes qui contrôlent le trafic réseau entre pods.

### NIST (National Institute of Standards and Technology)
Organisation américaine qui publie des standards de sécurité.

### Node
Machine (physique ou virtuelle) dans un cluster Kubernetes.

### npm (Node Package Manager)
Gestionnaire de packages pour Node.js.

---

## O

### OAuth
Protocole d'autorisation qui permet de se connecter via un compte externe (Google, GitHub, etc.).

### Ollama
Outil pour faire tourner des LLM en local via la ligne de commande.

### OOP (Object-Oriented Programming)
Programmation orientée objet : organiser le code en classes et objets.

### Phoenix
Assistant IA personnel open source. Anciennement Clawdbot/MoltBot.

### ORCID
Identifiant unique pour les chercheurs et auteurs.

### OWASP (Open Web Application Security Project)
Organisation qui publie des guides de sécurité web. Le "Top 10" liste les 10 vulnérabilités les plus critiques.

---

## P

### Pairing
Dans Phoenix, processus d'approbation d'un nouvel utilisateur.

### PersistentVolume (PV)
Stockage persistant dans Kubernetes.

### PersistentVolumeClaim (PVC)
Demande de stockage par un pod Kubernetes.

### Pod
Plus petite unité déployable dans Kubernetes. Contient un ou plusieurs containers.

### Port
Numéro (0-65535) qui identifie un service sur une machine. Exemples : 80 (HTTP), 443 (HTTPS), 18789 (Phoenix).

### Prometheus
Système de monitoring et d'alerting pour Kubernetes.

### Proxy
Intermédiaire entre un client et un serveur. Peut filtrer, cacher ou modifier le trafic.

### PWA (Progressive Web App)
Application web qui peut fonctionner offline et être installée comme une app native.

---

## Q

### Quantization
Technique pour réduire la taille d'un modèle IA en diminuant la précision des poids.

---

## R

### RAM (Random Access Memory)
Mémoire vive de l'ordinateur.

### RBAC (Role-Based Access Control)
Système de permissions basé sur des rôles.

### Readiness Probe
Vérification Kubernetes pour savoir si un container est prêt à recevoir du trafic.

### ReplicaSet
Ressource Kubernetes qui maintient un nombre constant de réplicas d'un pod.

### RGPD (Règlement Général sur la Protection des Données)
Loi européenne sur la protection des données personnelles.

### Rolling Update
Mise à jour progressive qui remplace les pods un par un sans interruption de service.

---

## S

### Sandbox
Environnement isolé pour exécuter du code potentiellement dangereux.

### Secret (Kubernetes)
Ressource pour stocker des données sensibles (mots de passe, clés API).

### Service (Kubernetes)
Abstraction qui expose un groupe de pods via une IP stable.

### Skill
Dans Phoenix, un plugin qui ajoute des capacités (recherche web, lecture de fichiers, etc.).

### SOLID
5 principes de conception logicielle : Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion.

### Squid
Proxy HTTP/HTTPS configurable, utilisé pour filtrer le trafic.

### SSH (Secure Shell)
Protocole sécurisé pour se connecter à distance à un serveur.

### SSL/TLS (Secure Sockets Layer / Transport Layer Security)
Protocoles de chiffrement pour sécuriser les communications. TLS est la version moderne.

---

## T

### Tailscale
VPN mesh qui crée un réseau privé entre tes appareils.

### Token
Chaîne de caractères utilisée pour l'authentification ou l'autorisation.

---

## U

### URI (Uniform Resource Identifier)
Identifiant unique d'une ressource. Une URL est un type d'URI.

---

## V

### Volume
Stockage attaché à un container Kubernetes.

---

## W

### WCAG (Web Content Accessibility Guidelines)
Standards d'accessibilité web. Niveaux : A, AA, AAA.

### WebSocket
Protocole de communication bidirectionnel en temps réel.

### Whitelist
Liste de ce qui est autorisé (tout le reste est bloqué).

---

## X

### XSS (Cross-Site Scripting)
Attaque qui injecte du code malveillant dans une page web.

---

## Y

### YAML (YAML Ain't Markup Language)
Format de fichier lisible utilisé pour les configurations Kubernetes.

---

## Z

### Zero Trust
Modèle de sécurité : ne jamais faire confiance, toujours vérifier.

---

## Ressources complémentaires

- [Glossaire Kubernetes officiel](https://kubernetes.io/docs/reference/glossary/)
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/)
- [CVE Database](https://cve.mitre.org/)
