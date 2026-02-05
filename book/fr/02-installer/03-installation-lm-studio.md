# 🎯 2.3 - Installation LM Studio NATIF

## 📋 Ce que tu vas apprendre
- Comment installer LM Studio sur macOS
- Comment télécharger des modèles depuis l'interface graphique
- Comment configurer le serveur API local
- Comment connecter LM Studio à OpenClaw

## 🛠️ Prérequis
- Chapitre 2.1 complété (outils de base installés)
- Chapitre 2.2 complété (Ollama installé - optionnel mais recommandé)
- Mac Studio M3 Ultra avec au moins 64 GB de RAM
- Environ 50 GB d'espace disque libre

## 📝 Étapes détaillées

### Étape 1 : Télécharger LM Studio

**Pourquoi ?** LM Studio offre une interface graphique facile pour gérer et tester des modèles d'IA. C'est parfait pour expérimenter avant de choisir un modèle pour OpenClaw.

**Comment ?**
1. Ouvre Safari ou ton navigateur
2. Va sur : https://lmstudio.ai/
3. Clique sur "Download for Mac"
4. Sélectionne "Apple Silicon" (pour M1/M2/M3)
5. Attends le téléchargement (environ 400 MB)

**Vérification :**
Le fichier `LM-Studio-x.x.x-arm64.dmg` doit être dans ton dossier Téléchargements.

---

### Étape 2 : Installer LM Studio

**Pourquoi ?** On va installer l'application dans le dossier Applications pour pouvoir la lancer facilement.

**Comment ?**
1. Double-clique sur le fichier `LM-Studio-x.x.x-arm64.dmg`
2. Une fenêtre s'ouvre avec l'icône LM Studio
3. Glisse l'icône LM Studio vers le dossier Applications
4. Attends la copie (quelques secondes)
5. Éjecte le disque LM Studio (clic droit > Éjecter)

**Premier lancement :**
1. Ouvre le dossier Applications
2. Double-clique sur "LM Studio"
3. macOS peut te demander confirmation : clique sur "Ouvrir"
4. Accepte les conditions d'utilisation

**Vérification :**
LM Studio s'ouvre avec un écran d'accueil.

---

### Étape 3 : Configurer les paramètres de base

**Pourquoi ?** On va configurer LM Studio pour utiliser au mieux le GPU M3 Ultra.

**Comment ?**
1. Dans LM Studio, clique sur l'icône ⚙️ (Paramètres) en bas à gauche
2. Va dans l'onglet "Runtime"
3. Configure ces paramètres :

**Paramètres GPU :**
- **GPU Acceleration :** Activé (ON)
- **GPU Layers :** Maximum (mettre 999 ou la valeur max proposée)
- **Metal :** Activé (ON)

**Paramètres mémoire :**
- **Context Length :** 8192 (ou 4096 si tu manques de RAM)
- **Max Tokens :** 2048

**Paramètres serveur (onglet "Local Server") :**
- **Port :** 1234
- **CORS :** Activé (ON)
- **Verbose Logging :** Désactivé (OFF) pour de meilleures performances

4. Clique sur "Save" ou ferme la fenêtre (les changements sont automatiques)

**Vérification :**
Les paramètres sont sauvegardés automatiquement.

---

### Étape 4 : Télécharger un modèle depuis l'interface

**Pourquoi ?** LM Studio a un moteur de recherche intégré pour trouver et télécharger des modèles facilement.

**Comment ?**
1. Clique sur l'icône 🔍 (Discover) dans la barre latérale gauche
2. Dans la barre de recherche, tape : `llama 3.1 8b`
3. Trouve un modèle avec le tag "Q4_K_M" ou "Q5_K_M" (bon équilibre taille/qualité)
4. Clique sur le bouton "Download" à côté du modèle

**Modèles recommandés pour commencer :**

| Modèle | Taille | Usage |
|--------|--------|-------|
| `TheBloke/Llama-2-7B-Chat-GGUF` | ~4 GB | Chat rapide |
| `lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF` | ~5 GB | Usage général |
| `TheBloke/CodeLlama-13B-Instruct-GGUF` | ~7 GB | Programmation |
| `lmstudio-community/Meta-Llama-3.1-70B-Instruct-GGUF` | ~40 GB | Haute qualité |

**Pour télécharger Llama 3.1 8B :**
1. Recherche : `lmstudio-community Meta-Llama-3.1-8B-Instruct`
2. Sélectionne la version `Q4_K_M` (environ 5 GB)
3. Clique sur "Download"
4. Attends la fin du téléchargement (5-20 minutes selon ta connexion)

**Vérification :**
Le modèle apparaît dans la section "My Models" (icône 📁).

---

### Étape 5 : Charger et tester un modèle

**Pourquoi ?** On veut vérifier que le modèle fonctionne correctement avec le GPU.

**Comment ?**
1. Clique sur l'icône 💬 (Chat) dans la barre latérale
2. En haut, clique sur "Select a model to load"
3. Sélectionne le modèle que tu as téléchargé
4. Attends le chargement (quelques secondes à quelques minutes selon la taille)

**Premier test :**
1. Dans la zone de texte en bas, tape : `Bonjour, qui es-tu ?`
2. Appuie sur Entrée ou clique sur Envoyer
3. Attends la réponse

**Vérification :**
- Tu dois recevoir une réponse en quelques secondes
- Regarde en bas de la fenêtre : tu devrais voir "Metal" ou "GPU" indiqué

**Observer les performances :**
- En haut à droite, tu vois la vitesse (tokens/seconde)
- Sur M3 Ultra, tu devrais avoir 30-100+ tokens/s selon le modèle

---

### Étape 6 : Démarrer le serveur API local

**Pourquoi ?** Pour qu'OpenClaw puisse utiliser LM Studio, on doit activer le serveur API qui écoute sur le port 1234.

**Comment ?**
1. Clique sur l'icône 🔌 (Local Server) dans la barre latérale gauche
2. Vérifie que le port est bien 1234
3. Clique sur "Start Server"
4. Le bouton devient vert et affiche "Server Running"

**Configuration CORS (important pour OpenClaw) :**
1. Dans les paramètres du serveur, active "Enable CORS"
2. Cela permet à OpenClaw d'accéder au serveur depuis le navigateur

**Vérification en Terminal :**
```bash
curl -s http://localhost:1234/v1/models | jq .
```

**Résultat attendu :**
```json
{
  "object": "list",
  "data": [
    {
      "id": "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF",
      "object": "model",
      "created": 1234567890,
      "owned_by": "lmstudio"
    }
  ]
}
```

---

### Étape 7 : Tester l'API compatible OpenAI

**Pourquoi ?** LM Studio expose une API compatible avec OpenAI. OpenClaw peut l'utiliser comme s'il parlait à GPT-4.

**Comment ?**
```bash
curl -s http://localhost:1234/v1/chat/completions -H "Content-Type: application/json" -d '{"model": "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF", "messages": [{"role": "user", "content": "Dis bonjour en une phrase"}], "max_tokens": 50}' | jq -r '.choices[0].message.content'
```

**Résultat attendu :**
```
Bonjour ! Je suis ravi de vous rencontrer.
```

**Test avec stream (réponse progressive) :**
```bash
curl -N http://localhost:1234/v1/chat/completions -H "Content-Type: application/json" -d '{"model": "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF", "messages": [{"role": "user", "content": "Compte de 1 à 5"}], "stream": true}'
```

---

### Étape 8 : Configurer LM Studio pour démarrer avec le serveur

**Pourquoi ?** On veut que le serveur démarre automatiquement quand on ouvre LM Studio.

**Comment ?**
1. Clique sur ⚙️ (Paramètres)
2. Va dans l'onglet "Local Server"
3. Active "Start server on launch"
4. Active "Load last used model on launch"

**Configurer LM Studio au démarrage du Mac :**
1. Ouvre "Préférences Système"
2. Va dans "Général" > "Ouverture"
3. Clique sur "+"
4. Sélectionne "LM Studio" dans Applications
5. Clique sur "Ajouter"

**Vérification :**
Redémarre LM Studio et vérifie que le serveur démarre automatiquement.

---

### Étape 9 : Comparer les performances Ollama vs LM Studio

**Pourquoi ?** Les deux outils peuvent faire tourner les mêmes modèles. On va voir lequel est le plus rapide pour ton usage.

**Script de comparaison :**
```bash
cat << 'EOF' > ~/openclaw/compare-backends.sh
#!/bin/bash
echo "=== Comparaison Ollama vs LM Studio ==="
echo ""

PROMPT="Écris une liste de 5 fruits"

# Test Ollama
echo "1. Test Ollama (port 11434)..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    START=$(python3 -c "import time; print(int(time.time()*1000))")
    curl -s http://localhost:11434/api/generate -d "{\"model\": \"llama3.2:3b\", \"prompt\": \"$PROMPT\", \"stream\": false}" > /dev/null
    END=$(python3 -c "import time; print(int(time.time()*1000))")
    echo "   ✅ Ollama: $((END-START))ms"
else
    echo "   ❌ Ollama non disponible"
fi

# Test LM Studio
echo ""
echo "2. Test LM Studio (port 1234)..."
if curl -s http://localhost:1234/v1/models > /dev/null 2>&1; then
    MODEL=$(curl -s http://localhost:1234/v1/models | jq -r '.data[0].id')
    START=$(python3 -c "import time; print(int(time.time()*1000))")
    curl -s http://localhost:1234/v1/chat/completions -H "Content-Type: application/json" -d "{\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}], \"max_tokens\": 100}" > /dev/null
    END=$(python3 -c "import time; print(int(time.time()*1000))")
    echo "   ✅ LM Studio: $((END-START))ms"
else
    echo "   ❌ LM Studio non disponible"
fi

echo ""
echo "=== Comparaison terminée ==="
EOF
chmod +x ~/openclaw/compare-backends.sh
```

**Exécuter la comparaison :**
```bash
~/openclaw/compare-backends.sh
```

---

### Étape 10 : Configuration pour OpenClaw

**Pourquoi ?** On prépare les paramètres que OpenClaw utilisera pour se connecter à LM Studio.

**Créer le fichier de configuration :**
```bash
cat << 'EOF' > ~/openclaw/config/lm-studio.json
{
  "name": "LM Studio Local",
  "type": "openai-compatible",
  "baseURL": "http://localhost:1234/v1",
  "apiKey": "lm-studio",
  "models": {
    "default": "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF",
    "code": "TheBloke/CodeLlama-13B-Instruct-GGUF",
    "fast": "TheBloke/Llama-2-7B-Chat-GGUF"
  },
  "settings": {
    "temperature": 0.7,
    "maxTokens": 2048,
    "contextLength": 8192
  }
}
EOF
```

**Vérification :**
```bash
cat ~/openclaw/config/lm-studio.json | jq .
```

---

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] LM Studio est installé dans Applications
- [ ] Au moins un modèle est téléchargé
- [ ] Le modèle se charge et répond dans le chat
- [ ] Le GPU Metal est utilisé (visible en bas de la fenêtre)
- [ ] Le serveur local est démarré sur le port 1234
- [ ] L'API répond correctement (test curl)
- [ ] Le serveur est configuré pour démarrer automatiquement
- [ ] Le fichier de configuration pour OpenClaw est créé

---

## ⚠️ Dépannage

### LM Studio ne démarre pas
**Symptôme :** L'application se ferme immédiatement
**Solution :**
```bash
rm -rf ~/Library/Application\ Support/LMStudio && rm -rf ~/Library/Caches/LMStudio
```
Puis relance LM Studio.

### Le modèle ne se charge pas
**Symptôme :** Erreur "Failed to load model"
**Solutions :**
1. Vérifie que tu as assez de RAM libre
2. Essaie un modèle plus petit (Q4 au lieu de Q8)
3. Ferme d'autres applications gourmandes

### Le serveur ne répond pas sur le port 1234
**Symptôme :** Connection refused
**Solutions :**
1. Vérifie que le serveur est bien démarré (bouton vert)
2. Vérifie qu'aucune autre application n'utilise le port :
```bash
lsof -i :1234
```
3. Change le port dans les paramètres si nécessaire

### Performances lentes (moins de 10 tokens/seconde)
**Symptôme :** Génération très lente
**Solutions :**
1. Vérifie que "Metal" est activé dans les paramètres
2. Utilise un modèle quantifié (Q4_K_M ou Q5_K_M)
3. Réduis le "Context Length" à 4096
4. Ferme le navigateur et autres apps gourmandes

### Erreur "Out of memory"
**Symptôme :** Crash ou erreur de mémoire
**Solutions :**
1. Utilise un modèle plus petit
2. Réduis "GPU Layers" à 32 ou moins
3. Ferme d'autres applications
```bash
# Voir la mémoire utilisée
top -l 1 | grep PhysMem
```

### Le modèle donne des réponses incohérentes
**Symptôme :** Réponses bizarres ou répétitives
**Solutions :**
1. Ajuste la température (0.7 est un bon défaut)
2. Essaie un modèle de meilleure qualité (Q5 au lieu de Q4)
3. Vérifie que "repeat_penalty" est activé

---

## 🔗 Ressources

- [Site officiel LM Studio](https://lmstudio.ai/)
- [Documentation LM Studio](https://lmstudio.ai/docs)
- [Hugging Face Models](https://huggingface.co/models) - Source des modèles
- [TheBloke sur Hugging Face](https://huggingface.co/TheBloke) - Modèles quantifiés populaires
- [Guide des formats GGUF](https://github.com/ggerganov/llama.cpp/blob/master/gguf-py/README.md)

---

## 📊 Comparaison Ollama vs LM Studio

| Aspect | Ollama | LM Studio |
|--------|--------|-----------|
| **Interface** | Terminal | Graphique |
| **API** | Format propre + OpenAI | Format OpenAI |
| **Port par défaut** | 11434 | 1234 |
| **Gestion modèles** | `ollama pull` | Interface graphique |
| **Personnalisation** | Modelfiles | Paramètres GUI |
| **Usage mémoire** | Légèrement plus bas | Légèrement plus haut |
| **Idéal pour** | Production, scripts | Tests, expérimentation |

**Recommandation pour OpenClaw :**
- Utilise **Ollama** pour la production (plus stable, plus léger)
- Utilise **LM Studio** pour tester de nouveaux modèles avant de les adopter

---

## ➡️ Prochaine étape

LM Studio est installé et configuré ! Tu as maintenant deux backends d'IA locaux qui fonctionnent. Dans le prochain chapitre, on va installer **k3s**, la version légère de Kubernetes qui va orchestrer tous nos conteneurs.

**Chapitre suivant :** [2.4 - Installation k3s sur macOS](./04-installation-k3s.md)
