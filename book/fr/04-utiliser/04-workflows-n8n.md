# 🎯 4.4 - Workflows n8n

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas connecter OpenClaw a n8n pour creer des workflows d'automatisation puissants. n8n permet d'orchestrer des taches complexes en combinant OpenClaw avec des centaines d'applications.

**Objectifs :**
- Installer n8n sur ton Mac Studio
- Connecter n8n au gateway OpenClaw
- Creer un workflow d'automatisation
- Declencher des workflows via les channels

---

## 🛠️ Prérequis

| Composant | Requis | Verification |
|-----------|--------|--------------|
| OpenClaw Gateway | Actif sur 18789 | `curl http://localhost:18789/api/health` |
| Docker | Installe | `docker --version` |
| Port 5678 | Disponible | `lsof -i :5678` |

---

## 📝 Étapes détaillées

### Étape 1 : Installer n8n avec Docker

**Pourquoi ?**
n8n est une plateforme d'automatisation open-source avec une interface visuelle. L'installation Docker isole n8n et simplifie la configuration.

**Comment ?**

Cree un volume pour les donnees persistantes :

```bash
docker volume create n8n_data
```

Lance n8n :

```bash
docker run -d --name n8n --restart unless-stopped -p 5678:5678 -v n8n_data:/home/node/.n8n --network host docker.n8n.io/n8nio/n8n
```

Note : `--network host` permet a n8n d'acceder facilement au gateway OpenClaw.

**Vérification :**
```bash
curl http://localhost:5678/healthz
```

Ouvre http://localhost:5678 dans ton navigateur. Cree un compte admin lors du premier lancement.

---

### Étape 2 : Configurer le node OpenClaw dans n8n

**Pourquoi ?**
n8n utilise des "nodes" pour communiquer avec les services externes. Tu vas configurer un node HTTP pour appeler l'API OpenClaw.

**Comment ?**

Dans n8n :
1. Clique sur **Settings** (engrenage) > **Credentials**
2. Clique **Add Credential** > **HTTP Header Auth**
3. Configure :
   - Name : `OpenClaw API`
   - Header Name : `Authorization`
   - Header Value : `Bearer ton-token-openclaw`

Cree le credential OpenClaw :
1. Va dans **Credentials** > **Add Credential**
2. Cherche **HTTP Request**
3. Configure :
   - Name : `OpenClaw Gateway`
   - Authentication : Generic Credential Type
   - Generic Auth Type : Header Auth
   - Header Auth : selectionne `OpenClaw API`

**Vérification :**

Cree un nouveau workflow :
1. Clique **New Workflow**
2. Ajoute un node **HTTP Request**
3. Configure :
   - Method : GET
   - URL : `http://localhost:18789/api/health`
   - Authentication : Predefined Credential Type > Header Auth
4. Clique **Execute Node**

Tu dois voir le statut du gateway.

---

### Étape 3 : Creer un workflow d'analyse d'email

**Pourquoi ?**
Ce workflow montre comment combiner OpenClaw avec d'autres services : recevoir un email, l'analyser avec le LLM, et envoyer une notification.

**Comment ?**

Cree un nouveau workflow et ajoute ces nodes :

**1. Trigger Email (IMAP)**
- Node : **Email Trigger (IMAP)**
- Host : ton serveur IMAP
- User : ton email
- Password : mot de passe application
- Mailbox : INBOX

**2. Analyse OpenClaw**
- Node : **HTTP Request**
- Method : POST
- URL : `http://localhost:18789/api/chat`
- Body Content Type : JSON
- Body :
```json
{
  "message": "Analyse cet email et determine s'il est urgent. Reponds avec un JSON contenant: urgent (boolean), resume (string), action_suggeree (string).\n\nSujet: {{ $json.subject }}\nContenu: {{ $json.text }}"
}
```

**3. Parse JSON**
- Node : **Code**
- Language : JavaScript
- Code :
```javascript
const response = JSON.parse($input.first().json.response);
return [{ json: response }];
```

**4. Condition**
- Node : **IF**
- Condition : `{{ $json.urgent }}` equals `true`

**5. Notification (si urgent)**
- Node : **Slack** ou **Telegram**
- Message : `Email urgent: {{ $json.resume }}\nAction: {{ $json.action_suggeree }}`

Connecte les nodes dans cet ordre et active le workflow.

**Vérification :**

Envoie un email de test a l'adresse configuree. Tu dois recevoir une notification si l'email est classe urgent.

---

### Étape 4 : Webhook pour declencher depuis les channels

**Pourquoi ?**
Tu peux declencher des workflows n8n depuis WhatsApp, Telegram ou Discord via des commandes speciales.

**Comment ?**

Cree un workflow avec trigger webhook :

**1. Webhook Trigger**
- Node : **Webhook**
- HTTP Method : POST
- Path : `openclaw-trigger`
- Authentication : Header Auth (optionnel)

Note l'URL du webhook (ex: `http://localhost:5678/webhook/openclaw-trigger`).

**2. Process Command**
- Node : **Code**
```javascript
const { command, args, channel, userId } = $input.first().json;

return [{
  json: {
    command,
    args,
    channel,
    userId,
    timestamp: new Date().toISOString()
  }
}];
```

**3. Switch par commande**
- Node : **Switch**
- Mode : Rules
- Add Rule : `{{ $json.command }}` equals `rapport`
- Add Rule : `{{ $json.command }}` equals `backup`
- Add Rule : `{{ $json.command }}` equals `stats`

**4. Actions specifiques pour chaque branche**

Configure OpenClaw pour appeler ce webhook :

```bash
nano ~/.openclaw/openclaw.json
```

```json
{
  "webhooks": {
    "n8n": {
      "enabled": true,
      "url": "http://localhost:5678/webhook/openclaw-trigger",
      "triggers": ["/workflow", "/rapport", "/backup", "/stats"],
      "includeContext": true
    }
  }
}
```

Redemarre le gateway :

```bash
docker restart openclaw-gateway
```

**Vérification :**

Envoie `/rapport` sur Telegram ou WhatsApp. Le workflow n8n doit se declencher.

---

### Étape 5 : Workflow avance avec boucle LLM

**Pourquoi ?**
Certaines taches necessitent plusieurs iterations avec le LLM : analyse iterative, generation avec revision, recherche progressive.

**Comment ?**

Cree un workflow "Agent de Recherche" :

**1. Trigger**
- Node : **Webhook**
- Path : `agent-recherche`

**2. Initialisation**
- Node : **Set**
```json
{
  "query": "{{ $json.query }}",
  "iterations": 0,
  "maxIterations": 5,
  "results": [],
  "done": false
}
```

**3. Boucle**
- Node : **Loop Over Items**
- Options :
  - Loop Count : `{{ $json.maxIterations }}`

**4. Appel OpenClaw dans la boucle**
- Node : **HTTP Request**
- URL : `http://localhost:18789/api/chat`
- Body :
```json
{
  "message": "Tu es un agent de recherche. Query: {{ $json.query }}\nResultats precedents: {{ $json.results }}\n\nSi tu as assez d'infos, reponds avec {\"done\": true, \"answer\": \"...\"}\nSinon, reponds avec {\"done\": false, \"nextSearch\": \"...\", \"partialResults\": \"...\"}"
}
```

**5. Check Done**
- Node : **IF**
- Condition : `{{ $json.done }}` equals `true`
- True : Sort de la boucle
- False : Continue

**6. Merge Results**
- Node : **Merge**
- Mode : Append

**7. Reponse Finale**
- Node : **Respond to Webhook**
- Body : `{{ $json.answer }}`

**Vérification :**
```bash
curl -X POST http://localhost:5678/webhook/agent-recherche -H "Content-Type: application/json" -d '{"query": "Quels sont les avantages du Mac Studio M3 Ultra?"}'
```

---

## ✅ Checklist

- [ ] n8n installe et accessible sur http://localhost:5678
- [ ] Compte admin cree
- [ ] Credentials OpenClaw configures
- [ ] Workflow basique HTTP Request fonctionne
- [ ] Workflow d'analyse email cree
- [ ] Webhook de trigger configure
- [ ] Commandes depuis les channels declenchent les workflows

---

## ⚠️ Dépannage

### Erreur : "Connection refused" vers OpenClaw

**Cause :** n8n ne peut pas atteindre le gateway.

**Solution :**

Si n8n est en mode `--network host`, utilise `localhost:18789`.

Si n8n est sur un reseau Docker separe :
```bash
docker network connect bridge n8n
```

Utilise `host.docker.internal:18789` dans les URLs.

---

### Erreur : "Workflow execution failed"

**Cause :** Erreur dans un node du workflow.

**Solution :**
1. Ouvre le workflow
2. Clique sur **Executions** dans le menu
3. Trouve l'execution echouee
4. Clique pour voir le detail de l'erreur
5. Corrige le node problematique

---

### Webhook non declenche

**Cause :** URL incorrecte ou workflow inactif.

**Solution :**
1. Verifie que le workflow est **Active** (toggle en haut)
2. Verifie l'URL exacte du webhook dans les parametres du node
3. Teste avec curl :
```bash
curl -X POST http://localhost:5678/webhook/ton-path -d '{}'
```

---

### Timeout sur les appels LLM

**Cause :** Le modele met trop de temps a repondre.

**Solution :**

Dans le node HTTP Request :
- Options > Timeout : augmente a 120000 (2 minutes)

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| Documentation n8n | https://docs.n8n.io |
| Nodes disponibles | https://n8n.io/integrations |
| Templates n8n | https://n8n.io/workflows |
| Community n8n | https://community.n8n.io |
| API OpenClaw | https://docs.openclaw.ai/api |

---

## ➡️ Prochaine étape

Tu maitrises l'automatisation avec n8n ! Dans le dernier chapitre de cette partie, tu vas integrer OpenClaw avec tes **outils de developpement** : [4.5 - Integrations Dev Tools](./05-integrations-dev-tools.md).
