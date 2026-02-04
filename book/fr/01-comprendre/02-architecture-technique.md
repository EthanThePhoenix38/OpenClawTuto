# 🎯 1.2 - Architecture technique

## 📋 Ce que tu vas apprendre

- Comment OpenClaw est structuré
- Le rôle de chaque composant
- Comment les données circulent
- L'architecture spécifique pour Mac Studio M3 Ultra

## 🛠️ Prérequis

- [Chapitre 1.1](./01-quest-ce-que-openclaw.md) complété

---

## 📝 Vue d'ensemble

OpenClaw fonctionne comme un **hub central** qui connecte tes messageries à un cerveau IA. Voici l'architecture simplifiée :

```
┌─────────────────────────────────────────────────────────────────┐
│                        TON MAC STUDIO                           │
│                                                                 │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │   WhatsApp   │     │   Telegram   │     │   Discord    │    │
│  └──────┬───────┘     └──────┬───────┘     └──────┬───────┘    │
│         │                    │                    │             │
│         └────────────────────┼────────────────────┘             │
│                              ▼                                  │
│                    ┌──────────────────┐                         │
│                    │     GATEWAY      │                         │
│                    │   (port 18789)   │                         │
│                    └────────┬─────────┘                         │
│                             │                                   │
│              ┌──────────────┼──────────────┐                    │
│              ▼              ▼              ▼                    │
│       ┌──────────┐   ┌──────────┐   ┌──────────┐               │
│       │  Agent   │   │  Skills  │   │  Tools   │               │
│       │   (Pi)   │   │          │   │          │               │
│       └────┬─────┘   └──────────┘   └──────────┘               │
│            │                                                    │
│            ▼                                                    │
│       ┌──────────────────────────────────────┐                  │
│       │              LLM                      │                  │
│       │  (Ollama / LM Studio / API cloud)    │                  │
│       └──────────────────────────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧩 Les composants détaillés

### 1. Gateway (Passerelle)

Le **Gateway** est le serveur WebSocket central. C'est le chef d'orchestre.

**Ce qu'il fait :**
- Écoute sur `ws://127.0.0.1:18789`
- Gère l'authentification des connexions
- Route les messages entrants vers l'agent
- Renvoie les réponses aux bons canaux
- Stocke les sessions et l'historique

**Fichiers importants :**
```
~/.openclaw/
├── openclaw.json          # Configuration principale
├── credentials/           # Tokens des messageries
│   └── whatsapp/
│       └── creds.json
├── agents/
│   └── main/
│       ├── sessions/      # Historique conversations
│       └── auth-profiles.json
└── workspace/             # Fichiers de travail
```

### 2. Channels (Canaux)

Les **channels** sont les connecteurs vers les messageries.

**Architecture d'un channel :**
```
┌─────────────────────────────────────────────┐
│              Channel WhatsApp               │
│                                             │
│  ┌─────────────┐    ┌─────────────────┐    │
│  │   Baileys   │───►│  WebSocket      │    │
│  │  (library)  │    │  Gateway        │    │
│  └─────────────┘    └─────────────────┘    │
│         │                                   │
│         ▼                                   │
│  ┌─────────────┐                           │
│  │  WhatsApp   │                           │
│  │  Servers    │                           │
│  └─────────────┘                           │
└─────────────────────────────────────────────┘
```

**Channels supportés (v2026.1.30) :**

| Channel | Bibliothèque | Port par défaut |
|---------|--------------|-----------------|
| WhatsApp | Baileys | - |
| Telegram | grammY | - |
| Discord | discord.js | - |
| Slack | Bolt | - |
| iMessage | imsg CLI | - |
| Signal | signal-cli | - |
| Teams | Graph API | - |
| Matrix | matrix-js-sdk | - |
| WebChat | Built-in | 18789 |

### 3. Agent (Pi)

L'**agent** est le cerveau qui traite les requêtes.

**Modes de fonctionnement :**
- **RPC Mode** : Communication par appels de fonction
- **Tool Streaming** : Exécution d'outils en temps réel
- **Block Streaming** : Réponses par blocs progressifs

**Cycle de traitement :**
```
Message reçu
     │
     ▼
┌─────────────┐
│   Parser    │ ──► Analyse le message
└─────┬───────┘
      │
      ▼
┌─────────────┐
│   Router    │ ──► Choisit l'agent/session
└─────┬───────┘
      │
      ▼
┌─────────────┐
│    LLM      │ ──► Génère la réponse
└─────┬───────┘
      │
      ▼
┌─────────────┐
│   Tools     │ ──► Exécute les actions (si besoin)
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  Formatter  │ ──► Adapte au format du channel
└─────────────┘
```

### 4. Tools (Outils)

Les **tools** sont les capacités d'action de l'agent.

**Outils intégrés :**

| Outil | Description | Risque |
|-------|-------------|--------|
| `bash` | Exécuter des commandes shell | Élevé |
| `read` | Lire des fichiers | Moyen |
| `write` | Écrire des fichiers | Élevé |
| `browser` | Contrôler Chrome | Élevé |
| `web_fetch` | Télécharger des pages | Moyen |
| `web_search` | Rechercher sur le web | Faible |
| `canvas` | Créer des visuels | Faible |

### 5. LLM (Modèle IA)

Le **LLM** est le modèle de langage qui génère les réponses.

**Options supportées :**

| Type | Exemples | Avantages | Inconvénients |
|------|----------|-----------|---------------|
| **API Cloud** | Claude, GPT-4 | Puissant | Payant, données envoyées |
| **Local** | Ollama, LM Studio | Gratuit, privé | Nécessite GPU |

---

## 🖥️ Architecture Mac Studio M3 Ultra

Pour ce guide, voici l'architecture **sécurisée** recommandée :

```
┌─────────────────────────────────────────────────────────────────┐
│                    MAC STUDIO M3 ULTRA                          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    NATIF (GPU M3 Access)                  │  │
│  │                                                           │  │
│  │   ┌─────────────┐           ┌─────────────┐              │  │
│  │   │   OLLAMA    │           │  LM STUDIO  │              │  │
│  │   │  :11434     │           │   :1234     │              │  │
│  │   └─────────────┘           └─────────────┘              │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                    host.docker.internal                         │
│                              │                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                 KUBERNETES (k3s)                          │  │
│  │                                                           │  │
│  │   ┌────────────────────────────────────────────────────┐ │  │
│  │   │              NAMESPACE: openclaw                    │ │  │
│  │   │                                                     │ │  │
│  │   │  ┌──────────────┐    ┌──────────────┐             │ │  │
│  │   │  │   OPENCLAW   │    │    SQUID     │             │ │  │
│  │   │  │   Gateway    │───►│    Proxy     │───► Internet│ │  │
│  │   │  │   :18789     │    │   :3128      │             │ │  │
│  │   │  └──────────────┘    └──────────────┘             │ │  │
│  │   │                                                     │ │  │
│  │   │  Network: 172.20.0.0/16 (isolé)                    │ │  │
│  │   └────────────────────────────────────────────────────┘ │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Pourquoi cette architecture ?

**1. LLM HORS Kubernetes (natif)**

Les LLM locaux (Ollama, LM Studio) tournent **directement sur macOS** pour :
- ✅ Accès complet au GPU M3 Ultra (192 Go RAM unifiée)
- ✅ Performances optimales (pas de virtualisation)
- ✅ Pas de limitation de mémoire container

**2. OpenClaw DANS Kubernetes (isolé)**

Le Gateway tourne dans un **pod Kubernetes** pour :
- ✅ Isolation totale du système hôte
- ✅ Pas d'accès direct aux fichiers Mac
- ✅ Réseau contrôlé (network policies)
- ✅ Redémarrage automatique si crash

**3. Proxy Squid (whitelist)**

Tout accès internet passe par **Squid** pour :
- ✅ Whitelist des domaines autorisés
- ✅ Logs de toutes les requêtes
- ✅ Blocage des exfiltrations de données

---

## 🔄 Flux de données

Voici comment un message circule dans le système :

```
1. Tu écris sur WhatsApp
         │
         ▼
2. WhatsApp envoie à Baileys (dans le pod)
         │
         ▼
3. Baileys transmet au Gateway
         │
         ▼
4. Gateway route vers l'Agent
         │
         ▼
5. Agent appelle le LLM (via host.docker.internal)
         │
         ▼
6. LLM (Ollama) génère la réponse (GPU M3)
         │
         ▼
7. Agent reçoit la réponse
         │
         ▼
8. Si besoin d'internet → Proxy Squid → Whitelist check
         │
         ▼
9. Gateway renvoie à Baileys
         │
         ▼
10. Baileys envoie à WhatsApp
         │
         ▼
11. Tu reçois la réponse
```

---

## 📊 Diagramme de sécurité

```
┌─────────────────────────────────────────────────────────────────┐
│                        COUCHES DE SÉCURITÉ                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ COUCHE 1: Network Policies                                 │ │
│  │ - Deny all par défaut                                      │ │
│  │ - Whitelist explicite des communications                   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ COUCHE 2: Pod Security                                     │ │
│  │ - Read-only root filesystem                                │ │
│  │ - Non-root user                                            │ │
│  │ - Capabilities dropped                                     │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ COUCHE 3: Proxy Squid                                      │ │
│  │ - Whitelist domaines                                       │ │
│  │ - Logging complet                                          │ │
│  │ - Rate limiting                                            │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ COUCHE 4: OpenClaw Sandbox                                 │ │
│  │ - Tool allowlist                                           │ │
│  │ - Path restrictions                                        │ │
│  │ - Command filtering                                        │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ COUCHE 5: Gateway Auth                                     │ │
│  │ - Token obligatoire                                        │ │
│  │ - DM pairing mode                                          │ │
│  │ - Allowlists par channel                                   │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist

- [ ] J'ai compris le rôle du Gateway (hub central)
- [ ] J'ai compris comment les channels connectent les messageries
- [ ] J'ai compris pourquoi les LLM sont HORS Kubernetes (GPU)
- [ ] J'ai compris pourquoi OpenClaw est DANS Kubernetes (isolation)
- [ ] J'ai compris le rôle du proxy Squid (whitelist internet)
- [ ] J'ai compris les 5 couches de sécurité

---

## ⚠️ Dépannage

**Problème :** Je ne comprends pas pourquoi séparer LLM et OpenClaw

**Solution :** macOS ne permet pas aux containers Docker d'accéder au GPU Metal. Si tu mets Ollama dans Docker, il utilisera le CPU (10x plus lent). En le gardant natif, tu profites des 192 Go de RAM unifiée et du GPU M3.

---

## 🔗 Ressources

- [Architecture OpenClaw (docs officielles)](https://docs.openclaw.ai/gateway/architecture)
- [k3s Architecture](https://docs.k3s.io/architecture)
- [Metal Performance Shaders (Apple)](https://developer.apple.com/metal/)

---

## ➡️ Prochaine étape

👉 [Chapitre 1.3 - Pourquoi Kubernetes et Docker ?](./03-pourquoi-kubernetes-docker.md)
