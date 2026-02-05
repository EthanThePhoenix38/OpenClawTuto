# 🎯 1.1 - Qu'est-ce qu'OpenClaw ?

## 📋 Ce que tu vas apprendre

- L'histoire d'OpenClaw (de Clawdbot à aujourd'hui)
- Ce que fait OpenClaw concrètement
- Pourquoi c'est différent des autres assistants IA

## 🛠️ Prérequis

- Aucun ! C'est le premier chapitre

---

## 📝 Introduction

**OpenClaw**, c'est ton assistant IA personnel qui vit sur TON ordinateur. Imagine un assistant comme ChatGPT, mais qui :

1. **Tourne chez toi** (pas sur les serveurs d'une entreprise)
2. **Parle sur toutes tes messageries** (WhatsApp, Telegram, Discord, iMessage...)
3. **Peut faire des actions** (exécuter du code, gérer des fichiers, naviguer sur le web)
4. **Garde tes données privées** (rien ne sort de ta machine sans ton accord)

C'est le "couteau suisse" des assistants IA, mais **tu contrôles tout**.

---

## 📖 L'histoire : De Clawdbot à OpenClaw

### 🦀 Clawdbot (2024)

Tout a commencé avec **Clawdbot** ("Claude" + "Bot"). C'était un projet expérimental pour connecter l'API Claude d'Anthropic à des messageries.

Le problème ? Le nom "Clawdbot" ressemblait trop à "Claude", ce qui créait de la confusion.

### 🦞 MoltBot (2025)

Le projet a été renommé **MoltBot** (référence à la "mue" du homard). Nouvelle identité, même philosophie : un assistant IA local et privé.

Mais le nom ne collait pas vraiment à la communauté...

### 🦞 OpenClaw (2026)

Finalement, le projet est devenu **OpenClaw** en janvier 2026 :
- "Open" = open source, transparent
- "Claw" = la pince (hommage au homard/crabe)

Le logo officiel est maintenant un homard rouge 🦞.

**Version actuelle** : `2026.1.30` (sortie le 30 janvier 2026)

---

## 🔧 Que fait OpenClaw concrètement ?

### 1. Gateway (Passerelle)

Le **Gateway** est le cœur d'OpenClaw. C'est un serveur local qui :

- Écoute sur le port `18789` par défaut
- Connecte toutes tes messageries en un seul point
- Gère les sessions de conversation
- Route les messages vers l'IA

```
[WhatsApp] ──┐
[Telegram] ──┼──► [Gateway :18789] ──► [LLM]
[Discord]  ──┤                          │
[iMessage] ──┘                          ▼
                                   [Réponse]
```

### 2. Channels (Canaux)

OpenClaw supporte **12+ messageries** :

| Catégorie | Plateformes |
|-----------|-------------|
| **Messageries** | WhatsApp, Telegram, Discord, Signal |
| **Travail** | Slack, Microsoft Teams, Google Chat |
| **Apple** | iMessage (via imsg CLI) |
| **Autres** | Matrix, Mattermost, Zalo, WebChat |

Tu peux parler à ton assistant depuis N'IMPORTE laquelle de ces apps !

### 3. Agent IA

L'agent (appelé "Pi") est le cerveau. Il peut :

- Répondre à tes questions
- Exécuter du code (Python, Bash, Node...)
- Naviguer sur le web avec un navigateur contrôlé
- Gérer des fichiers sur ta machine
- Créer des images, des documents...

### 4. Skills (Compétences)

Les **skills** sont des modules qui étendent les capacités :

- Envoi d'emails
- Gestion de calendrier
- Automatisation de tâches
- Intégration avec des APIs tierces

---

## 🌟 Pourquoi OpenClaw est différent ?

### vs ChatGPT / Claude.ai

| Aspect | ChatGPT/Claude.ai | OpenClaw |
|--------|-------------------|----------|
| **Où ça tourne** | Serveurs cloud | Ton ordinateur |
| **Tes données** | Stockées chez eux | Restent chez toi |
| **Messageries** | Juste leur interface | WhatsApp, Telegram, Discord... |
| **Actions** | Limité | Exécute du code, navigue, fichiers |
| **Modèle IA** | Leur choix | Ton choix (Ollama, GPT, Claude...) |
| **Coût** | Abonnement mensuel | Gratuit (tu paies juste l'API) |

### vs Auto-GPT / AgentGPT

| Aspect | Auto-GPT | OpenClaw |
|--------|----------|----------|
| **Interface** | Terminal/Web | Tes messageries habituelles |
| **Sécurité** | Basique | Sandbox, isolation, audit |
| **Stabilité** | Expérimental | Production-ready |
| **Messageries** | Non | 12+ plateformes |

### L'avantage clé

OpenClaw est le **seul** assistant qui combine :

1. ✅ Exécution locale (privacy)
2. ✅ Multi-messageries (convenience)
3. ✅ Actions système (power)
4. ✅ Sécurité enterprise (safety)

---

## ⚠️ Ce qu'OpenClaw n'est PAS

Pour éviter les malentendus :

- ❌ **Pas un chatbot basique** : il peut exécuter du code, pas juste répondre
- ❌ **Pas dangereux par défaut** : le sandbox limite ce qu'il peut faire
- ❌ **Pas gratuit à 100%** : tu paies l'API du LLM (Anthropic, OpenAI...) ou tu utilises des LLM locaux gratuits (Ollama)
- ❌ **Pas magique** : il reste limité par le modèle IA que tu choisis

---

## ✅ Checklist

- [ ] J'ai compris ce qu'est OpenClaw (assistant IA local multi-messageries)
- [ ] J'ai compris l'histoire (Clawdbot → MoltBot → OpenClaw)
- [ ] J'ai compris la différence avec ChatGPT (local vs cloud)
- [ ] J'ai compris les composants (Gateway, Channels, Agent, Skills)

---

## 🔗 Ressources

- [Site officiel OpenClaw](https://openclaw.ai/)
- [Documentation officielle](https://docs.openclaw.ai/)
- [GitHub OpenClaw](https://github.com/openclaw/openclaw)
- [Annonce du rebranding (janvier 2026)](https://medium.com/@balazskocsis/openclaw-now-with-tighter-security-a063ecf564ff)

---

## ➡️ Prochaine étape

👉 [Chapitre 1.2 - Architecture technique](./02-architecture-technique.md)
