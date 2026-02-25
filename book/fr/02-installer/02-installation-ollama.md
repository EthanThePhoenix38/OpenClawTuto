# 🎯 2.2 - Installation Ollama NATIF avec config GPU M3

## 📋 Ce que tu vas apprendre
- Comment installer Ollama nativement sur macOS (pas dans Docker)
- Comment configurer Ollama pour utiliser tout le GPU du M3 Ultra
- Comment télécharger et tester ton premier modèle IA
- Comment vérifier que le GPU est bien utilisé

## 🛠️ Prérequis
- Chapitre 2.1 complété (tous les outils installés)
- Mac Studio M3 Ultra avec au moins 64 GB de RAM
- Connexion Internet (pour télécharger les modèles)

## 📝 Étapes détaillées

### Étape 1 : Télécharger et installer Ollama

**Pourquoi ?** Ollama est le serveur qui va faire tourner les modèles d'IA. On l'installe en NATIF (pas dans Docker) pour qu'il puisse utiliser directement le GPU Metal du M3 Ultra.

**Comment ?**
1. Ouvre Safari ou ton navigateur
2. Va sur : https://ollama.ai/download
3. Clique sur "Download for macOS"
4. Ouvre le fichier Ollama-darwin.zip téléchargé
5. Glisse l'application Ollama dans le dossier Applications
6. Ouvre Ollama depuis le dossier Applications
7. Clique sur "Ouvrir" si macOS te demande confirmation

**Alternative avec Homebrew :**
```bash
brew install ollama
```

**Vérification :**
```bash
ollama --version
```

**Résultat attendu :**
```
ollama version 0.x.x
```

---

### Étape 2 : Démarrer le serveur Ollama

**Pourquoi ?** Le serveur Ollama doit tourner en arrière-plan pour répondre aux requêtes d'Phoenix.

**Comment (GUI) :**
1. Ouvre l'application Ollama depuis Applications
2. Une icône de lama apparaît dans la barre de menu en haut
3. Ollama démarre automatiquement son serveur

**Comment (Terminal) :**
```bash
ollama serve &
```

**Vérification :**
```bash
curl -s http://localhost:11434/api/tags | jq .
```

**Résultat attendu :**
```json
{
  "models": []
}
```

C'est normal que la liste soit vide, on n'a pas encore téléchargé de modèle !

---

### Étape 3 : Configurer Ollama pour le M3 Ultra

**Pourquoi ?** Par défaut, Ollama fonctionne bien, mais on peut l'optimiser pour mieux utiliser les 24 coeurs du M3 Ultra.

**Comment ?**
1. Crée le fichier de configuration :

```bash
mkdir -p ~/.ollama && cat << 'EOF' > ~/.ollama/config.json
{
  "gpu": true,
  "num_gpu": 999,
  "num_thread": 16,
  "num_ctx": 8192,
  "num_batch": 512
}
EOF
```

**Explication des paramètres :**
- `gpu: true` : Active l'utilisation du GPU Metal
- `num_gpu: 999` : Utilise tous les coeurs GPU disponibles
- `num_thread: 16` : Utilise 16 threads CPU (laisse 8 pour le système)
- `num_ctx: 8192` : Taille du contexte (mémoire de conversation)
- `num_batch: 512` : Taille des lots pour le traitement

**Configuration des variables d'environnement :**
```bash
cat << 'EOF' >> ~/.zprofile
# Configuration Ollama pour M3 Ultra
export OLLAMA_HOST="127.0.0.1:11434"
export OLLAMA_KEEP_ALIVE="24h"
export OLLAMA_NUM_PARALLEL="4"
export OLLAMA_MAX_LOADED_MODELS="3"
export OLLAMA_FLASH_ATTENTION="1"
EOF
source ~/.zprofile
```

**Explication :**
- `OLLAMA_HOST` : Adresse d'écoute (localhost seulement pour la sécurité)
- `OLLAMA_KEEP_ALIVE` : Garde les modèles en mémoire 24h
- `OLLAMA_NUM_PARALLEL` : Permet 4 requêtes simultanées
- `OLLAMA_MAX_LOADED_MODELS` : Maximum 3 modèles en mémoire
- `OLLAMA_FLASH_ATTENTION` : Active l'attention flash (plus rapide)

**Redémarrer Ollama pour appliquer :**
1. Clique sur l'icône Ollama dans la barre de menu
2. Clique sur "Quit Ollama"
3. Réouvre Ollama depuis Applications

**Vérification :**
```bash
echo "OLLAMA_HOST: $OLLAMA_HOST" && echo "OLLAMA_KEEP_ALIVE: $OLLAMA_KEEP_ALIVE"
```

---

### Étape 4 : Télécharger un modèle de test

**Pourquoi ?** On va télécharger un petit modèle pour vérifier que tout fonctionne avant d'installer les gros.

**Comment ?**
```bash
ollama pull llama3.2:3b
```

**Ce qui va se passer :**
- Téléchargement d'environ 2 GB
- Extraction automatique
- Le modèle sera prêt à l'emploi

**Temps estimé :** 1-5 minutes selon ta connexion.

**Vérification :**
```bash
ollama list
```

**Résultat attendu :**
```
NAME            ID              SIZE    MODIFIED
llama3.2:3b     a80c4f17acd5    2.0 GB  Just now
```

---

### Étape 5 : Tester le modèle

**Pourquoi ?** On vérifie que le modèle fonctionne et utilise bien le GPU.

**Comment ?**
```bash
ollama run llama3.2:3b "Dis bonjour en une phrase"
```

**Résultat attendu :**
Une réponse en quelques secondes, par exemple :
```
Bonjour ! Je suis ravi de vous rencontrer.
```

**Test via l'API (comme Phoenix va l'utiliser) :**
```bash
curl -s http://localhost:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "Réponds en un mot: 2+2=", "stream": false}' | jq -r '.response'
```

**Résultat attendu :**
```
4
```

---

### Étape 6 : Vérifier l'utilisation du GPU

**Pourquoi ?** On veut être sûr que le M3 Ultra travaille avec son GPU, pas juste le CPU.

**Comment ?**
1. Ouvre "Moniteur d'activité" (Cmd + Espace, tape "Moniteur", Entrée)
2. Clique sur l'onglet "GPU"
3. Pendant qu'Ollama génère du texte, tu dois voir de l'activité

**Test en ligne de commande :**
```bash
sudo powermetrics --samplers gpu_power -i 1000 -n 1 2>/dev/null | grep -E "GPU|Power"
```

**Pendant un test avec Ollama (dans un autre terminal) :**
```bash
ollama run llama3.2:3b "Écris un poème de 10 lignes sur la technologie"
```

**Ce que tu dois voir :**
L'utilisation GPU doit augmenter pendant la génération.

---

### Étape 7 : Télécharger les modèles recommandés pour Phoenix

**Pourquoi ?** Phoenix fonctionne mieux avec certains modèles. On va télécharger ceux recommandés.

**Modèle principal - Llama 3.1 70B (nécessite 64+ GB RAM) :**
```bash
ollama pull llama3.1:70b
```
**Taille :** ~40 GB - **Temps :** 20-60 minutes

**Modèle alternatif - Llama 3.1 8B (pour moins de RAM) :**
```bash
ollama pull llama3.1:8b
```
**Taille :** ~4.7 GB - **Temps :** 2-10 minutes

**Modèle de code - CodeLlama 34B :**
```bash
ollama pull codellama:34b
```
**Taille :** ~19 GB - **Temps :** 10-30 minutes

**Modèle pour embeddings :**
```bash
ollama pull nomic-embed-text
```
**Taille :** ~274 MB - **Temps :** 1 minute

**Vérification de tous les modèles :**
```bash
ollama list
```

**Résultat attendu :**
```
NAME                ID              SIZE      MODIFIED
llama3.1:70b        xxxxx           40 GB     x minutes ago
llama3.1:8b         xxxxx           4.7 GB    x minutes ago
codellama:34b       xxxxx           19 GB     x minutes ago
nomic-embed-text    xxxxx           274 MB    x minutes ago
llama3.2:3b         xxxxx           2.0 GB    x minutes ago
```

---

### Étape 8 : Créer un Modelfile personnalisé pour Phoenix

**Pourquoi ?** On peut créer un modèle personnalisé avec des paramètres optimisés pour Phoenix.

**Comment ?**
```bash
cat << 'EOF' > ~/phoenix/config/Modelfile.phoenix
FROM llama3.1:8b

# Paramètres optimisés pour Phoenix
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 8192
PARAMETER repeat_penalty 1.1

# Prompt système pour Phoenix
SYSTEM """Tu es un assistant IA intégré à Phoenix, une plateforme de développement sécurisée. Tu aides les développeurs avec leur code, leurs questions techniques et leurs projets. Tu réponds toujours en français quand on te parle en français. Tu es précis, concis et professionnel."""
EOF
```

**Créer le modèle personnalisé :**
```bash
ollama create phoenix-assistant -f ~/phoenix/config/Modelfile.phoenix
```

**Vérification :**
```bash
ollama list | grep phoenix
```

**Résultat attendu :**
```
phoenix-assistant    xxxxx    4.7 GB    Just now
```

**Tester le modèle personnalisé :**
```bash
ollama run phoenix-assistant "Qui es-tu ?"
```

---

### Étape 9 : Configurer Ollama pour démarrer automatiquement

**Pourquoi ?** On veut qu'Ollama démarre tout seul quand le Mac s'allume.

**Comment (GUI) :**
1. Ouvre "Préférences Système" > "Général" > "Ouverture"
2. Clique sur "+"
3. Sélectionne "Ollama" dans Applications
4. Clique sur "Ajouter"

**Comment (Terminal) :**
```bash
cat << 'EOF' > ~/Library/LaunchAgents/com.ollama.server.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/ollama.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/ollama.error.log</string>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.ollama.server.plist
```

**Vérification :**
```bash
launchctl list | grep ollama
```

---

### Étape 10 : Script de test complet

**Pourquoi ?** Un script qui teste tout d'un coup pour être sûr que tout marche.

**Comment ?**
```bash
cat << 'EOF' > ~/phoenix/test-ollama.sh
#!/bin/bash
echo "=== Test Ollama pour Phoenix ==="
echo ""

# Test 1: Serveur actif
echo "1. Vérification du serveur..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "   ✅ Serveur Ollama actif sur le port 11434"
else
    echo "   ❌ Serveur Ollama non accessible"
    exit 1
fi

# Test 2: Modèles installés
echo ""
echo "2. Modèles installés :"
ollama list | while read line; do echo "   $line"; done

# Test 3: Test de génération
echo ""
echo "3. Test de génération rapide..."
RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "Réponds seulement OK", "stream": false}' | jq -r '.response' 2>/dev/null)
if [[ "$RESPONSE" == *"OK"* ]] || [[ -n "$RESPONSE" ]]; then
    echo "   ✅ Génération fonctionne"
    echo "   Réponse: $RESPONSE"
else
    echo "   ❌ Problème de génération"
fi

# Test 4: Temps de réponse
echo ""
echo "4. Test de performance..."
START=$(date +%s%N)
curl -s http://localhost:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "1+1=", "stream": false}' > /dev/null
END=$(date +%s%N)
DURATION=$(( (END - START) / 1000000 ))
echo "   Temps de réponse: ${DURATION}ms"

echo ""
echo "=== Tests terminés ==="
EOF
chmod +x ~/phoenix/test-ollama.sh
```

**Exécuter les tests :**
```bash
~/phoenix/test-ollama.sh
```

**Résultat attendu :**
```
=== Test Ollama pour Phoenix ===

1. Vérification du serveur...
   ✅ Serveur Ollama actif sur le port 11434

2. Modèles installés :
   NAME                ID              SIZE      MODIFIED
   llama3.1:8b         xxxxx           4.7 GB    x minutes ago
   llama3.2:3b         xxxxx           2.0 GB    x minutes ago

3. Test de génération rapide...
   ✅ Génération fonctionne
   Réponse: OK

4. Test de performance...
   Temps de réponse: 1234ms

=== Tests terminés ===
```

---

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] Ollama est installé (version 0.x.x ou plus)
- [ ] Le serveur Ollama tourne sur le port 11434
- [ ] Les variables d'environnement sont configurées
- [ ] Au moins un modèle est téléchargé (llama3.2:3b minimum)
- [ ] Le test de génération fonctionne
- [ ] Le GPU est utilisé pendant la génération
- [ ] Ollama est configuré pour démarrer automatiquement
- [ ] Le script de test passe sans erreur

---

## ⚠️ Dépannage

### Ollama ne démarre pas
**Symptôme :** L'application se ferme immédiatement
**Solution :**
```bash
rm -rf ~/.ollama/logs && rm -rf ~/.ollama/*.pid && open -a Ollama
```

### Le port 11434 est déjà utilisé
**Symptôme :** "address already in use"
**Solution :**
```bash
lsof -i :11434 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

### Le modèle ne se télécharge pas
**Symptôme :** Erreur de connexion ou timeout
**Solution :**
```bash
export OLLAMA_ORIGINS="*" && ollama pull llama3.2:3b
```

### La génération est très lente (>30 secondes)
**Symptôme :** Le modèle met trop de temps à répondre
**Solution :** Vérifie que le GPU est utilisé :
```bash
sudo powermetrics --samplers gpu_power -i 1000 -n 3
```
Si le GPU n'est pas actif, redémarre Ollama.

### "Not enough memory"
**Symptôme :** Erreur de mémoire insuffisante
**Solution :** Utilise un modèle plus petit ou ferme d'autres applications :
```bash
ollama stop llama3.1:70b && ollama run llama3.1:8b "test"
```

### Les modèles disparaissent après redémarrage
**Symptôme :** `ollama list` est vide
**Solution :** Les modèles sont stockés dans ~/.ollama/models. Vérifie :
```bash
ls -la ~/.ollama/models/
```

---

## 🔗 Ressources

- [Documentation officielle Ollama](https://ollama.ai/docs)
- [Liste des modèles Ollama](https://ollama.ai/library)
- [API Ollama](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Optimisation GPU Apple Silicon](https://github.com/ollama/ollama/blob/main/docs/gpu.md)
- [Modelfile Reference](https://github.com/ollama/ollama/blob/main/docs/modelfile.md)

---

## ➡️ Prochaine étape

Ollama est installé et optimisé pour ton M3 Ultra ! Dans le prochain chapitre, on va installer **LM Studio**, une interface graphique qui permet de tester et comparer facilement différents modèles.

**Chapitre suivant :** [2.3 - Installation LM Studio NATIF](./03-installation-lm-studio.md)
