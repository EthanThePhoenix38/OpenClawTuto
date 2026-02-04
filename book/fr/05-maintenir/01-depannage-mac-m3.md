# 🎯 5.1 - Dépannage Mac M3 Complet

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas maitriser le depannage d'OpenClaw sur Mac Studio M3 Ultra. Tu apprendras a diagnostiquer et resoudre les problemes courants lies au systeme, a Docker, aux LLM et aux performances.

**Objectifs :**
- Diagnostiquer les problemes systematiquement
- Resoudre les erreurs Docker sur Apple Silicon
- Corriger les problemes de LLM locaux
- Optimiser les performances degradees
- Recuperer d'un crash systeme

---

## 🛠️ Prérequis

| Composant | Requis | Verification |
|-----------|--------|--------------|
| Acces Terminal | Admin | `whoami` |
| Docker Desktop | Installe | `docker --version` |
| OpenClaw | Installe | `ls ~/.openclaw` |
| Logs accessibles | - | `docker logs openclaw-gateway` |

---

## 📝 Étapes détaillées

### Étape 1 : Diagnostic initial systematique

**Pourquoi ?**
Un diagnostic methodique permet d'identifier rapidement la source du probleme. Commence toujours par verifier les composants de base avant d'aller plus loin.

**Comment ?**

Execute le script de diagnostic complet :

```bash
echo "=== Diagnostic OpenClaw ===" && echo "Date: $(date)" && echo "" && echo "=== Systeme ===" && sw_vers && echo "" && echo "=== Docker ===" && docker version --format '{{.Server.Version}}' && echo "" && echo "=== Conteneurs ===" && docker ps -a --filter "name=openclaw" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" && echo "" && echo "=== Gateway Health ===" && curl -s http://localhost:18789/api/health | jq '.status' 2>/dev/null || echo "Gateway non accessible" && echo "" && echo "=== Ollama ===" && curl -s http://localhost:11434/api/tags | jq '.models[].name' 2>/dev/null || echo "Ollama non accessible" && echo "" && echo "=== Ressources ===" && top -l 1 | head -10 && echo "" && echo "=== Espace disque ===" && df -h /
```

**Vérification :**

Compare les resultats avec l'etat normal :
- Docker version : 24.0+
- Conteneurs : tous "Up"
- Gateway : "status": "healthy"
- Ollama : liste des modeles
- CPU : < 80% en idle
- Disque : > 20% libre

---

### Étape 2 : Problemes Docker sur Apple Silicon

**Pourquoi ?**
Docker sur Mac M3 utilise une VM Linux. Certains problemes sont specifiques a l'architecture ARM64 et a la virtualisation.

**Comment ?**

**Probleme : Docker Desktop ne demarre pas**

```bash
killall Docker && sleep 5 && open -a Docker
```

Si ca persiste, reset Docker Desktop :

```bash
rm -rf ~/Library/Group\ Containers/group.com.docker && rm -rf ~/Library/Containers/com.docker.docker && rm -rf ~/.docker && open -a Docker
```

**Probleme : "image platform does not match"**

Force l'architecture ARM64 :

```bash
docker pull --platform linux/arm64 image:tag
```

Ou ajoute dans `~/.docker/config.json` :

```json
{
  "experimental": "enabled",
  "features": {
    "buildkit": true
  }
}
```

**Probleme : "Cannot connect to Docker daemon"**

```bash
docker context use default && sudo launchctl stop com.docker.dockerd && sudo launchctl start com.docker.dockerd
```

**Probleme : Conteneur restart en boucle**

Verifie les logs :

```bash
docker logs openclaw-gateway --tail 100
```

Causes frequentes :
- Port deja utilise
- Fichier de config corrompu
- Permissions incorrectes

**Vérification :**
```bash
docker run --rm hello-world
```

---

### Étape 3 : Problemes de LLM locaux

**Pourquoi ?**
Ollama et LM Studio peuvent avoir des problemes de chargement de modeles, de memoire ou de communication avec le gateway.

**Comment ?**

**Probleme : Ollama ne repond pas**

Verifie le processus :

```bash
pgrep -l ollama
```

Relance si absent :

```bash
ollama serve &
```

**Probleme : "Model not found"**

Liste les modeles disponibles :

```bash
ollama list
```

Telecharge le modele manquant :

```bash
ollama pull llama3.2:8b
```

**Probleme : "Out of memory"**

Les modeles 70B+ necessitent beaucoup de RAM. Verifie l'utilisation :

```bash
memory_pressure
```

Solutions :
1. Utilise un modele plus petit
2. Ferme les applications gourmandes
3. Reduis le contexte :

```bash
ollama run llama3.2:8b --num-ctx 2048
```

**Probleme : GPU Metal non utilise**

Verifie la configuration :

```bash
echo $OLLAMA_NUM_GPU
```

Configure si manquant :

```bash
export OLLAMA_NUM_GPU=999 && ollama serve
```

**Probleme : LM Studio non accessible**

Verifie le serveur :

```bash
curl http://localhost:1234/v1/models
```

Dans LM Studio :
1. Va dans **Local Server**
2. Verifie que le serveur est "Running"
3. Note le port affiche

**Vérification :**
```bash
curl -X POST http://localhost:11434/api/generate -d '{"model":"llama3.2:8b","prompt":"Test","stream":false}' | jq '.response'
```

---

### Étape 4 : Problemes de performance

**Pourquoi ?**
Le Mac Studio M3 Ultra est puissant mais peut etre ralenti par une mauvaise configuration, des fuites memoire ou des processus parasites.

**Comment ?**

**Diagnostic performance :**

```bash
echo "=== CPU ===" && top -l 1 -s 0 | grep "CPU usage" && echo "" && echo "=== Memoire ===" && vm_stat | head -5 && echo "" && echo "=== Processus gourmands ===" && ps aux | sort -nrk 3,3 | head -5 && echo "" && echo "=== GPU Metal ===" && sudo powermetrics --samplers gpu_power -i 1000 -n 1 2>/dev/null | grep "GPU" || echo "Requires sudo"
```

**Probleme : CPU a 100%**

Identifie le coupable :

```bash
top -o cpu
```

Si c'est Ollama ou Docker, verifie les requetes en cours :

```bash
docker stats --no-stream
```

**Probleme : Memoire saturee**

Verifie la pression memoire :

```bash
memory_pressure
```

Libere la memoire :

```bash
sudo purge
```

Reduis le cache Docker :

```bash
docker system prune -a --volumes
```

**Probleme : Reponses LLM lentes**

Verifie le taux d'inference :

```bash
ollama run llama3.2:8b "Test rapide" --verbose 2>&1 | grep "eval rate"
```

Valeurs normales sur M3 Ultra :
- 7B modele : 50+ tokens/s
- 13B modele : 30+ tokens/s
- 70B modele : 10+ tokens/s

Si trop lent, verifie que Metal est actif :

```bash
OLLAMA_NUM_GPU=999 ollama run llama3.2:8b "Test" --verbose
```

**Vérification :**
```bash
docker exec openclaw-gateway openclaw benchmark --quick
```

---

### Étape 5 : Problemes de configuration

**Pourquoi ?**
Un fichier de configuration corrompu ou mal forme peut empecher OpenClaw de demarrer ou de fonctionner correctement.

**Comment ?**

**Valide la configuration JSON :**

```bash
cat ~/.openclaw/openclaw.json | jq . > /dev/null && echo "JSON valide" || echo "JSON invalide"
```

**Sauvegarde et reset :**

```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup && docker exec openclaw-gateway openclaw config init --force
```

**Probleme : "Permission denied"**

Corrige les permissions :

```bash
chmod 755 ~/.openclaw && chmod 644 ~/.openclaw/*.json && chmod -R 755 ~/.openclaw/skills
```

**Probleme : "Port already in use"**

Trouve le processus :

```bash
lsof -i :18789
```

Tue-le si necessaire :

```bash
kill -9 $(lsof -t -i :18789)
```

**Probleme : Variables d'environnement manquantes**

Verifie :

```bash
docker exec openclaw-gateway env | grep -E "OPENCLAW|OLLAMA"
```

Ajoute dans le docker-compose ou la commande run :

```bash
docker run -e OLLAMA_HOST=host.docker.internal:11434 ...
```

**Vérification :**
```bash
docker exec openclaw-gateway openclaw config validate
```

---

### Étape 6 : Recuperation apres crash

**Pourquoi ?**
Un crash systeme peut laisser OpenClaw dans un etat inconsistant. Une procedure de recuperation methodique evite la perte de donnees.

**Comment ?**

**Procedure de recuperation complete :**

1. Arrete tout proprement :

```bash
docker stop $(docker ps -aq --filter "name=openclaw") 2>/dev/null && docker rm $(docker ps -aq --filter "name=openclaw") 2>/dev/null
```

2. Verifie l'integrite des volumes :

```bash
docker volume ls --filter "name=openclaw"
```

3. Sauvegarde les donnees critiques :

```bash
mkdir -p ~/openclaw-backup-$(date +%Y%m%d) && cp -r ~/.openclaw ~/openclaw-backup-$(date +%Y%m%d)/
```

4. Nettoie Docker :

```bash
docker system prune -f && docker volume prune -f
```

5. Redemarre OpenClaw :

```bash
docker-compose -f ~/.openclaw/docker-compose.yml up -d
```

6. Verifie le statut :

```bash
sleep 10 && curl http://localhost:18789/api/health | jq
```

**Recuperation des logs apres crash :**

```bash
docker logs openclaw-gateway --since 1h > ~/openclaw-crash-logs.txt 2>&1
```

**Vérification :**
```bash
docker exec openclaw-gateway openclaw status --full
```

---

## ✅ Checklist

- [ ] Script de diagnostic execute sans erreur
- [ ] Docker fonctionne correctement
- [ ] Ollama repond et les modeles sont charges
- [ ] Gateway OpenClaw est healthy
- [ ] Performances CPU/RAM dans les normes
- [ ] Configuration JSON valide
- [ ] Procedure de recuperation testee

---

## ⚠️ Dépannage

### Erreur : "Cannot kill container"

**Cause :** Processus zombie ou Docker freeze.

**Solution :**
```bash
docker kill --signal=SIGKILL openclaw-gateway && docker rm -f openclaw-gateway
```

Si ca ne marche pas, redemarre Docker Desktop.

---

### Erreur : "No space left on device"

**Cause :** Disque plein, souvent a cause de Docker.

**Solution :**
```bash
docker system df && docker system prune -a --volumes
```

Supprime aussi les anciens modeles Ollama :

```bash
ollama list && ollama rm modele-inutilise
```

---

### Erreur : "Connection reset by peer"

**Cause :** Le service cible a crashe ou est surcharge.

**Solution :**

Redemarre les services un par un :

```bash
docker restart openclaw-gateway && sleep 5 && ollama serve &
```

---

### Mac tres lent / ventilateurs a fond

**Cause :** Processus emballe ou fuite memoire.

**Solution :**

Identifie et tue le processus :

```bash
top -o cpu
```

Si c'est ollama ou Docker, redemarre :

```bash
pkill ollama && docker restart openclaw-gateway
```

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| Docker Troubleshooting | https://docs.docker.com/desktop/troubleshoot/overview/ |
| Ollama FAQ | https://github.com/ollama/ollama/blob/main/docs/faq.md |
| Apple Silicon Docker | https://docs.docker.com/desktop/install/mac-install/ |
| OpenClaw Status Page | https://status.openclaw.ai |
| Forum Support | https://community.openclaw.ai/support |

---

## ➡️ Prochaine étape

Tu sais maintenant diagnostiquer et resoudre les problemes courants. Dans le chapitre suivant, tu vas apprendre a faire des **mises a jour sans interruption** : [5.2 - Mises a Jour Rolling](./02-mises-a-jour-rolling.md).
