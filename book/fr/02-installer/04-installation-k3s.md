# 🎯 2.4 - Installation k3s sur macOS

## 📋 Ce que tu vas apprendre
- Ce qu'est k3s et pourquoi on l'utilise au lieu de Docker seul
- Comment installer k3s sur macOS via Multipass
- Comment configurer kubectl pour parler à ton cluster
- Comment vérifier que tout fonctionne correctement

## 🛠️ Prérequis
- Chapitre 2.1 complété (tous les outils installés)
- Docker Desktop installé et fonctionnel
- Au moins 16 GB de RAM disponibles pour la VM k3s
- 50 GB d'espace disque libre

## 📝 Étapes détaillées

### Étape 1 : Comprendre pourquoi k3s

**Pourquoi ?** k3s est une version allégée de Kubernetes. C'est comme avoir un orchestre qui dirige tous tes conteneurs au lieu de les gérer un par un.

**Avantages de k3s :**
- Plus léger que Kubernetes complet (moins de 100 MB)
- Parfait pour un seul serveur (notre Mac Studio)
- Inclut tout ce qu'il faut : stockage, réseau, load balancer
- Facile à sauvegarder et restaurer

**Architecture sur macOS :**
```
┌─────────────────────────────────────────┐
│           Mac Studio M3 Ultra            │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │         Multipass VM (Linux)       │  │
│  │                                    │  │
│  │  ┌──────────────────────────────┐  │  │
│  │  │           k3s Cluster        │  │  │
│  │  │                              │  │  │
│  │  │  ┌─────┐ ┌─────┐ ┌─────┐   │  │  │
│  │  │  │Pod 1│ │Pod 2│ │Pod 3│   │  │  │
│  │  │  └─────┘ └─────┘ └─────┘   │  │  │
│  │  └──────────────────────────────┘  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Ollama (natif)    LM Studio (natif)    │
└─────────────────────────────────────────┘
```

---

### Étape 2 : Installer Multipass

**Pourquoi ?** Sur macOS, k3s ne tourne pas nativement. On utilise Multipass pour créer une VM Linux légère qui hébergera k3s.

**Comment ?**
```bash
brew install multipass
```

**Vérification :**
```bash
multipass version
```

**Résultat attendu :**
```
multipass   1.x.x
multipassd  1.x.x
```

---

### Étape 3 : Créer une VM pour k3s

**Pourquoi ?** On crée une machine virtuelle Ubuntu qui sera notre noeud k3s. On lui donne beaucoup de ressources pour de bonnes performances.

**Comment ?**
```bash
multipass launch --name k3s-master --cpus 8 --memory 16G --disk 50G 22.04
```

**Explication des paramètres :**
- `--name k3s-master` : Nom de la VM
- `--cpus 8` : 8 coeurs CPU dédiés
- `--memory 16G` : 16 GB de RAM
- `--disk 50G` : 50 GB de disque
- `22.04` : Ubuntu 22.04 LTS

**Temps estimé :** 2-5 minutes pour télécharger et créer la VM.

**Vérification :**
```bash
multipass list
```

**Résultat attendu :**
```
Name          State       IPv4             Image
k3s-master    Running     192.168.x.x      Ubuntu 22.04 LTS
```

**Note l'adresse IP !** Tu en auras besoin plus tard.

---

### Étape 4 : Installer k3s dans la VM

**Pourquoi ?** Maintenant qu'on a notre VM Linux, on peut y installer k3s.

**Comment ?**
```bash
multipass exec k3s-master -- bash -c "curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644"
```

**Temps estimé :** 1-2 minutes.

**Vérification :**
```bash
multipass exec k3s-master -- sudo k3s kubectl get nodes
```

**Résultat attendu :**
```
NAME         STATUS   ROLES                  AGE   VERSION
k3s-master   Ready    control-plane,master   1m    v1.28.x+k3s1
```

---

### Étape 5 : Récupérer le fichier kubeconfig

**Pourquoi ?** kubeconfig est le fichier qui contient les credentials pour se connecter au cluster k3s. On doit le copier sur notre Mac.

**Comment ?**
```bash
multipass exec k3s-master -- sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/k3s-config
```

**Récupérer l'IP de la VM :**
```bash
K3S_IP=$(multipass info k3s-master | grep IPv4 | awk '{print $2}') && echo "IP de k3s: $K3S_IP"
```

**Modifier le fichier pour utiliser la bonne IP :**
```bash
sed -i '' "s/127.0.0.1/$K3S_IP/g" ~/.kube/k3s-config
```

**Configurer kubectl pour utiliser ce fichier :**
```bash
echo 'export KUBECONFIG=~/.kube/k3s-config' >> ~/.zprofile && source ~/.zprofile
```

**Vérification :**
```bash
kubectl cluster-info
```

**Résultat attendu :**
```
Kubernetes control plane is running at https://192.168.x.x:6443
CoreDNS is running at https://192.168.x.x:6443/api/v1/...
```

---

### Étape 6 : Tester la connexion au cluster

**Pourquoi ?** On veut s'assurer que kubectl sur le Mac peut bien communiquer avec k3s dans la VM.

**Comment ?**
```bash
kubectl get nodes -o wide
```

**Résultat attendu :**
```
NAME         STATUS   ROLES                  AGE   VERSION        INTERNAL-IP     ...
k3s-master   Ready    control-plane,master   5m    v1.28.x+k3s1   192.168.x.x     ...
```

**Tester les namespaces :**
```bash
kubectl get namespaces
```

**Résultat attendu :**
```
NAME              STATUS   AGE
default           Active   5m
kube-system       Active   5m
kube-public       Active   5m
kube-node-lease   Active   5m
```

---

### Étape 7 : Créer un namespace pour OpenClaw

**Pourquoi ?** Les namespaces sont comme des dossiers pour organiser les applications. On crée un namespace dédié à OpenClaw.

**Comment ?**
```bash
kubectl create namespace openclaw
```

**Définir comme namespace par défaut :**
```bash
kubectl config set-context --current --namespace=openclaw
```

**Vérification :**
```bash
kubectl config view --minify | grep namespace
```

**Résultat attendu :**
```
    namespace: openclaw
```

---

### Étape 8 : Installer Helm (gestionnaire de packages Kubernetes)

**Pourquoi ?** Helm, c'est comme Homebrew mais pour Kubernetes. Il permet d'installer des applications complexes facilement.

**Comment ?**
```bash
brew install helm
```

**Vérification :**
```bash
helm version
```

**Résultat attendu :**
```
version.BuildInfo{Version:"v3.x.x", ...}
```

**Ajouter les repos Helm utiles :**
```bash
helm repo add stable https://charts.helm.sh/stable && helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update
```

---

### Étape 9 : Configurer le stockage persistant

**Pourquoi ?** Par défaut, les données dans les conteneurs disparaissent quand ils redémarrent. On configure un stockage persistant pour garder les données.

**Comment ?**

k3s inclut déjà le stockage local-path. Vérifions qu'il fonctionne :

```bash
kubectl get storageclass
```

**Résultat attendu :**
```
NAME                   PROVISIONER             RECLAIMPOLICY   ...
local-path (default)   rancher.io/local-path   Delete          ...
```

**Créer un test de stockage persistant :**
```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: openclaw
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
EOF
```

**Vérification :**
```bash
kubectl get pvc -n openclaw
```

**Résultat attendu :**
```
NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-pvc   Pending   ...      ...        ...            local-path     1m
```

Le statut "Pending" est normal jusqu'à ce qu'un Pod utilise ce PVC.

**Nettoyer le test :**
```bash
kubectl delete pvc test-pvc -n openclaw
```

---

### Étape 10 : Configurer l'accès réseau entre Mac et k3s

**Pourquoi ?** On doit pouvoir accéder aux services k3s depuis notre Mac (par exemple, OpenClaw sur le port 18789).

**Comment ?**

**Vérifier la connectivité :**
```bash
ping -c 3 $(multipass info k3s-master | grep IPv4 | awk '{print $2}')
```

**Configurer le port forwarding automatique :**
```bash
cat << 'EOF' > ~/openclaw/config/port-forward.sh
#!/bin/bash
# Script de port-forwarding pour OpenClaw

K3S_IP=$(multipass info k3s-master | grep IPv4 | awk '{print $2}')

echo "Démarrage du port-forwarding vers $K3S_IP..."
echo "OpenClaw sera accessible sur http://localhost:18789"

# Port-forward OpenClaw (sera utilisé après le déploiement)
# kubectl port-forward -n openclaw svc/openclaw 18789:18789 &

echo "Port-forwarding prêt!"
EOF
chmod +x ~/openclaw/config/port-forward.sh
```

---

### Étape 11 : Créer un script de démarrage k3s

**Pourquoi ?** On veut pouvoir démarrer et arrêter k3s facilement.

**Comment ?**
```bash
cat << 'EOF' > ~/openclaw/k3s-control.sh
#!/bin/bash

case "$1" in
    start)
        echo "Démarrage de k3s..."
        multipass start k3s-master
        sleep 5
        kubectl get nodes
        echo "k3s démarré!"
        ;;
    stop)
        echo "Arrêt de k3s..."
        multipass stop k3s-master
        echo "k3s arrêté!"
        ;;
    status)
        echo "Statut de k3s:"
        multipass list
        echo ""
        kubectl get nodes 2>/dev/null || echo "kubectl: non connecté"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    shell)
        echo "Connexion à k3s-master..."
        multipass shell k3s-master
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart|shell}"
        exit 1
        ;;
esac
EOF
chmod +x ~/openclaw/k3s-control.sh
```

**Utilisation :**
```bash
# Voir le statut
~/openclaw/k3s-control.sh status

# Arrêter k3s
~/openclaw/k3s-control.sh stop

# Démarrer k3s
~/openclaw/k3s-control.sh start

# Se connecter à la VM
~/openclaw/k3s-control.sh shell

# Sortir de la VM (obligatoire sinon le prochain script ne marchera pas depuis la VM)
exit

```

---

### Étape 12 : Configurer k3s pour démarrer automatiquement

**Pourquoi ?** On veut que k3s démarre automatiquement quand le Mac s'allume.

**Comment ?**
```bash
cat << 'EOF' > ~/Library/LaunchAgents/com.multipass.k3s.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.multipass.k3s</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/multipass</string>
        <string>start</string>
        <string>k3s-master</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/k3s-autostart.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/k3s-autostart.error.log</string>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.multipass.k3s.plist
```

**Vérification :**
```bash
launchctl list | grep k3s
```

---

### Étape 13 : Script de vérification complète

**Pourquoi ?** Un script qui teste tout pour être sûr que k3s est prêt pour OpenClaw.

**Comment ?**
```bash
cat << 'EOF' > ~/openclaw/test-k3s.sh
#!/bin/bash
echo "=== Test k3s pour OpenClaw ==="
echo ""

# Test 1: VM active
echo "1. Vérification de la VM Multipass..."
if multipass info k3s-master > /dev/null 2>&1; then
    STATE=$(multipass info k3s-master | grep State | awk '{print $2}')
    if [ "$STATE" == "Running" ]; then
        echo "   ✅ VM k3s-master active"
    else
        echo "   ⚠️  VM k3s-master existe mais état: $STATE"
    fi
else
    echo "   ❌ VM k3s-master non trouvée"
    exit 1
fi

# Test 2: kubectl connecté
echo ""
echo "2. Vérification de kubectl..."
if kubectl cluster-info > /dev/null 2>&1; then
    echo "   ✅ kubectl connecté au cluster"
else
    echo "   ❌ kubectl non connecté"
    exit 1
fi

# Test 3: Noeud prêt
echo ""
echo "3. Vérification du noeud k3s..."
NODE_STATUS=$(kubectl get nodes --no-headers | awk '{print $2}')
if [ "$NODE_STATUS" == "Ready" ]; then
    echo "   ✅ Noeud k3s prêt"
else
    echo "   ⚠️  Noeud k3s: $NODE_STATUS"
fi

# Test 4: Namespace openclaw
echo ""
echo "4. Vérification du namespace openclaw..."
if kubectl get namespace openclaw > /dev/null 2>&1; then
    echo "   ✅ Namespace openclaw existe"
else
    echo "   ⚠️  Namespace openclaw n'existe pas"
    echo "   Création du namespace..."
    kubectl create namespace openclaw
fi

# Test 5: Stockage
echo ""
echo "5. Vérification du stockage..."
STORAGE_CLASS=$(kubectl get storageclass --no-headers | awk '{print $1}')
if [ -n "$STORAGE_CLASS" ]; then
    echo "   ✅ StorageClass disponible: $STORAGE_CLASS"
else
    echo "   ❌ Pas de StorageClass configuré"
fi

# Test 6: Réseau
echo ""
echo "6. Vérification du réseau..."
K3S_IP=$(multipass info k3s-master | grep IPv4 | awk '{print $2}')
if ping -c 1 $K3S_IP > /dev/null 2>&1; then
    echo "   ✅ Réseau OK (IP: $K3S_IP)"
else
    echo "   ❌ Impossible de joindre la VM"
fi

# Test 7: API k3s
echo ""
echo "7. Vérification de l'API k3s..."
if kubectl get --raw /healthz > /dev/null 2>&1; then
    echo "   ✅ API k3s saine"
else
    echo "   ❌ API k3s non accessible"
fi

# Résumé
echo ""
echo "=== Résumé ==="
echo "K3S_IP: $K3S_IP"
echo "API: https://$K3S_IP:6443"
echo "Kubeconfig: $KUBECONFIG"
echo ""
echo "=== Tests terminés ==="
EOF
chmod +x ~/openclaw/test-k3s.sh
```

**Exécuter les tests :**
```bash
~/openclaw/test-k3s.sh
```

**Résultat attendu :**
```
=== Test k3s pour OpenClaw ===

1. Vérification de la VM Multipass...
   ✅ VM k3s-master active

2. Vérification de kubectl...
   ✅ kubectl connecté au cluster

3. Vérification du noeud k3s...
   ✅ Noeud k3s prêt

4. Vérification du namespace openclaw...
   ✅ Namespace openclaw existe

5. Vérification du stockage...
   ✅ StorageClass disponible: local-path

6. Vérification du réseau...
   ✅ Réseau OK (IP: 192.168.x.x)

7. Vérification de l'API k3s...
   ✅ API k3s saine

=== Résumé ===
K3S_IP: 192.168.x.x
API: https://192.168.x.x:6443
Kubeconfig: /Users/xxx/.kube/k3s-config

=== Tests terminés ===
```

---

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] Multipass est installé
- [ ] La VM k3s-master est créée et en état "Running"
- [ ] k3s est installé dans la VM
- [ ] Le fichier kubeconfig est copié sur le Mac
- [ ] kubectl peut se connecter au cluster
- [ ] Le noeud k3s est en état "Ready"
- [ ] Le namespace "openclaw" est créé
- [ ] Helm est installé
- [ ] Le stockage local-path fonctionne
- [ ] Le réseau entre Mac et VM fonctionne
- [ ] Le script de test passe sans erreur

---

## ⚠️ Dépannage

### La VM ne démarre pas
**Symptôme :** "multipass start" échoue
**Solution :**
```bash
multipass stop k3s-master && multipass delete k3s-master && multipass purge && multipass launch --name k3s-master --cpus 8 --memory 16G --disk 50G 22.04
```

### kubectl ne se connecte pas
**Symptôme :** "Unable to connect to the server"
**Solutions :**
1. Vérifie que la VM tourne :
```bash
multipass list
```
2. Récupère à nouveau le kubeconfig :
```bash
multipass exec k3s-master -- sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/k3s-config
```
3. Mets à jour l'IP :
```bash
K3S_IP=$(multipass info k3s-master | grep IPv4 | awk '{print $2}') && sed -i '' "s/127.0.0.1/$K3S_IP/g" ~/.kube/k3s-config
```

### Le noeud reste en "NotReady"
**Symptôme :** Le noeud n'est pas prêt
**Solution :**
```bash
multipass exec k3s-master -- sudo systemctl restart k3s
```
Attends 30 secondes et revérifie.

### Erreur "permission denied" sur kubeconfig
**Symptôme :** kubectl refuse d'utiliser le fichier
**Solution :**
```bash
chmod 600 ~/.kube/k3s-config
```

### La VM est très lente
**Symptôme :** kubectl met longtemps à répondre
**Solutions :**
1. Augmente les ressources de la VM :
```bash
multipass stop k3s-master && multipass set local.k3s-master.cpus=12 && multipass set local.k3s-master.memory=24G && multipass start k3s-master
```
2. Ou recrée la VM avec plus de ressources.

### Erreur Multipass "Instance not found"
**Symptôme :** La VM a disparu
**Solution :**
Recrée la VM depuis l'étape 3.

---

## 🔗 Ressources

- [Documentation k3s](https://docs.k3s.io/)
- [Documentation Multipass](https://multipass.run/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)

---

## 📊 Récapitulatif des composants

| Composant | Rôle | Port |
|-----------|------|------|
| Multipass | Gestionnaire de VM | - |
| k3s-master | VM Linux avec k3s | - |
| k3s API | API Kubernetes | 6443 |
| CoreDNS | DNS interne | 53 |
| Traefik | Ingress Controller | 80, 443 |
| local-path | Stockage persistant | - |

---

## ➡️ Prochaine étape

k3s est installé et fonctionnel ! Tu as maintenant un vrai cluster Kubernetes léger qui tourne sur ton Mac Studio. Dans le prochain chapitre, on va enfin déployer **OpenClaw** dans ce cluster.

**Chapitre suivant :** [2.5 - Déploiement OpenClaw dans k3s](./05-deploiement-openclaw.md)
