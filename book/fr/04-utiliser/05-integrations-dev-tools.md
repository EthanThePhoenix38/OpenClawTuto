# 🎯 4.5 - Integrations Dev Tools

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas connecter Phoenix a tes outils de developpement : VS Code, Cursor et Windsurf. Ces integrations te permettent d'utiliser ton assistant IA local directement dans ton IDE.

**Objectifs :**
- Configurer l'extension VS Code pour Phoenix
- Integrer Cursor avec le gateway local
- Configurer Windsurf pour utiliser ton LLM local
- Creer des raccourcis et commandes personnalisees

---

## 🛠️ Prérequis

| Composant | Requis | Verification |
|-----------|--------|--------------|
| Phoenix Gateway | Actif sur 18789 | `curl http://localhost:18789/api/health` |
| VS Code | 1.85+ | `code --version` |
| Cursor | 0.40+ | Interface Cursor |
| Windsurf | Derniere version | Interface Windsurf |

---

## 📝 Étapes détaillées

### Étape 1 : Configurer VS Code avec Phoenix

**Pourquoi ?**
VS Code est l'editeur le plus populaire. L'extension Phoenix ajoute une sidebar IA et des commandes contextuelles pour interagir avec ton LLM local.

**Comment ?**

Installe l'extension Phoenix :

```bash
code --install-extension phoenix.phoenix-vscode
```

Ou depuis VS Code :
1. Ouvre la palette de commandes : `Cmd+Shift+P`
2. Tape "Extensions: Install Extensions"
3. Cherche "Phoenix"
4. Clique **Install**

Configure l'extension :

```bash
code ~/.vscode/settings.json
```

Ajoute ou modifie :

```json
{
  "phoenix.gateway.url": "http://localhost:18789",
  "phoenix.gateway.apiKey": "",
  "phoenix.provider.default": "ollama",
  "phoenix.model.default": "llama3.2:8b",
  "phoenix.chat.streamResponse": true,
  "phoenix.context.includeOpenFiles": true,
  "phoenix.context.maxTokens": 4096,
  "phoenix.shortcuts.explain": "Cmd+Shift+E",
  "phoenix.shortcuts.refactor": "Cmd+Shift+R",
  "phoenix.shortcuts.document": "Cmd+Shift+D"
}
```

Redemarre VS Code.

**Vérification :**
1. Ouvre VS Code
2. Clique sur l'icone Phoenix dans la sidebar (patte de chat)
3. Tape "Bonjour" dans le chat
4. Tu dois recevoir une reponse du LLM local

---

### Étape 2 : Utiliser les fonctionnalites VS Code

**Pourquoi ?**
L'extension offre des commandes contextuelles qui analysent ton code et utilisent le LLM pour t'aider : explication, refactoring, documentation, tests.

**Comment ?**

**Chat contextuel :**
1. Selectionne du code dans l'editeur
2. Clic droit > "Phoenix: Ask about selection"
3. Pose ta question dans le chat

**Explication de code :**
1. Selectionne une fonction ou classe
2. `Cmd+Shift+E` ou clic droit > "Phoenix: Explain"
3. Le LLM explique le code selectionne

**Refactoring assiste :**
1. Selectionne le code a ameliorer
2. `Cmd+Shift+R` ou clic droit > "Phoenix: Refactor"
3. Decris l'amelioration souhaitee
4. Applique les suggestions

**Generation de documentation :**
1. Place le curseur sur une fonction
2. `Cmd+Shift+D` ou clic droit > "Phoenix: Document"
3. Le LLM genere les docstrings/JSDoc

**Generation de tests :**
1. Selectionne une fonction
2. Palette de commandes > "Phoenix: Generate Tests"
3. Choisis le framework (Jest, Pytest, etc.)

**Vérification :**

Cree un fichier test :

```bash
cat > /tmp/test.js << 'EOF'
function calculateDiscount(price, percentage) {
  if (percentage < 0 || percentage > 100) {
    throw new Error("Invalid percentage");
  }
  return price - (price * percentage / 100);
}
EOF
```

Ouvre dans VS Code, selectionne la fonction, et teste `Cmd+Shift+E`.

---

### Étape 3 : Configurer Cursor avec Phoenix

**Pourquoi ?**
Cursor est un IDE base sur VS Code avec des fonctionnalites IA integrees. Tu peux le configurer pour utiliser ton gateway Phoenix au lieu des API cloud.

**Comment ?**

Ouvre les parametres Cursor :
1. `Cmd+,` pour ouvrir Settings
2. Cherche "AI" ou "OpenAI"

Configure le proxy local :

Dans Cursor, va dans **Settings > Models > OpenAI API Key** et configure :
- API Base URL : `http://localhost:18789/v1`
- API Key : `local` (ou ton token Phoenix)

Alternative via fichier de configuration :

```bash
nano ~/.cursor/settings.json
```

```json
{
  "ai.provider": "openai-compatible",
  "ai.openaiBaseUrl": "http://localhost:18789/v1",
  "ai.openaiApiKey": "local",
  "ai.model": "llama3.2:8b",
  "ai.temperature": 0.7,
  "ai.maxTokens": 4096
}
```

**Vérification :**
1. Ouvre Cursor
2. Selectionne du code
3. Appuie sur `Cmd+K` pour ouvrir le chat inline
4. Pose une question sur le code

Tu dois recevoir une reponse de ton LLM local.

---

### Étape 4 : Configurer Windsurf avec Phoenix

**Pourquoi ?**
Windsurf est un IDE IA qui peut utiliser des providers personnalises. L'integration avec Phoenix te donne un controle total sur le modele utilise.

**Comment ?**

Ouvre les parametres Windsurf :
1. Menu **Windsurf > Preferences > Settings**
2. Ou raccourci `Cmd+,`

Cherche "AI Provider" et configure :

```json
{
  "windsurf.ai.provider": "custom",
  "windsurf.ai.customEndpoint": "http://localhost:18789/v1/chat/completions",
  "windsurf.ai.customApiKey": "local",
  "windsurf.ai.model": "llama3.2:8b",
  "windsurf.ai.contextWindow": 8192
}
```

Configure les fonctionnalites avancees :

```json
{
  "windsurf.cascade.enabled": true,
  "windsurf.cascade.provider": "custom",
  "windsurf.cascade.endpoint": "http://localhost:18789/v1",
  "windsurf.codeCompletion.provider": "custom",
  "windsurf.codeCompletion.endpoint": "http://localhost:18789/v1/completions"
}
```

**Vérification :**
1. Ouvre un projet dans Windsurf
2. Utilise la commande Cascade (`Cmd+L`)
3. Demande une modification de code
4. Verifie que la reponse vient de ton LLM local

---

### Étape 5 : Creer des snippets et templates

**Pourquoi ?**
Les snippets permettent d'inserer rapidement des prompts frequents. Les templates standardisent les demandes au LLM.

**Comment ?**

Cree des snippets VS Code :

```bash
nano ~/.vscode/snippets/phoenix.code-snippets
```

```json
{
  "Phoenix Review": {
    "prefix": "ocreview",
    "body": [
      "// @phoenix-review",
      "// Analyse ce code pour:",
      "// - Bugs potentiels",
      "// - Problemes de performance",
      "// - Violations des best practices",
      "// - Suggestions d'amelioration",
      "$0"
    ],
    "description": "Demande une review de code a Phoenix"
  },
  "Phoenix Test": {
    "prefix": "octest",
    "body": [
      "// @phoenix-generate-tests",
      "// Framework: ${1|jest,pytest,mocha,vitest|}",
      "// Couverture: ${2|unit,integration,e2e|}",
      "// Style: ${3|bdd,tdd|}",
      "$0"
    ],
    "description": "Genere des tests avec Phoenix"
  },
  "Phoenix Explain": {
    "prefix": "ocexplain",
    "body": [
      "// @phoenix-explain",
      "// Niveau: ${1|debutant,intermediaire,expert|}",
      "// Focus: ${2|logique,performance,securite|}",
      "$0"
    ],
    "description": "Demande une explication a Phoenix"
  }
}
```

Configure des templates dans Phoenix :

```bash
nano ~/.phoenix/templates/code-review.json
```

```json
{
  "name": "code-review",
  "description": "Review de code complete",
  "prompt": "Tu es un senior developer expert. Analyse le code suivant:\n\n```{{language}}\n{{code}}\n```\n\nFournis:\n1. Resume (2-3 phrases)\n2. Bugs potentiels\n3. Problemes de performance\n4. Suggestions d'amelioration\n5. Note globale (1-10)",
  "parameters": {
    "language": "auto-detect",
    "code": "selection"
  }
}
```

Utilise le template :

```bash
docker exec phoenix-gateway phoenix template run code-review --code "function add(a,b){return a+b}"
```

**Vérification :**

Dans VS Code, tape `ocreview` et appuie sur Tab. Le snippet doit s'inserer.

---

## ✅ Checklist

- [ ] Extension VS Code Phoenix installee et configuree
- [ ] Chat VS Code connecte au gateway local
- [ ] Raccourcis clavier fonctionnels (Explain, Refactor, Document)
- [ ] Cursor configure avec l'endpoint Phoenix
- [ ] Chat inline Cursor utilise le LLM local
- [ ] Windsurf configure avec le provider custom
- [ ] Snippets personnalises crees
- [ ] Templates Phoenix configures

---

## ⚠️ Dépannage

### VS Code : Extension ne se connecte pas

**Cause :** URL du gateway incorrecte ou gateway non demarre.

**Solution :**
```bash
curl http://localhost:18789/api/health
```

Si erreur, redemarre le gateway :
```bash
docker restart phoenix-gateway
```

Verifie les parametres VS Code : `Cmd+,` > cherche "phoenix.gateway.url".

---

### Cursor : "API Key invalid"

**Cause :** Configuration du proxy incorrecte.

**Solution :**

Assure-toi que l'URL se termine par `/v1` :
```
http://localhost:18789/v1
```

Utilise "local" ou une chaine non-vide comme API key.

---

### Windsurf : Cascade ne repond pas

**Cause :** Endpoint incorrect ou timeout.

**Solution :**

Teste l'endpoint manuellement :
```bash
curl -X POST http://localhost:18789/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"llama3.2:8b","messages":[{"role":"user","content":"test"}]}'
```

Augmente le timeout dans Windsurf si le modele est lent.

---

### Completions de code lentes

**Cause :** Modele trop grand ou contexte trop large.

**Solution :**

Utilise un modele plus petit pour les completions :
```json
{
  "windsurf.codeCompletion.model": "llama3.2:3b"
}
```

Reduis la fenetre de contexte :
```json
{
  "phoenix.context.maxTokens": 2048
}
```

---

### Snippets ne s'activent pas

**Cause :** Fichier de snippets mal forme ou dans le mauvais dossier.

**Solution :**

Verifie la syntaxe JSON :
```bash
cat ~/.vscode/snippets/phoenix.code-snippets | jq .
```

Recharge VS Code : `Cmd+Shift+P` > "Developer: Reload Window".

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| Extension VS Code Phoenix | https://marketplace.visualstudio.com/items?itemName=phoenix.phoenix-vscode |
| Documentation Cursor | https://cursor.sh/docs |
| Documentation Windsurf | https://codeium.com/windsurf |
| API OpenAI Compatible | https://platform.openai.com/docs/api-reference |
| Snippets VS Code | https://code.visualstudio.com/docs/editor/userdefinedsnippets |

---

## ➡️ Prochaine étape

Felicitations ! Tu as termine la partie "Utiliser". Tu sais maintenant connecter des LLM locaux, configurer des channels de messagerie, installer des skills, automatiser avec n8n et integrer tes outils de dev.

Dans la prochaine partie, tu vas apprendre a **maintenir** ton installation Phoenix : [Partie 5 - Maintenir](../05-maintenir/01-depannage-mac-m3.md).
