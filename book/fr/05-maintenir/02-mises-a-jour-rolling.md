# 🎯 5.2 - Mises à Jour Rolling (Zero-Downtime)

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas maitriser les mises a jour sans interruption de service. Les rolling updates permettent de deployer de nouvelles versions d'OpenClaw tout en continuant a repondre aux utilisateurs.

**Objectifs :**
- Comprendre le principe des rolling updates
- Configurer les health checks pour le zero-downtime
- Effectuer une mise a jour sans interruption
- Gerer les rollbacks en cas de probleme
- Automatiser les mises a jour

---

## 🛠️ Prérequis

| Composant | Requis | Verification |
|-----------|--------|--------------|
| OpenClaw | En fonctionnement | `curl http://localhost:18789/api/health` |
| Docker | 24.0+ | `docker --version` |
| Docker Compose | 2.20+ | `docker compose version` |
| Espace disque | 10 Go libre | `df -h /` |

---

## 📝 Étapes détaillées

### Étape 1 : Comprendre le rolling update

**Pourquoi ?**
Un rolling update remplace progressivement les conteneurs par leurs nouvelles versions. Pendant la transition, l'ancien et le nouveau conteneur coexistent, garantissant la continuite du service.

**Comment ?**

Schema du processus :

```
Etat initial:     [Gateway v1] ──── Port 18789
                       │
Nouvelle image:   [Gateway v2] (demarre)
                       │
Health check OK:  [Gateway v1] + [Gateway v2] (les deux actifs)
                       │
Bascule trafic:   [Gateway v2] ──── Port 18789
                       │
Nettoyage:        [Gateway v1] (arrete et supprime)
```

Avantages :
- Zero interruption de service
- Rollback rapide si probleme
- Test de la nouvelle version en production

**Vérification :**

Verifie que le health check est configure :

```bash
docker inspect openclaw-gateway | jq '.[0].Config.Healthcheck'
```

---

### Étape 2 : Configurer les health checks

**Pourquoi ?**
Les health checks permettent a Docker de savoir si le conteneur est pret a recevoir du trafic. Sans ca, le nouveau conteneur pourrait recevoir des requetes avant d'etre initialise.

**Comment ?**

Cree ou modifie le docker-compose :

```bash
nano ~/.openclaw/docker-compose.yml
```

```yaml
version: '3.8'

services:
  gateway:
    image: openclaw/gateway:latest
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - ~/.openclaw:/app/config
      - openclaw-data:/app/data
    environment:
      - OLLAMA_HOST=host.docker.internal:11434
      - LMSTUDIO_HOST=host.docker.internal:1234
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/api/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
    deploy:
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        monitor: 60s
        order: start-first
      rollback_config:
        parallelism: 1
        delay: 10s
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  openclaw-data:
```

Explications des parametres :
- `start_period` : temps d'initialisation avant les checks
- `order: start-first` : demarre le nouveau avant d'arreter l'ancien
- `failure_action: rollback` : retour automatique si echec

**Vérification :**
```bash
docker compose -f ~/.openclaw/docker-compose.yml config
```

---

### Étape 3 : Effectuer une mise a jour manuelle

**Pourquoi ?**
Avant d'automatiser, tu dois savoir faire une mise a jour manuellement. Ca te permet de comprendre le processus et d'intervenir si necessaire.

**Comment ?**

**1. Verifie l'etat actuel :**

```bash
docker exec openclaw-gateway openclaw --version && docker images openclaw/gateway --format "{{.Tag}}"
```

**2. Telecharge la nouvelle image :**

```bash
docker pull openclaw/gateway:latest
```

**3. Sauvegarde la configuration :**

```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-update
```

**4. Lance la mise a jour :**

```bash
docker compose -f ~/.openclaw/docker-compose.yml up -d --no-deps --build gateway
```

**5. Surveille le deploiement :**

```bash
watch -n 2 'docker ps --filter "name=openclaw" --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"'
```

Attend que le statut passe a "healthy".

**6. Verifie la nouvelle version :**

```bash
docker exec openclaw-gateway openclaw --version
```

**Vérification :**
```bash
curl http://localhost:18789/api/health | jq '{status, version}'
```

---

### Étape 4 : Gerer les rollbacks

**Pourquoi ?**
Si la nouvelle version a un bug critique, tu dois pouvoir revenir rapidement a la version precedente. Un rollback bien prepare prend moins de 30 secondes.

**Comment ?**

**Rollback automatique (si configure) :**

Si le deploy echoue et que `failure_action: rollback` est configure, Docker revient automatiquement a la version precedente.

**Rollback manuel :**

**1. Identifie la version precedente :**

```bash
docker images openclaw/gateway --format "{{.Tag}}\t{{.CreatedAt}}" | head -5
```

**2. Force le retour a la version precedente :**

```bash
docker compose -f ~/.openclaw/docker-compose.yml up -d --no-deps gateway --force-recreate
```

Si tu as tag l'ancienne version :

```bash
docker tag openclaw/gateway:latest openclaw/gateway:rollback && docker compose -f ~/.openclaw/docker-compose.yml up -d
```

**3. Restaure la configuration si modifiee :**

```bash
cp ~/.openclaw/openclaw.json.pre-update ~/.openclaw/openclaw.json && docker restart openclaw-gateway
```

**Script de rollback rapide :**

```bash
cat > ~/rollback-openclaw.sh << 'EOF'
#!/bin/bash
echo "Rolling back OpenClaw..."
cp ~/.openclaw/openclaw.json.pre-update ~/.openclaw/openclaw.json 2>/dev/null
docker compose -f ~/.openclaw/docker-compose.yml down
docker compose -f ~/.openclaw/docker-compose.yml up -d
echo "Waiting for health check..."
sleep 30
curl -s http://localhost:18789/api/health | jq '{status, version}'
echo "Rollback complete."
EOF
chmod +x ~/rollback-openclaw.sh
```

**Vérification :**
```bash
~/rollback-openclaw.sh
```

---

### Étape 5 : Automatiser les mises a jour

**Pourquoi ?**
Les mises a jour automatiques garantissent que tu beneficies des correctifs de securite et des nouvelles fonctionnalites sans intervention manuelle.

**Comment ?**

**Option 1 : Watchtower (recommande)**

Watchtower surveille les images Docker et met a jour automatiquement :

```bash
docker run -d --name watchtower --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower openclaw-gateway --schedule "0 0 4 * * *" --cleanup --include-stopped
```

Parametres :
- `--schedule` : cron expression (ici : 4h du matin chaque jour)
- `--cleanup` : supprime les anciennes images
- `--include-stopped` : met a jour meme les conteneurs arretes

**Option 2 : Script cron personnalise**

```bash
cat > ~/update-openclaw.sh << 'EOF'
#!/bin/bash
LOG_FILE=~/.openclaw/update.log
echo "=== Update $(date) ===" >> $LOG_FILE

# Pull nouvelle image
docker pull openclaw/gateway:latest >> $LOG_FILE 2>&1

# Sauvegarde config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-update

# Update avec rolling
docker compose -f ~/.openclaw/docker-compose.yml up -d --no-deps gateway >> $LOG_FILE 2>&1

# Attend et verifie
sleep 60
HEALTH=$(curl -s http://localhost:18789/api/health | jq -r '.status')

if [ "$HEALTH" != "healthy" ]; then
    echo "UPDATE FAILED - Rolling back" >> $LOG_FILE
    ~/rollback-openclaw.sh >> $LOG_FILE 2>&1
else
    echo "UPDATE SUCCESS" >> $LOG_FILE
fi
EOF
chmod +x ~/update-openclaw.sh
```

Ajoute au crontab :

```bash
(crontab -l 2>/dev/null; echo "0 4 * * * ~/update-openclaw.sh") | crontab -
```

**Option 3 : Notifications de mise a jour**

Configure les alertes sans mise a jour automatique :

```bash
cat > ~/check-openclaw-updates.sh << 'EOF'
#!/bin/bash
CURRENT=$(docker inspect openclaw-gateway --format '{{.Image}}')
docker pull openclaw/gateway:latest > /dev/null 2>&1
LATEST=$(docker inspect openclaw/gateway:latest --format '{{.Id}}')

if [ "$CURRENT" != "$LATEST" ]; then
    echo "OpenClaw update available!" | mail -s "OpenClaw Update" ton@email.com
fi
EOF
chmod +x ~/check-openclaw-updates.sh
```

**Vérification :**
```bash
docker logs watchtower --tail 20
```

Ou :

```bash
cat ~/.openclaw/update.log
```

---

## ✅ Checklist

- [ ] Health checks configures dans docker-compose.yml
- [ ] Mise a jour manuelle testee avec succes
- [ ] Script de rollback prepare et teste
- [ ] Sauvegarde automatique de la config avant update
- [ ] Automatisation configuree (Watchtower ou cron)
- [ ] Logs de mise a jour accessibles
- [ ] Zero-downtime verifie pendant une mise a jour

---

## ⚠️ Dépannage

### Erreur : "Health check failed"

**Cause :** Le nouveau conteneur ne demarre pas correctement.

**Solution :**

Verifie les logs du nouveau conteneur :

```bash
docker logs openclaw-gateway --tail 50
```

Augmente le `start_period` si l'initialisation est longue :

```yaml
healthcheck:
  start_period: 60s
```

---

### Erreur : "Port already allocated"

**Cause :** L'ancien conteneur n'est pas encore arrete.

**Solution :**

Force l'arret de l'ancien :

```bash
docker stop openclaw-gateway && docker rm openclaw-gateway && docker compose up -d
```

---

### Watchtower ne met pas a jour

**Cause :** Label ou filtre incorrect.

**Solution :**

Verifie que le conteneur est surveille :

```bash
docker logs watchtower | grep openclaw
```

Relance Watchtower avec debug :

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once --debug openclaw-gateway
```

---

### Rollback echoue

**Cause :** Image precedente supprimee.

**Solution :**

Tag toujours l'image stable avant mise a jour :

```bash
docker tag openclaw/gateway:latest openclaw/gateway:stable
```

Rollback vers stable :

```bash
docker tag openclaw/gateway:stable openclaw/gateway:latest && docker compose up -d
```

---

### Mise a jour partielle

**Cause :** Interruption pendant le deploiement.

**Solution :**

Force le recreate complet :

```bash
docker compose -f ~/.openclaw/docker-compose.yml up -d --force-recreate
```

---

## 🔗 Ressources

| Ressource | URL |
|-----------|-----|
| Docker Compose Deploy | https://docs.docker.com/compose/compose-file/deploy/ |
| Watchtower | https://containrrr.dev/watchtower/ |
| Health Checks | https://docs.docker.com/engine/reference/builder/#healthcheck |
| Rolling Updates | https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/ |
| OpenClaw Changelog | https://docs.openclaw.ai/changelog |

---

## ➡️ Prochaine étape

Tu maitrises les mises a jour sans interruption ! Dans le dernier chapitre, tu vas apprendre a **optimiser les performances** de ton installation : [5.3 - Optimisation Performances](./03-optimisation-performances.md).
