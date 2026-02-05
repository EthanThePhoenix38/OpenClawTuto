# 🎯 2.5 - Déploiement OpenClaw dans k3s

## 📋 Ce que tu vas apprendre
- Comment créer les fichiers de configuration Kubernetes pour OpenClaw
- Comment déployer OpenClaw version 2026.1.30 dans k3s
- Comment connecter OpenClaw aux backends Ollama et LM Studio
- Comment vérifier que tout fonctionne et accéder à l'interface

## 🛠️ Prérequis
- Chapitre 2.2 complété (Ollama installé et fonctionnel)
- Chapitre 2.3 complété (LM Studio installé - optionnel)
- Chapitre 2.4 complété (k3s installé et fonctionnel)
- kubectl connecté au cluster k3s

## 📝 Étapes détaillées

### Étape 1 : Préparer l'environnement

**Pourquoi ?** On va créer tous les fichiers de configuration dans un dossier organisé avant de les appliquer.

**Comment ?**
```bash
mkdir -p ~/openclaw/k8s/{base,secrets,services} && cd ~/openclaw/k8s
```

**Vérifier que k3s est prêt :**
```bash
kubectl get nodes && kubectl get ns openclaw
```

**Résultat attendu :**
```
NAME         STATUS   ROLES                  AGE   VERSION
k3s-master   Ready    control-plane,master   1h    v1.28.x+k3s1

NAME       STATUS   AGE
openclaw   Active   1h
```

---

### Étape 2 : Créer les secrets (mots de passe et clés)

**Pourquoi ?** Les secrets contiennent les informations sensibles comme les mots de passe. Kubernetes les stocke de manière sécurisée.

**Comment ?**

**Générer un mot de passe aléatoire pour la base de données :**
```bash
DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24) && echo "Mot de passe DB généré: $DB_PASSWORD" && echo "$DB_PASSWORD" > ~/openclaw/config/db-password.txt
```

**Générer une clé secrète pour les sessions :**
```bash
SESSION_SECRET=$(openssl rand -base64 32) && echo "Clé session générée: $SESSION_SECRET" && echo "$SESSION_SECRET" > ~/openclaw/config/session-secret.txt
```

**Créer le fichier de secrets Kubernetes :**
```bash
cat << EOF > ~/openclaw/k8s/secrets/openclaw-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: openclaw-secrets
  namespace: openclaw
type: Opaque
stringData:
  DB_PASSWORD: "${DB_PASSWORD}"
  SESSION_SECRET: "${SESSION_SECRET}"
  OLLAMA_HOST: "host.docker.internal:11434"
  LM_STUDIO_HOST: "host.docker.internal:1234"
EOF
```

**Appliquer les secrets :**
```bash
kubectl apply -f ~/openclaw/k8s/secrets/openclaw-secrets.yaml
```

**Vérification :**
```bash
kubectl get secrets -n openclaw
```

**Résultat attendu :**
```
NAME               TYPE     DATA   AGE
openclaw-secrets   Opaque   4      1m
```

---

### Étape 3 : Créer le ConfigMap (configuration)

**Pourquoi ?** Le ConfigMap contient la configuration non-secrète de l'application.

**Comment ?**
```bash
cat << 'EOF' > ~/openclaw/k8s/base/openclaw-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openclaw-config
  namespace: openclaw
data:
  # Configuration générale
  NODE_ENV: "production"
  PORT: "18789"
  LOG_LEVEL: "info"

  # Configuration IA
  DEFAULT_AI_BACKEND: "ollama"
  OLLAMA_MODEL: "llama3.1:8b"
  LM_STUDIO_MODEL: "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF"

  # Configuration base de données
  DB_HOST: "openclaw-db"
  DB_PORT: "5432"
  DB_NAME: "openclaw"
  DB_USER: "openclaw"

  # Configuration réseau
  CORS_ORIGIN: "*"
  TRUST_PROXY: "true"

  # Configuration sécurité
  RATE_LIMIT_MAX: "100"
  RATE_LIMIT_WINDOW: "60000"
EOF
kubectl apply -f ~/openclaw/k8s/base/openclaw-configmap.yaml
```

**Vérification :**
```bash
kubectl get configmap -n openclaw
```

---

### Étape 4 : Créer le stockage persistant

**Pourquoi ?** On veut que les données d'OpenClaw (conversations, fichiers) survivent aux redémarrages.

**Comment ?**
```bash
cat << 'EOF' > ~/openclaw/k8s/base/openclaw-storage.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: openclaw-data
  namespace: openclaw
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: openclaw-db-data
  namespace: openclaw
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
EOF
kubectl apply -f ~/openclaw/k8s/base/openclaw-storage.yaml
```

**Vérification :**
```bash
kubectl get pvc -n openclaw
```

**Résultat attendu :**
```
NAME              STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
openclaw-data     Pending   ...      ...        RWO            local-path     1m
openclaw-db-data  Pending   ...      ...        RWO            local-path     1m
```

Le statut "Pending" est normal jusqu'au déploiement.

---

### Étape 5 : Déployer la base de données PostgreSQL

**Pourquoi ?** OpenClaw utilise PostgreSQL pour stocker les conversations, les utilisateurs et les paramètres.

**Comment ?**
```bash
cat << 'EOF' > ~/openclaw/k8s/services/postgres.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openclaw-db
  namespace: openclaw
  labels:
    app: openclaw-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openclaw-db
  template:
    metadata:
      labels:
        app: openclaw-db
    spec:
      containers:
        - name: postgres
          image: postgres:16-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: "openclaw"
            - name: POSTGRES_USER
              value: "openclaw"
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: openclaw-secrets
                  key: DB_PASSWORD
            - name: PGDATA
              value: "/var/lib/postgresql/data/pgdata"
          volumeMounts:
            - name: db-data
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            exec:
              command: ["pg_isready", "-U", "openclaw"]
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "openclaw"]
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: db-data
          persistentVolumeClaim:
            claimName: openclaw-db-data
---
apiVersion: v1
kind: Service
metadata:
  name: openclaw-db
  namespace: openclaw
spec:
  selector:
    app: openclaw-db
  ports:
    - port: 5432
      targetPort: 5432
  type: ClusterIP
EOF
kubectl apply -f ~/openclaw/k8s/services/postgres.yaml
```

**Attendre que PostgreSQL soit prêt :**
```bash
kubectl wait --for=condition=ready pod -l app=openclaw-db -n openclaw --timeout=120s
```

**Vérification :**
```bash
kubectl get pods -n openclaw -l app=openclaw-db
```

**Résultat attendu :**
```
NAME                           READY   STATUS    RESTARTS   AGE
openclaw-db-xxxxxxxxx-xxxxx    1/1     Running   0          2m
```

---

### Étape 6 : Déployer OpenClaw

**Pourquoi ?** C'est le moment de déployer l'application principale !

**Comment ?**
```bash
cat << 'EOF' > ~/openclaw/k8s/services/openclaw.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openclaw
  namespace: openclaw
  labels:
    app: openclaw
    version: "2026.1.30"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openclaw
  template:
    metadata:
      labels:
        app: openclaw
        version: "2026.1.30"
    spec:
      containers:
        - name: openclaw
          image: ghcr.io/openclaw/openclaw:2026.1.30
          ports:
            - containerPort: 18789
              name: http
          envFrom:
            - configMapRef:
                name: openclaw-config
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: openclaw-secrets
                  key: DB_PASSWORD
            - name: SESSION_SECRET
              valueFrom:
                secretKeyRef:
                  name: openclaw-secrets
                  key: SESSION_SECRET
            - name: OLLAMA_HOST
              valueFrom:
                secretKeyRef:
                  name: openclaw-secrets
                  key: OLLAMA_HOST
            - name: LM_STUDIO_HOST
              valueFrom:
                secretKeyRef:
                  name: openclaw-secrets
                  key: LM_STUDIO_HOST
            - name: DATABASE_URL
              value: "postgresql://openclaw:$(DB_PASSWORD)@openclaw-db:5432/openclaw"
          volumeMounts:
            - name: data
              mountPath: /app/data
          resources:
            requests:
              memory: "512Mi"
              cpu: "200m"
            limits:
              memory: "2Gi"
              cpu: "2000m"
          livenessProbe:
            httpGet:
              path: /health
              port: 18789
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 18789
            initialDelaySeconds: 10
            periodSeconds: 5
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: openclaw-data
      hostAliases:
        - ip: "192.168.65.254"
          hostnames:
            - "host.docker.internal"
---
apiVersion: v1
kind: Service
metadata:
  name: openclaw
  namespace: openclaw
spec:
  selector:
    app: openclaw
  ports:
    - port: 18789
      targetPort: 18789
      name: http
  type: ClusterIP
EOF
kubectl apply -f ~/openclaw/k8s/services/openclaw.yaml
```

**Attendre le déploiement :**
```bash
kubectl wait --for=condition=ready pod -l app=openclaw -n openclaw --timeout=180s
```

**Vérification :**
```bash
kubectl get pods -n openclaw
```

**Résultat attendu :**
```
NAME                           READY   STATUS    RESTARTS   AGE
openclaw-xxxxxxxxx-xxxxx       1/1     Running   0          2m
openclaw-db-xxxxxxxxx-xxxxx    1/1     Running   0          5m
```

---

### Étape 7 : Exposer OpenClaw à l'extérieur

**Pourquoi ?** On veut pouvoir accéder à OpenClaw depuis notre navigateur sur le Mac.

**Comment ?**

**Option A : Port-forwarding (simple, pour les tests) :**
```bash
kubectl port-forward -n openclaw svc/openclaw 18789:18789 &
```

**Option B : NodePort (accès direct via l'IP de la VM) :**
```bash
cat << 'EOF' > ~/openclaw/k8s/services/openclaw-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: openclaw-external
  namespace: openclaw
spec:
  selector:
    app: openclaw
  ports:
    - port: 18789
      targetPort: 18789
      nodePort: 30789
  type: NodePort
EOF
kubectl apply -f ~/openclaw/k8s/services/openclaw-nodeport.yaml
```

**Trouver l'URL d'accès :**
```bash
K3S_IP=$(multipass info k3s-master | grep IPv4 | awk '{print $2}') && echo "OpenClaw accessible sur : http://$K3S_IP:30789"
```

**Vérification :**
```bash
curl -s http://localhost:18789/health
```

**Résultat attendu :**
```json
{"status":"healthy","version":"2026.1.30"}
```

---

### Étape 8 : Configurer la connexion aux backends IA

**Pourquoi ?** On doit permettre aux pods k3s d'accéder à Ollama et LM Studio qui tournent sur le Mac.

**Comment ?**

Le problème : k3s tourne dans une VM, et Ollama/LM Studio tournent sur le Mac. On doit créer un pont.

**Configurer Ollama pour accepter les connexions externes :**
```bash
cat << 'EOF' >> ~/.zprofile
export OLLAMA_HOST="0.0.0.0:11434"
EOF
source ~/.zprofile
```

**Redémarrer Ollama :**
1. Quitte Ollama (clic sur l'icône > Quit)
2. Réouvre Ollama

**Créer un ExternalName Service pour Ollama :**
```bash
MAC_IP=$(ipconfig getifaddr en0) && echo "IP du Mac: $MAC_IP"
```

```bash
cat << EOF > ~/openclaw/k8s/services/external-ai.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: ollama-external
  namespace: openclaw
spec:
  type: ExternalName
  externalName: ${MAC_IP}
---
apiVersion: v1
kind: Endpoints
metadata:
  name: ollama-host
  namespace: openclaw
subsets:
  - addresses:
      - ip: ${MAC_IP}
    ports:
      - port: 11434
        name: ollama
---
apiVersion: v1
kind: Service
metadata:
  name: ollama-host
  namespace: openclaw
spec:
  ports:
    - port: 11434
      targetPort: 11434
      name: ollama
---
apiVersion: v1
kind: Endpoints
metadata:
  name: lmstudio-host
  namespace: openclaw
subsets:
  - addresses:
      - ip: ${MAC_IP}
    ports:
      - port: 1234
        name: lmstudio
---
apiVersion: v1
kind: Service
metadata:
  name: lmstudio-host
  namespace: openclaw
spec:
  ports:
    - port: 1234
      targetPort: 1234
      name: lmstudio
EOF
kubectl apply -f ~/openclaw/k8s/services/external-ai.yaml
```

**Tester la connexion depuis un pod :**
```bash
kubectl run -n openclaw test-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s http://ollama-host:11434/api/tags
```

---

### Étape 9 : Vérifier le déploiement complet

**Pourquoi ?** On fait une vérification finale de tous les composants.

**Script de vérification :**
```bash
cat << 'EOF' > ~/openclaw/test-deployment.sh
#!/bin/bash
echo "=== Vérification du déploiement OpenClaw ==="
echo ""

# Test 1: Pods
echo "1. État des Pods :"
kubectl get pods -n openclaw -o wide
echo ""

# Test 2: Services
echo "2. Services disponibles :"
kubectl get svc -n openclaw
echo ""

# Test 3: Health check
echo "3. Health check OpenClaw :"
HEALTH=$(kubectl exec -n openclaw deploy/openclaw -- curl -s http://localhost:18789/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   ✅ $HEALTH"
else
    # Essayer via port-forward
    kubectl port-forward -n openclaw svc/openclaw 18789:18789 &>/dev/null &
    PF_PID=$!
    sleep 2
    HEALTH=$(curl -s http://localhost:18789/health 2>/dev/null)
    kill $PF_PID 2>/dev/null
    if [ -n "$HEALTH" ]; then
        echo "   ✅ $HEALTH"
    else
        echo "   ❌ Health check échoué"
    fi
fi

# Test 4: Base de données
echo ""
echo "4. Connexion base de données :"
DB_STATUS=$(kubectl exec -n openclaw deploy/openclaw-db -- pg_isready -U openclaw 2>/dev/null)
if echo "$DB_STATUS" | grep -q "accepting"; then
    echo "   ✅ PostgreSQL prêt"
else
    echo "   ❌ PostgreSQL non accessible"
fi

# Test 5: Connexion Ollama
echo ""
echo "5. Connexion Ollama :"
OLLAMA_STATUS=$(curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models | length' 2>/dev/null)
if [ "$OLLAMA_STATUS" -gt 0 ] 2>/dev/null; then
    echo "   ✅ Ollama accessible avec $OLLAMA_STATUS modèle(s)"
else
    echo "   ⚠️  Ollama non accessible depuis le Mac"
fi

# Test 6: Logs récents
echo ""
echo "6. Logs récents OpenClaw :"
kubectl logs -n openclaw deploy/openclaw --tail=5 2>/dev/null || echo "   Pas de logs disponibles"

echo ""
echo "=== Vérification terminée ==="

# URL d'accès
K3S_IP=$(multipass info k3s-master 2>/dev/null | grep IPv4 | awk '{print $2}')
echo ""
echo "📍 URLs d'accès :"
echo "   - Via port-forward : http://localhost:18789"
echo "   - Via NodePort     : http://$K3S_IP:30789"
EOF
chmod +x ~/openclaw/test-deployment.sh
```

**Exécuter la vérification :**
```bash
~/openclaw/test-deployment.sh
```

---

### Étape 10 : Accéder à l'interface OpenClaw

**Pourquoi ?** C'est le moment de voir le fruit de notre travail !

**Comment ?**

**Démarrer le port-forwarding :**
```bash
kubectl port-forward -n openclaw svc/openclaw 18789:18789
```

**Ouvrir dans le navigateur :**
1. Ouvre Safari ou Chrome
2. Va sur : http://localhost:18789
3. Tu devrais voir l'interface de connexion OpenClaw

**Premier compte :**
1. Clique sur "S'inscrire" ou "Register"
2. Crée ton compte administrateur
3. Connecte-toi

**Configurer les backends IA :**
1. Va dans Paramètres > Backends IA
2. Ajoute Ollama :
   - URL : http://host.docker.internal:11434
   - Modèle par défaut : llama3.1:8b
3. Ajoute LM Studio (optionnel) :
   - URL : http://host.docker.internal:1234
   - Modèle par défaut : lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF

**Premier test :**
1. Ouvre une nouvelle conversation
2. Tape : "Bonjour, comment ça va ?"
3. Vérifie que tu reçois une réponse

---

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] Les secrets Kubernetes sont créés
- [ ] Le ConfigMap est appliqué
- [ ] Le stockage persistant est créé
- [ ] PostgreSQL est déployé et en état "Running"
- [ ] OpenClaw est déployé et en état "Running"
- [ ] Le health check renvoie "healthy"
- [ ] L'interface web est accessible sur localhost:18789
- [ ] Tu peux te connecter avec ton compte
- [ ] OpenClaw peut communiquer avec Ollama
- [ ] Une conversation de test fonctionne

---

## ⚠️ Dépannage

### Le pod OpenClaw reste en "Pending"
**Symptôme :** Le pod ne démarre pas
**Solutions :**
```bash
kubectl describe pod -n openclaw -l app=openclaw
```
Regarde la section "Events" pour voir l'erreur.

### Le pod est en "CrashLoopBackOff"
**Symptôme :** Le pod redémarre en boucle
**Solution :** Regarde les logs :
```bash
kubectl logs -n openclaw -l app=openclaw --previous
```

### Erreur "ImagePullBackOff"
**Symptôme :** Impossible de télécharger l'image
**Solution :** Vérifie ta connexion Internet et réessaie :
```bash
kubectl delete pod -n openclaw -l app=openclaw
```

### PostgreSQL ne démarre pas
**Symptôme :** Pod DB en erreur
**Solution :**
```bash
kubectl logs -n openclaw -l app=openclaw-db
```
Souvent un problème de permissions sur le volume.

### OpenClaw ne peut pas joindre Ollama
**Symptôme :** Erreur de connexion dans les logs
**Solutions :**
1. Vérifie qu'Ollama écoute sur toutes les interfaces :
```bash
lsof -i :11434
```
2. Vérifie que `OLLAMA_HOST=0.0.0.0:11434` est défini
3. Teste depuis la VM :
```bash
multipass exec k3s-master -- curl -s http://$(ipconfig getifaddr en0):11434/api/tags
```

### L'interface web ne se charge pas
**Symptôme :** Page blanche ou erreur 502
**Solutions :**
1. Vérifie que le port-forward est actif
2. Essaie d'accéder directement au pod :
```bash
kubectl exec -n openclaw deploy/openclaw -- curl -s http://localhost:18789/
```

### Les données disparaissent après redémarrage
**Symptôme :** Conversations perdues
**Solution :** Vérifie les PVC :
```bash
kubectl get pvc -n openclaw
```
S'ils sont en "Pending", le stockage n'est pas correctement configuré.

---

## 🔗 Ressources

- [Documentation OpenClaw](https://openclaw.dev/docs)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

---

## 📊 Architecture déployée

```
┌─────────────────────────────────────────────────────────┐
│                    Namespace: openclaw                   │
│                                                          │
│  ┌─────────────────┐      ┌─────────────────────────┐  │
│  │    ConfigMap    │      │        Secrets          │  │
│  │  openclaw-config│      │   openclaw-secrets      │  │
│  └────────┬────────┘      └───────────┬─────────────┘  │
│           │                           │                  │
│  ┌────────▼───────────────────────────▼─────────────┐  │
│  │              Deployment: openclaw                 │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────────┐ │  │
│  │  │              Pod: openclaw                   │ │  │
│  │  │  Image: ghcr.io/openclaw/openclaw:2026.1.30│ │  │
│  │  │  Port: 18789                                │ │  │
│  │  └─────────────────────────────────────────────┘ │  │
│  └──────────────────────┬───────────────────────────┘  │
│                         │                               │
│  ┌──────────────────────▼───────────────────────────┐  │
│  │            Service: openclaw                      │  │
│  │            Port: 18789 → 18789                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │          Deployment: openclaw-db                 │   │
│  │          Image: postgres:16-alpine               │   │
│  │          Port: 5432                              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │  PVC: data   │  │  PVC: db-data│                    │
│  │  10Gi        │  │  5Gi         │                    │
│  └──────────────┘  └──────────────┘                    │
└─────────────────────────────────────────────────────────┘
              │                      │
              ▼                      ▼
      ┌───────────────┐      ┌───────────────┐
      │    Ollama     │      │   LM Studio   │
      │  Port 11434   │      │   Port 1234   │
      │   (Mac natif) │      │  (Mac natif)  │
      └───────────────┘      └───────────────┘
```

---

## ➡️ Prochaine étape

OpenClaw est déployé et fonctionnel ! Dans le prochain chapitre, on va configurer le réseau pour isoler complètement notre installation et la sécuriser.

**Chapitre suivant :** [2.6 - Configuration réseau isolé](./06-configuration-reseau.md)
