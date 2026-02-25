# 🎯 4.2 - Channels de Messagerie

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas connecter Phoenix a differentes plateformes de messagerie : WhatsApp, Telegram, Discord et iMessage. Chaque channel permet d'interagir avec ton assistant IA depuis l'application de ton choix.

**Objectifs :**
- Configurer WhatsApp via Baileys (sans API officielle)
- Connecter un bot Telegram avec grammY
- Integrer Discord avec discord.js
- Configurer iMessage (macOS uniquement)

---

## 🛠️ Prérequis

| Composant | Requis | Verification |
|-----------|--------|--------------|
| Phoenix Gateway | Actif sur port 18789 | `curl http://localhost:18789/api/health` |
| Numero WhatsApp | Smartphone avec WhatsApp | Application installee |
| Bot Telegram | Token BotFather | `@BotFather` sur Telegram |
| Serveur Discord | Droits administrateur | Acces aux parametres serveur |
| macOS | Pour iMessage | `sw_vers` |

---

## 📝 Étapes détaillées

### Étape 1 : Configurer WhatsApp (Baileys)

**Pourquoi ?**
Baileys permet de connecter WhatsApp sans passer par l'API Business payante. La connexion utilise WhatsApp Web et necessite un scan QR code initial.

**Comment ?**

Active le channel WhatsApp dans la configuration :

```bash
nano ~/.phoenix/phoenix.json
```

```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "adapter": "baileys",
      "sessionPath": "~/.phoenix/whatsapp-session",
      "autoReconnect": true,
      "qrTimeout": 60000,
      "allowedNumbers": ["+33612345678"],
      "webhookUrl": "http://localhost:18789/api/channels/whatsapp/webhook"
    }
  }
}
```

Demarre la connexion WhatsApp :

```bash
docker exec -it phoenix-gateway phoenix channel whatsapp connect
```

Un QR code s'affiche dans le terminal. Scanne-le avec WhatsApp :
1. Ouvre WhatsApp sur ton telephone
2. Va dans **Parametres > Appareils lies**
3. Clique sur **Lier un appareil**
4. Scanne le QR code

**Vérification :**
```bash
docker exec phoenix-gateway phoenix channel whatsapp status
```

Tu dois voir `status: connected` et ton numero.

---

### Étape 2 : Configurer Telegram (grammY)

**Pourquoi ?**
Telegram offre une API bot gratuite et puissante. grammY est un framework TypeScript moderne qui simplifie le developpement de bots Telegram.

**Comment ?**

Cree un bot via BotFather :
1. Ouvre Telegram et cherche `@BotFather`
2. Envoie `/newbot`
3. Suis les instructions (nom, username)
4. Copie le token API fourni

Configure le channel Telegram :

```bash
nano ~/.phoenix/phoenix.json
```

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "adapter": "grammy",
      "token": "TON_TOKEN_BOTFATHER",
      "allowedUsers": [123456789],
      "commands": {
        "start": "Bienvenue ! Je suis ton assistant Phoenix.",
        "help": "Commandes: /start, /help, /clear, /model"
      },
      "webhookUrl": "http://localhost:18789/api/channels/telegram/webhook"
    }
  }
}
```

Remplace `TON_TOKEN_BOTFATHER` par ton vrai token.

Pour trouver ton user ID Telegram, envoie un message a `@userinfobot`.

Redemarre et verifie :

```bash
docker restart phoenix-gateway && sleep 5 && docker exec phoenix-gateway phoenix channel telegram status
```

**Vérification :**

Envoie `/start` a ton bot sur Telegram. Tu dois recevoir le message de bienvenue.

---

### Étape 3 : Configurer Discord (discord.js)

**Pourquoi ?**
Discord est ideal pour les equipes et communautes. Le bot peut repondre dans des channels dedies ou en messages prives.

**Comment ?**

Cree une application Discord :
1. Va sur https://discord.com/developers/applications
2. Clique **New Application**
3. Donne un nom et cree
4. Va dans **Bot** > **Add Bot**
5. Copie le token du bot
6. Active **Message Content Intent** dans **Privileged Gateway Intents**

Genere le lien d'invitation :
1. Va dans **OAuth2 > URL Generator**
2. Coche `bot` dans Scopes
3. Coche `Send Messages`, `Read Message History` dans Bot Permissions
4. Copie l'URL et ouvre-la pour inviter le bot

Configure le channel Discord :

```bash
nano ~/.phoenix/phoenix.json
```

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "adapter": "discordjs",
      "token": "TON_TOKEN_DISCORD",
      "prefix": "!claw",
      "allowedGuilds": ["123456789012345678"],
      "allowedChannels": ["987654321098765432"],
      "respondToMentions": true,
      "respondToDMs": true
    }
  }
}
```

Redemarre le gateway :

```bash
docker restart phoenix-gateway
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix channel discord status
```

Envoie `!claw bonjour` dans un channel autorise.

---

### Étape 4 : Configurer iMessage (macOS)

**Pourquoi ?**
Sur macOS, Phoenix peut repondre aux iMessages. Cette fonctionnalite utilise AppleScript et necessite des permissions speciales.

**Comment ?**

Accorde les permissions :
1. Va dans **Preferences Systeme > Securite et confidentialite > Confidentialite**
2. Selectionne **Automatisation**
3. Autorise Terminal (ou Docker) a controler Messages

Configure le channel iMessage :

```bash
nano ~/.phoenix/phoenix.json
```

```json
{
  "channels": {
    "imessage": {
      "enabled": true,
      "adapter": "applescript",
      "allowedContacts": ["+33612345678", "email@exemple.com"],
      "pollInterval": 5000,
      "autoRead": true
    }
  }
}
```

Active le service iMessage :

```bash
docker exec phoenix-gateway phoenix channel imessage enable
```

**Vérification :**
```bash
docker exec phoenix-gateway phoenix channel imessage status
```

Envoie un iMessage depuis un contact autorise. La reponse devrait arriver automatiquement.

---

### Étape 5 : Gerer plusieurs channels simultanement

**Pourquoi ?**
Tu peux utiliser tous les channels en meme temps. Phoenix route les messages vers le bon provider LLM et renvoie les reponses au bon channel.

**Comment ?**

Voici une configuration complete multi-channel :

```bash
nano ~/.phoenix/phoenix.json
```

```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "adapter": "baileys",
      "sessionPath": "~/.phoenix/whatsapp-session"
    },
    "telegram": {
      "enabled": true,
      "adapter": "grammy",
      "token": "TON_TOKEN_TELEGRAM"
    },
    "discord": {
      "enabled": true,
      "adapter": "discordjs",
      "token": "TON_TOKEN_DISCORD",
      "prefix": "!claw"
    },
    "imessage": {
      "enabled": true,
      "adapter": "applescript"
    }
  },
  "routing": {
    "defaultProvider": "ollama",
    "channelOverrides": {
      "discord": "lmstudio",
      "telegram": "ollama"
    }
  }
}
```

Verifie tous les channels :

```bash
docker exec phoenix-gateway phoenix channels list
```

**Vérification :**
```bash
curl http://localhost:18789/api/channels/status | jq
```

Tous les channels actives doivent afficher `"connected": true`.

---

## ✅ Checklist

- [ ] WhatsApp : QR code scanne et session sauvegardee
- [ ] Telegram : Bot cree via BotFather et token configure
- [ ] Discord : Application creee et bot invite sur le serveur
- [ ] iMessage : Permissions accordees (macOS uniquement)
- [ ] Configuration JSON valide dans `~/.phoenix/phoenix.json`
- [ ] Gateway redemarre sans erreur
- [ ] Chaque channel repond aux messages de test

---

## ⚠️ Dépannage

### WhatsApp : QR code expire

**Cause :** Le QR code a une duree de vie de 60 secondes.

**Solution :**
```bash
docker exec -it phoenix-gateway phoenix channel whatsapp reconnect
```

---

### WhatsApp : Deconnexion frequente

**Cause :** WhatsApp detecte une activite suspecte.

**Solution :**
- Utilise un seul appareil lie a la fois
- Evite les reponses trop rapides (< 1 seconde)
- Ajoute un delai dans la configuration :
```json
{
  "channels": {
    "whatsapp": {
      "responseDelay": 2000
    }
  }
}
```

---

### Telegram : Bot ne repond pas

**Cause :** Token invalide ou user non autorise.

**Solution :**
```bash
docker logs phoenix-gateway | grep telegram
```

Verifie que ton user ID est dans `allowedUsers`.

---

### Discord : "Missing Access" error

**Cause :** Le bot n'a pas les permissions necessaires.

**Solution :**
1. Verifie les permissions du bot sur le serveur
2. Active **Message Content Intent** dans le portail developpeur
3. Re-invite le bot avec les bonnes permissions

---

### iMessage : "Not authorized"

**Cause :** Permissions macOS manquantes.

**Solution :**
1. Ouvre **Preferences Systeme > Securite et confidentialite**
2. Onglet **Confidentialite > Automatisation**
3. Autorise l'acces a l'application Messages

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| Baileys (WhatsApp) | https://github.com/WhiskeySockets/Baileys |
| grammY (Telegram) | https://grammy.dev |
| discord.js | https://discord.js.org |
| BotFather | https://t.me/botfather |
| Discord Developer Portal | https://discord.com/developers |

---

## ➡️ Prochaine étape

Tes channels de messagerie sont configures ! Dans le chapitre suivant, tu vas decouvrir les **Skills et Modules** du marketplace ClawHub : [4.3 - Skills et Modules](./03-skills-modules.md).
