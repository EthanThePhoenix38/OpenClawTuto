# 🎯 5.3 - Optimisation des Performances

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas optimiser OpenClaw pour tirer le maximum de ton Mac Studio M3 Ultra. Tu apprendras a configurer la RAM, exploiter le GPU Metal, et mettre en place un cache intelligent.

**Objectifs :**
- Optimiser l'allocation memoire pour les LLM
- Maximiser l'utilisation du GPU Metal
- Configurer le cache de reponses
- Monitorer et ajuster les performances
- Automatiser les optimisations

---

## 🛠️ Prérequis

| Composant | Requis | Verification |
|-----------|--------|--------------|
| Mac Studio M3 Ultra | - | `system_profiler SPHardwareDataType` |
| RAM | 64 Go+ recommande | `sysctl hw.memsize` |
| OpenClaw | v2026.1.30 | `docker exec openclaw-gateway openclaw --version` |
| Ollama | 0.3+ | `ollama --version` |

---

## 📝 Étapes détaillées

### Étape 1 : Analyser les performances actuelles

**Pourquoi ?**
Avant d'optimiser, tu dois connaitre l'etat actuel. Un benchmark de reference te permet de mesurer l'impact de chaque optimisation.

**Comment ?**

Execute le benchmark OpenClaw :

```bash
docker exec openclaw-gateway openclaw benchmark --full > ~/benchmark-before.txt
```

Mesure le throughput Ollama :

```bash
time ollama run llama3.2:8b "Ecris un poeme de 100 mots sur la mer" --verbose 2>&1 | tee ~/ollama-bench-before.txt
```

Collecte les metriques systeme :

```bash
echo "=== Benchmark Systeme ===" > ~/system-bench.txt && echo "CPU:" >> ~/system-bench.txt && sysctl -n machdep.cpu.brand_string >> ~/system-bench.txt && echo "RAM totale:" >> ~/system-bench.txt && sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " Go"}' >> ~/system-bench.txt && echo "GPU Cores:" >> ~/system-bench.txt && system_profiler SPDisplaysDataType | grep "Total Number of Cores" >> ~/system-bench.txt
```

Note ces metriques de reference :
- Temps de premiere reponse (TTFR)
- Tokens par seconde
- Utilisation memoire
- Utilisation GPU

**Vérification :**
```bash
cat ~/benchmark-before.txt | grep -E "throughput|latency|tokens"
```

---

### Étape 2 : Optimiser l'allocation memoire

**Pourquoi ?**
Le Mac Studio M3 Ultra peut avoir jusqu'a 192 Go de RAM unifiee. Une allocation optimale permet de charger des modeles plus grands et de les garder en memoire.

**Comment ?**

**Configure Docker Desktop :**

1. Ouvre Docker Desktop
2. Settings > Resources
3. Augmente la memoire a 75% de ta RAM totale
4. Exemple : 144 Go sur 192 Go

**Configure Ollama pour la memoire :**

```bash
cat >> ~/.zshrc << 'EOF'
# Ollama Memory Optimization
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_MAX_LOADED_MODELS=3
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_KV_CACHE_TYPE=q8_0
EOF
source ~/.zshrc
```

Parametres expliques :
- `NUM_PARALLEL` : requetes simultanees
- `MAX_LOADED_MODELS` : modeles en RAM
- `FLASH_ATTENTION` : optimisation attention
- `KV_CACHE_TYPE` : compression du cache

**Configure le garbage collector Go (pour OpenClaw) :**

```bash
nano ~/.openclaw/docker-compose.yml
```

Ajoute dans environment :

```yaml
environment:
  - GOGC=50
  - GOMEMLIMIT=32GiB
```

Redemarre :

```bash
docker compose -f ~/.openclaw/docker-compose.yml up -d
```

**Vérification :**
```bash
docker stats openclaw-gateway --no-stream --format "{{.MemUsage}}"
```

---

### Étape 3 : Maximiser l'utilisation GPU Metal

**Pourquoi ?**
Le GPU du M3 Ultra (jusqu'a 80 coeurs) accelere considerablement l'inference. Une configuration optimale peut doubler ou tripler la vitesse.

**Comment ?**

**Active tous les coeurs GPU pour Ollama :**

```bash
export OLLAMA_NUM_GPU=999
```

Pour rendre permanent :

```bash
echo 'export OLLAMA_NUM_GPU=999' >> ~/.zshrc && source ~/.zshrc
```

**Configure les layers GPU :**

Pour les gros modeles, ajuste le nombre de layers sur GPU :

```bash
ollama run llama3.2:70b --num-gpu 80
```

Sur M3 Ultra avec 192 Go RAM, tu peux mettre tous les layers sur GPU.

**Optimise Metal Performance Shaders :**

```bash
export METAL_DEVICE_WRAPPER_TYPE=1
```

**Desactive le throttling energetique (temporairement) :**

```bash
sudo pmset -a gpuswitch 2 && sudo pmset -a powernap 0
```

Attention : ca augmente la consommation electrique.

**Verifie l'utilisation GPU :**

```bash
sudo powermetrics --samplers gpu_power -i 1000 -n 5
```

**Vérification :**
```bash
ollama run llama3.2:8b "Test GPU" --verbose 2>&1 | grep -E "gpu|metal|eval"
```

Tu dois voir des lignes mentionnant "metal" ou "gpu".

---

### Étape 4 : Configurer le cache intelligent

**Pourquoi ?**
Le cache stocke les reponses frequentes et les embeddings precalcules. Ca reduit drastiquement la latence pour les requetes repetitives.

**Comment ?**

**Active le cache OpenClaw :**

```bash
nano ~/.openclaw/openclaw.json
```

```json
{
  "cache": {
    "enabled": true,
    "type": "hybrid",
    "memory": {
      "maxSize": "4GB",
      "ttl": 3600
    },
    "disk": {
      "path": "~/.openclaw/cache",
      "maxSize": "50GB",
      "ttl": 86400
    },
    "semantic": {
      "enabled": true,
      "threshold": 0.92,
      "embedModel": "nomic-embed-text"
    }
  }
}
```

Parametres :
- `hybrid` : combine RAM et disque
- `semantic` : cache par similarite semantique
- `threshold` : seuil de similarite (0.92 = 92%)

**Telecharge le modele d'embeddings :**

```bash
ollama pull nomic-embed-text
```

**Configure le cache KV d'Ollama :**

```bash
nano ~/.ollama/config.json
```

```json
{
  "kv_cache": {
    "type": "q8_0",
    "max_size": "8GB"
  },
  "flash_attention": true
}
```

**Precharge les modeles frequents :**

```bash
ollama run llama3.2:8b "" --keepalive 24h &
```

Cree un script de preload :

```bash
cat > ~/preload-models.sh << 'EOF'
#!/bin/bash
echo "Preloading models..."
ollama run llama3.2:8b "" --keepalive 24h &
ollama run nomic-embed-text "" --keepalive 24h &
echo "Models preloaded and kept in memory."
EOF
chmod +x ~/preload-models.sh
```

**Vérification :**
```bash
curl http://localhost:18789/api/cache/stats | jq
```

Tu dois voir le hit rate et la taille du cache.

---

### Étape 5 : Monitorer en continu

**Pourquoi ?**
Le monitoring permet de detecter les degradations de performance et d'ajuster les parametres en temps reel.

**Comment ?**

**Script de monitoring temps reel :**

```bash
cat > ~/monitor-openclaw.sh << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "=== OpenClaw Monitor $(date) ==="
    echo ""
    echo "--- Gateway Health ---"
    curl -s http://localhost:18789/api/health | jq '{status, uptime, requests_total}'
    echo ""
    echo "--- Docker Stats ---"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep openclaw
    echo ""
    echo "--- Ollama ---"
    curl -s http://localhost:11434/api/tags | jq '.models | length' | xargs -I {} echo "Models loaded: {}"
    echo ""
    echo "--- System ---"
    memory_pressure | head -3
    echo ""
    echo "--- Cache ---"
    curl -s http://localhost:18789/api/cache/stats 2>/dev/null | jq '{hit_rate, size}' || echo "Cache stats unavailable"
    echo ""
    sleep 5
done
EOF
chmod +x ~/monitor-openclaw.sh
```

Lance le monitoring :

```bash
~/monitor-openclaw.sh
```

**Alertes de performance :**

```bash
cat > ~/alert-performance.sh << 'EOF'
#!/bin/bash
THRESHOLD_CPU=90
THRESHOLD_MEM=85
THRESHOLD_LATENCY=5000

CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" openclaw-gateway | tr -d '%')
MEM=$(docker stats --no-stream --format "{{.MemPerc}}" openclaw-gateway | tr -d '%')
LATENCY=$(curl -s -w "%{time_total}" -o /dev/null http://localhost:18789/api/health | awk '{print $1*1000}')

if (( $(echo "$CPU > $THRESHOLD_CPU" | bc -l) )); then
    echo "ALERT: CPU usage is ${CPU}%"
fi

if (( $(echo "$MEM > $THRESHOLD_MEM" | bc -l) )); then
    echo "ALERT: Memory usage is ${MEM}%"
fi

if (( $(echo "$LATENCY > $THRESHOLD_LATENCY" | bc -l) )); then
    echo "ALERT: Latency is ${LATENCY}ms"
fi
EOF
chmod +x ~/alert-performance.sh
```

Ajoute au crontab :

```bash
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/alert-performance.sh >> ~/.openclaw/alerts.log 2>&1") | crontab -
```

**Vérification :**
```bash
~/alert-performance.sh
```

---

### Étape 6 : Comparer avant/apres

**Pourquoi ?**
La comparaison quantifie l'impact de tes optimisations et identifie les gains les plus significatifs.

**Comment ?**

Execute le meme benchmark qu'a l'etape 1 :

```bash
docker exec openclaw-gateway openclaw benchmark --full > ~/benchmark-after.txt
```

Compare les resultats :

```bash
echo "=== Comparaison Avant/Apres ===" && echo "" && echo "AVANT:" && cat ~/benchmark-before.txt | grep -E "throughput|latency|tokens" && echo "" && echo "APRES:" && cat ~/benchmark-after.txt | grep -E "throughput|latency|tokens"
```

Cree un rapport :

```bash
cat > ~/optimization-report.md << EOF
# Rapport d'Optimisation OpenClaw

Date: $(date)
Machine: Mac Studio M3 Ultra

## Resultats

### Avant optimisation
$(cat ~/benchmark-before.txt | grep -E "throughput|latency|tokens")

### Apres optimisation
$(cat ~/benchmark-after.txt | grep -E "throughput|latency|tokens")

## Optimisations appliquees
- [ ] Memoire Docker augmentee
- [ ] Variables Ollama configurees
- [ ] GPU Metal maximise
- [ ] Cache active
- [ ] Modeles precharges

## Recommandations
- Surveiller le cache hit rate
- Ajuster les modeles precharges selon usage
- Revoir les parametres si degradation
EOF
```

**Vérification :**
```bash
cat ~/optimization-report.md
```

---

## ✅ Checklist

- [ ] Benchmark initial execute et sauvegarde
- [ ] Memoire Docker configuree (75% RAM)
- [ ] Variables Ollama optimisees
- [ ] GPU Metal active (OLLAMA_NUM_GPU=999)
- [ ] Cache hybride configure
- [ ] Modele d'embeddings telecharge
- [ ] Script de preload cree
- [ ] Monitoring en place
- [ ] Alertes configurees
- [ ] Benchmark final execute et compare

---

## ⚠️ Dépannage

### Erreur : "Out of memory" malgre l'optimisation

**Cause :** Trop de modeles charges simultanement.

**Solution :**

Reduis le nombre de modeles en memoire :

```bash
export OLLAMA_MAX_LOADED_MODELS=2
```

Ou decharge un modele :

```bash
curl -X DELETE http://localhost:11434/api/generate -d '{"model":"modele-a-decharger"}'
```

---

### GPU non utilise (tokens/s faible)

**Cause :** Variable OLLAMA_NUM_GPU non appliquee.

**Solution :**

Verifie et relance Ollama :

```bash
echo $OLLAMA_NUM_GPU && pkill ollama && OLLAMA_NUM_GPU=999 ollama serve &
```

---

### Cache hit rate faible

**Cause :** Seuil semantique trop eleve ou cache trop petit.

**Solution :**

Baisse le seuil :

```json
{
  "cache": {
    "semantic": {
      "threshold": 0.85
    }
  }
}
```

Augmente la taille :

```json
{
  "cache": {
    "memory": {
      "maxSize": "8GB"
    }
  }
}
```

---

### Latence elevee apres optimisation

**Cause :** Trop de parallelisme ou contention.

**Solution :**

Reduis le parallelisme :

```bash
export OLLAMA_NUM_PARALLEL=2
```

Verifie les processus concurrents :

```bash
top -o cpu
```

---

### Docker consomme trop de memoire

**Cause :** Fuites memoire ou garbage collection inefficace.

**Solution :**

Redemarre periodiquement :

```bash
docker restart openclaw-gateway
```

Ou ajoute un cron de maintenance :

```bash
(crontab -l 2>/dev/null; echo "0 3 * * * docker restart openclaw-gateway") | crontab -
```

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| Ollama Performance | https://github.com/ollama/ollama/blob/main/docs/faq.md#performance |
| Apple Metal | https://developer.apple.com/metal/ |
| Docker Resources | https://docs.docker.com/desktop/settings/mac/#resources |
| M3 Specifications | https://www.apple.com/mac-studio/specs/ |
| OpenClaw Tuning | https://docs.openclaw.ai/performance |

---

## ➡️ Conclusion

Felicitations ! Tu as termine le guide OpenClaw sur Mac Studio M3 Ultra. Tu sais maintenant :

- Installer et configurer OpenClaw
- Securiser ton installation
- Connecter des LLM locaux et des channels de messagerie
- Etendre les fonctionnalites avec skills et workflows
- Maintenir et optimiser les performances

**Pour aller plus loin :**
- Rejoins la communaute OpenClaw : https://community.openclaw.ai
- Contribue au projet : https://github.com/openclaw
- Decouvre les skills avances sur ClawHub : https://clawhub.io

Bonne utilisation d'OpenClaw !
