# 🎯 4.1 - Connexion aux LLM Locaux

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas configurer Phoenix pour utiliser des modèles de langage locaux via Ollama et LM Studio. L'avantage ? Tes conversations restent 100% privées sur ton Mac Studio M3 Ultra, sans dépendre d'Internet ou de services cloud.

**Objectifs :**
- Connecter Ollama (port 11434) à Phoenix
- Connecter LM Studio (port 1234) à Phoenix
- Basculer dynamiquement entre les providers
- Optimiser les performances pour le M3 Ultra

---

## 🛠️ Prérequis

| Composant | Version | Vérification |
|-----------|---------|--------------|
| Phoenix | v2026.1.30+ | `docker exec phoenix-gateway phoenix --version` |
| Ollama | 0.3+ | `ollama --version` |
| LM Studio | 0.3+ | Interface graphique lancée |
| Modèle téléchargé | Au moins 1 | `ollama list` |

**Ressources système recommandées :**
- RAM disponible : 32 Go minimum (modèles 7B-13B)
- GPU Metal : Activé pour l'accélération
- Espace disque : 50 Go pour les modèles

---

## 📝 Étapes détaillées

### Étape 1 : Vérifier qu'Ollama fonctionne

**Pourquoi ?**
Avant de connecter Phoenix, tu dois t'assurer qu'Ollama répond correctement aux requêtes API. Ollama expose une API REST compatible OpenAI sur le port 11434.

**Comment ?**

Lance Ollama s'il n'est pas déjà actif :

```bash
ollama serve
```

Dans un autre terminal, teste la connexion :

```bash
curl http://localhost:11434/api/tags
```

Télécharge un modèle si tu n'en as pas encore :

```bash
ollama pull llama3.2:8b
```

**Vérification :**
```bash
curl http://localhost:11434/api/generate -d '{"model": "llama3.2:8b", "prompt": "Dis bonjour", "stream": false}' | jq .response
```

Tu dois voir une réponse textuelle du modèle.

---

### Étape 2 : Configurer Ollama dans Phoenix

**Pourquoi ?**
Phoenix utilise `host.docker.internal` pour accéder aux services de l'hôte depuis les conteneurs Docker. Cette URL spéciale permet la communication entre le conteneur et ton Mac.

**Comment ?**

Ouvre le fichier de configuration :

```bash
nano ~/.phoenix/phoenix.json
```

Ajoute ou modifie la section `providers` :

```json
{
  "providers": {
    "ollama": {
      "enabled": true,
      "baseUrl": "http://host.docker.internal:11434",
      "defaultModel": "llama3.2:8b",
      "timeout": 120000,
      "maxTokens": 4096,
      "temperature": 0.7
    }
  },
  "defaultProvider": "ollama"
}
```

Redémarre le gateway pour appliquer :

```bash
docker restart phoenix-gateway
```

**Vérification :**
```bash
curl http://localhost:18789/api/health | jq '.providers.ollama'
```

Le statut doit indiquer `"status": "connected"`.

---

### Étape 3 : Configurer LM Studio

**Pourquoi ?**
LM Studio offre une interface graphique conviviale et permet de tester différents modèles GGUF. Son serveur local est compatible avec l'API OpenAI, ce qui facilite l'intégration.

**Comment ?**

1. Ouvre LM Studio sur ton Mac
2. Va dans l'onglet **Local Server** (icône serveur)
3. Clique sur **Start Server**
4. Note le port (par défaut : 1234)

Vérifie que le serveur répond :

```bash
curl http://localhost:1234/v1/models
```

Ajoute LM Studio dans la configuration Phoenix :

```bash
nano ~/.phoenix/phoenix.json
```

```json
{
  "providers": {
    "ollama": {
      "enabled": true,
      "baseUrl": "http://host.docker.internal:11434",
      "defaultModel": "llama3.2:8b"
    },
    "lmstudio": {
      "enabled": true,
      "baseUrl": "http://host.docker.internal:1234/v1",
      "defaultModel": "local-model",
      "apiType": "openai-compatible"
    }
  },
  "defaultProvider": "ollama"
}
```

**Vérification :**
```bash
docker restart phoenix-gateway && sleep 5 && curl http://localhost:18789/api/health | jq '.providers'
```

---

### Étape 4 : Basculer entre les providers

**Pourquoi ?**
Tu peux vouloir utiliser différents modèles selon la tâche : un modèle rapide pour les questions simples, un modèle plus puissant pour le code ou l'analyse.

**Comment ?**

Via l'API REST :

```bash
curl -X POST http://localhost:18789/api/provider/switch -H "Content-Type: application/json" -d '{"provider": "lmstudio"}'
```

Via la commande CLI :

```bash
docker exec phoenix-gateway phoenix provider use lmstudio
```

Pour voir le provider actif :

```bash
docker exec phoenix-gateway phoenix provider current
```

**Vérification :**

Envoie un message de test :

```bash
curl -X POST http://localhost:18789/api/chat -H "Content-Type: application/json" -d '{"message": "Quel provider utilises-tu ?"}'
```

---

### Étape 5 : Optimiser pour le M3 Ultra

**Pourquoi ?**
Le Mac Studio M3 Ultra dispose de ressources exceptionnelles (jusqu'à 192 Go de RAM unifiée, GPU 80 coeurs). Une configuration optimisée permet d'utiliser des modèles plus grands avec de meilleures performances.

**Comment ?**

Configure Ollama pour utiliser le GPU Metal :

```bash
export OLLAMA_NUM_GPU=999
```

Pour rendre permanent, ajoute dans `~/.zshrc` :

```bash
echo 'export OLLAMA_NUM_GPU=999' >> ~/.zshrc && source ~/.zshrc
```

Ajuste les paramètres de contexte pour les grands modèles :

```bash
nano ~/.phoenix/phoenix.json
```

```json
{
  "providers": {
    "ollama": {
      "enabled": true,
      "baseUrl": "http://host.docker.internal:11434",
      "defaultModel": "llama3.2:70b",
      "options": {
        "num_ctx": 8192,
        "num_gpu": 999,
        "num_thread": 16
      }
    }
  },
  "performance": {
    "maxConcurrentRequests": 4,
    "requestTimeout": 300000,
    "enableStreaming": true
  }
}
```

**Vérification :**
```bash
ollama run llama3.2:70b "Test de performance" --verbose 2>&1 | grep "eval rate"
```

Tu devrais voir un taux d'evaluation superieur a 30 tokens/seconde sur le M3 Ultra.

---

## ✅ Checklist

- [ ] Ollama est installe et le service tourne
- [ ] Au moins un modele est telecharge dans Ollama
- [ ] LM Studio est installe et le serveur local demarre
- [ ] Le fichier `~/.phoenix/phoenix.json` contient les deux providers
- [ ] Phoenix gateway redemarre sans erreur
- [ ] Le health check montre les deux providers connectes
- [ ] Le basculement entre providers fonctionne
- [ ] Les variables d'environnement GPU sont configurees

---

## ⚠️ Dépannage

### Erreur : "Connection refused" sur port 11434

**Cause :** Ollama n'est pas lance ou ecoute sur une autre interface.

**Solution :**
```bash
pkill ollama && OLLAMA_HOST=0.0.0.0 ollama serve
```

---

### Erreur : "Model not found"

**Cause :** Le modele specifie n'est pas telecharge.

**Solution :**
```bash
ollama list
ollama pull nom-du-modele
```

---

### Erreur : "Timeout" sur les gros modeles

**Cause :** Le chargement initial des modeles 70B+ prend du temps.

**Solution :**

Augmente le timeout dans la configuration :

```json
{
  "providers": {
    "ollama": {
      "timeout": 300000
    }
  }
}
```

---

### LM Studio ne repond pas

**Cause :** Le serveur local n'est pas demarre.

**Solution :**
1. Ouvre LM Studio
2. Va dans **Local Server**
3. Clique sur **Start Server**
4. Verifie le port affiche

---

### Performances degradees

**Cause :** Le GPU Metal n'est pas utilise.

**Solution :**
```bash
echo 'export OLLAMA_NUM_GPU=999' >> ~/.zshrc && source ~/.zshrc && ollama serve
```

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| Documentation Ollama | https://ollama.ai/docs |
| API Ollama | https://github.com/ollama/ollama/blob/main/docs/api.md |
| LM Studio | https://lmstudio.ai |
| Modeles compatibles | https://ollama.ai/library |
| Phoenix Providers | https://docs.phoenix.ai/providers |

---

## ➡️ Prochaine étape

Maintenant que tes LLM locaux sont connectes, tu vas configurer les **channels de messagerie** (WhatsApp, Telegram, Discord) dans le chapitre suivant : [4.2 - Channels de Messagerie](./02-channels-messagerie.md).
