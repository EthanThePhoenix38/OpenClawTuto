# 🎯 2.6 - Configuration réseau isolé

## 📋 Ce que tu vas apprendre
- Comment isoler Phoenix du réseau Internet
- Comment configurer le pare-feu macOS
- Comment créer des règles réseau Kubernetes
- Comment sécuriser les communications entre composants

## 🛠️ Prérequis
- Chapitre 2.5 complété (Phoenix déployé et fonctionnel)
- Accès administrateur sur le Mac
- kubectl connecté au cluster k3s

## 📝 Étapes détaillées

### Étape 1 : Comprendre l'isolation réseau

**Pourquoi ?** On veut que notre IA locale reste locale ! Aucune donnée ne doit partir sur Internet sans notre permission explicite.

**Ce qu'on va bloquer :**
- Connexions sortantes vers Internet depuis les pods
- Connexions entrantes depuis Internet
- Communications non autorisées entre pods

**Ce qu'on va autoriser :**
- Communication entre Phoenix et PostgreSQL
- Communication entre Phoenix et Ollama/LM Studio sur le Mac
- Accès depuis le Mac local uniquement

**Architecture réseau cible :**
```
┌─────────────────────────────────────────────────────────┐
│                      Mac Studio                          │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │                  Réseau local (192.168.x.x)        │ │
│  │                                                    │ │
│  │   ┌─────────┐     ┌─────────┐     ┌─────────┐    │ │
│  │   │ Browser │────▶│Phoenix │────▶│ Ollama  │    │ │
│  │   │localhost│     │ :18789  │     │ :11434  │    │ │
│  │   └─────────┘     └────┬────┘     └─────────┘    │ │
│  │                        │                          │ │
│  │                        ▼                          │ │
│  │                   ┌─────────┐                     │ │
│  │                   │Postgres │                     │ │
│  │                   │ :5432   │                     │ │
│  │                   └─────────┘                     │ │
│  └────────────────────────────────────────────────────┘ │
│                           │                              │
│                           ✖ BLOQUÉ vers Internet         │
│                                                          │
└─────────────────────────────────────────────────────────┘
                            │
                            ✖
                      ┌─────────────┐
                      │  Internet   │
                      └─────────────┘
```

---

### Étape 2 : Configurer le pare-feu macOS (pf)

**Pourquoi ?** Le pare-feu pf (Packet Filter) va bloquer les connexions non autorisées au niveau du système.

**Créer les règles du pare-feu :**
```bash
sudo cat << 'EOF' > /etc/pf.anchors/phoenix
# Règles pare-feu Phoenix
# Bloque tout trafic sortant des ports Phoenix vers Internet

# Définition des variables
ollama_port = "11434"
lmstudio_port = "1234"
phoenix_port = "18789"
k3s_port = "6443"
postgres_port = "5432"

# Interface loopback toujours autorisée
pass quick on lo0 all

# Autoriser le trafic local (192.168.x.x et 10.x.x.x)
pass quick from 192.168.0.0/16 to 192.168.0.0/16
pass quick from 10.0.0.0/8 to 10.0.0.0/8
pass quick from 127.0.0.0/8 to 127.0.0.0/8

# Autoriser les connexions établies
pass quick proto tcp from any to any flags S/SA keep state
pass quick proto udp from any to any keep state

# Bloquer le trafic sortant vers Internet depuis les ports sensibles
block out quick proto tcp from any port $ollama_port to ! 192.168.0.0/16
block out quick proto tcp from any port $lmstudio_port to ! 192.168.0.0/16
block out quick proto tcp from any port $phoenix_port to ! 192.168.0.0/16
EOF
```

**Charger les règles :**
```bash
echo 'anchor "phoenix"' | sudo tee -a /etc/pf.conf && echo 'load anchor "phoenix" from "/etc/pf.anchors/phoenix"' | sudo tee -a /etc/pf.conf
```

**Activer le pare-feu :**
```bash
sudo pfctl -ef /etc/pf.conf
```

**Vérification :**
```bash
sudo pfctl -sr | grep phoenix
```

---

### Étape 3 : Configurer le pare-feu applicatif macOS

**Pourquoi ?** En plus de pf, on configure le pare-feu intégré de macOS pour une double protection.

**Comment (GUI) :**
1. Ouvre "Préférences Système"
2. Va dans "Confidentialité et sécurité" > "Pare-feu"
3. Clique sur "Options du pare-feu..."
4. Active "Bloquer toutes les connexions entrantes" (temporairement désactivé pour les tests)
5. Ajoute Ollama et LM Studio aux applications autorisées

**Comment (Terminal) :**
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on && sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Ollama.app && sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "/Applications/LM Studio.app"
```

**Vérification :**
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
```

---

### Étape 4 : Créer les Network Policies Kubernetes

**Pourquoi ?** Les Network Policies contrôlent les communications entre pods dans k3s. C'est comme un pare-feu dans le cluster.

**Installer Calico pour les Network Policies (k3s de base ne les supporte pas complètement) :**
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

**Attendre que Calico soit prêt :**
```bash
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=120s
```

**Créer la policy par défaut (deny all) :**
```bash
cat << 'EOF' > ~/phoenix/k8s/base/network-policy-default.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: phoenix
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF
kubectl apply -f ~/phoenix/k8s/base/network-policy-default.yaml
```

**Créer la policy pour Phoenix :**
```bash
cat << 'EOF' > ~/phoenix/k8s/base/network-policy-phoenix.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: phoenix-policy
  namespace: phoenix
spec:
  podSelector:
    matchLabels:
      app: phoenix
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Autoriser le trafic depuis le même namespace
    - from:
        - namespaceSelector:
            matchLabels:
              name: phoenix
      ports:
        - protocol: TCP
          port: 18789
    # Autoriser le trafic depuis l'extérieur du cluster (le Mac)
    - from: []
      ports:
        - protocol: TCP
          port: 18789
  egress:
    # Autoriser la connexion à PostgreSQL
    - to:
        - podSelector:
            matchLabels:
              app: phoenix-db
      ports:
        - protocol: TCP
          port: 5432
    # Autoriser la connexion DNS
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    # Autoriser la connexion au Mac (Ollama/LM Studio)
    - to:
        - ipBlock:
            cidr: 192.168.0.0/16
      ports:
        - protocol: TCP
          port: 11434
        - protocol: TCP
          port: 1234
EOF
kubectl apply -f ~/phoenix/k8s/base/network-policy-phoenix.yaml
```

**Créer la policy pour PostgreSQL :**
```bash
cat << 'EOF' > ~/phoenix/k8s/base/network-policy-postgres.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-policy
  namespace: phoenix
spec:
  podSelector:
    matchLabels:
      app: phoenix-db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Seulement Phoenix peut se connecter
    - from:
        - podSelector:
            matchLabels:
              app: phoenix
      ports:
        - protocol: TCP
          port: 5432
  egress:
    # PostgreSQL n'a pas besoin de sortir
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
EOF
kubectl apply -f ~/phoenix/k8s/base/network-policy-postgres.yaml
```

**Vérification :**
```bash
kubectl get networkpolicy -n phoenix
```

**Résultat attendu :**
```
NAME               POD-SELECTOR       AGE
default-deny-all   <none>             1m
phoenix-policy    app=phoenix       1m
postgres-policy    app=phoenix-db    1m
```

---

### Étape 5 : Configurer Ollama en mode local uniquement

**Pourquoi ?** On veut qu'Ollama n'écoute que sur les interfaces locales.

**Comment ?**
```bash
cat << 'EOF' >> ~/.zprofile
# Ollama - Mode local uniquement
export OLLAMA_HOST="127.0.0.1:11434"
export OLLAMA_ORIGINS="http://localhost:*,http://127.0.0.1:*,http://192.168.*.*:*"
EOF
source ~/.zprofile
```

**Pour permettre l'accès depuis k3s (VM Multipass), modifier temporairement :**
```bash
export OLLAMA_HOST="0.0.0.0:11434"
```

**Script pour basculer entre modes :**
```bash
cat << 'EOF' > ~/phoenix/ollama-mode.sh
#!/bin/bash
case "$1" in
    local)
        export OLLAMA_HOST="127.0.0.1:11434"
        echo "Ollama en mode LOCAL uniquement"
        echo "Redémarre Ollama pour appliquer"
        ;;
    network)
        export OLLAMA_HOST="0.0.0.0:11434"
        echo "Ollama en mode RÉSEAU (pour k3s)"
        echo "Redémarre Ollama pour appliquer"
        ;;
    status)
        echo "OLLAMA_HOST actuel: $OLLAMA_HOST"
        lsof -i :11434 | head -5
        ;;
    *)
        echo "Usage: $0 {local|network|status}"
        ;;
esac
EOF
chmod +x ~/phoenix/ollama-mode.sh
```

---

### Étape 6 : Bloquer l'accès Internet pour les modèles IA

**Pourquoi ?** On s'assure que les modèles ne peuvent pas "téléphoner maison" ou envoyer des données à l'extérieur.

**Créer les règles iptables dans la VM k3s :**
```bash
multipass exec k3s-master -- sudo bash -c 'cat << "EOF" > /etc/iptables.rules
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# Autoriser le loopback
-A OUTPUT -o lo -j ACCEPT

# Autoriser les connexions établies
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Autoriser le trafic vers le réseau local
-A OUTPUT -d 192.168.0.0/16 -j ACCEPT
-A OUTPUT -d 10.0.0.0/8 -j ACCEPT
-A OUTPUT -d 172.16.0.0/12 -j ACCEPT

# Autoriser DNS
-A OUTPUT -p udp --dport 53 -j ACCEPT
-A OUTPUT -p tcp --dport 53 -j ACCEPT

# Bloquer tout le reste vers Internet
-A OUTPUT -d 0.0.0.0/0 -j DROP

COMMIT
EOF'
```

**Appliquer les règles :**
```bash
multipass exec k3s-master -- sudo iptables-restore < /etc/iptables.rules
```

**Rendre persistant :**
```bash
multipass exec k3s-master -- sudo bash -c 'apt-get update && apt-get install -y iptables-persistent && netfilter-persistent save'
```

**Vérification :**
```bash
multipass exec k3s-master -- sudo iptables -L OUTPUT -n
```

---

### Étape 7 : Configurer les accès par IP uniquement

**Pourquoi ?** On limite l'accès à Phoenix à certaines adresses IP.

**Créer un fichier d'IP autorisées :**
```bash
cat << 'EOF' > ~/phoenix/config/allowed-ips.txt
# IPs autorisées à accéder à Phoenix
127.0.0.1
192.168.1.0/24
10.0.0.0/8
EOF
```

**Mettre à jour la Network Policy :**
```bash
cat << 'EOF' > ~/phoenix/k8s/base/network-policy-whitelist.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: phoenix-ip-whitelist
  namespace: phoenix
spec:
  podSelector:
    matchLabels:
      app: phoenix
  policyTypes:
    - Ingress
  ingress:
    - from:
        # Localhost
        - ipBlock:
            cidr: 127.0.0.1/32
        # Réseau local typique
        - ipBlock:
            cidr: 192.168.0.0/16
        # Réseau Multipass
        - ipBlock:
            cidr: 10.0.0.0/8
      ports:
        - protocol: TCP
          port: 18789
EOF
kubectl apply -f ~/phoenix/k8s/base/network-policy-whitelist.yaml
```

---

### Étape 8 : Activer les logs de sécurité

**Pourquoi ?** On veut savoir si quelqu'un essaie d'accéder à notre système.

**Créer un ConfigMap pour les logs :**
```bash
cat << 'EOF' > ~/phoenix/k8s/base/logging-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logging-config
  namespace: phoenix
data:
  LOG_LEVEL: "info"
  LOG_SECURITY: "true"
  LOG_ACCESS: "true"
  LOG_FORMAT: "json"
EOF
kubectl apply -f ~/phoenix/k8s/base/logging-config.yaml
```

**Script pour surveiller les tentatives de connexion :**
```bash
cat << 'EOF' > ~/phoenix/monitor-access.sh
#!/bin/bash
echo "=== Surveillance des accès Phoenix ==="
echo "Appuie sur Ctrl+C pour arrêter"
echo ""

# Suivre les logs Phoenix en temps réel
kubectl logs -n phoenix -l app=phoenix -f --since=1m | while read line; do
    # Filtrer les accès
    if echo "$line" | grep -qE "(access|connection|auth|security)"; then
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$TIMESTAMP] $line"
    fi
done
EOF
chmod +x ~/phoenix/monitor-access.sh
```

**Surveiller les connexions réseau :**
```bash
cat << 'EOF' > ~/phoenix/monitor-network.sh
#!/bin/bash
echo "=== Surveillance réseau Phoenix ==="
echo ""

echo "1. Connexions actives sur les ports Phoenix :"
lsof -i :11434 -i :1234 -i :18789 -i :6443 | grep -v "^COMMAND"

echo ""
echo "2. Connexions depuis/vers la VM k3s :"
K3S_IP=$(multipass info k3s-master | grep IPv4 | awk '{print $2}')
netstat -an | grep $K3S_IP

echo ""
echo "3. Tentatives de connexion bloquées (pare-feu) :"
sudo log show --predicate 'process == "socketfilterfw"' --last 5m 2>/dev/null | tail -10

echo ""
echo "=== Fin de la surveillance ==="
EOF
chmod +x ~/phoenix/monitor-network.sh
```

---

### Étape 9 : Test d'isolation complet

**Pourquoi ?** On vérifie que l'isolation fonctionne correctement.

**Script de test :**
```bash
cat << 'EOF' > ~/phoenix/test-isolation.sh
#!/bin/bash
echo "=== Test d'isolation réseau Phoenix ==="
echo ""

# Test 1: Vérifier que Phoenix est accessible localement
echo "1. Test accès local à Phoenix..."
if curl -s http://localhost:18789/health > /dev/null 2>&1; then
    echo "   ✅ Phoenix accessible localement"
else
    # Démarrer port-forward si nécessaire
    kubectl port-forward -n phoenix svc/phoenix 18789:18789 &>/dev/null &
    sleep 2
    if curl -s http://localhost:18789/health > /dev/null 2>&1; then
        echo "   ✅ Phoenix accessible (via port-forward)"
    else
        echo "   ❌ Phoenix non accessible"
    fi
fi

# Test 2: Vérifier qu'Ollama est accessible
echo ""
echo "2. Test accès à Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "   ✅ Ollama accessible"
else
    echo "   ❌ Ollama non accessible"
fi

# Test 3: Vérifier que les pods ne peuvent pas accéder à Internet
echo ""
echo "3. Test isolation Internet des pods..."
INTERNET_TEST=$(kubectl run -n phoenix test-internet --image=curlimages/curl --rm -it --restart=Never -- curl -s --connect-timeout 5 http://google.com 2>/dev/null)
if [ -z "$INTERNET_TEST" ]; then
    echo "   ✅ Pods isolés d'Internet"
else
    echo "   ⚠️  Pods peuvent accéder à Internet"
fi

# Test 4: Vérifier les Network Policies
echo ""
echo "4. Network Policies actives :"
kubectl get networkpolicy -n phoenix --no-headers | while read line; do
    echo "   - $line"
done

# Test 5: Vérifier le pare-feu macOS
echo ""
echo "5. État du pare-feu macOS :"
FW_STATUS=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
echo "   $FW_STATUS"

# Test 6: Ports ouverts
echo ""
echo "6. Ports Phoenix ouverts :"
echo "   - 11434 (Ollama): $(lsof -i :11434 | grep LISTEN | wc -l | tr -d ' ') processus"
echo "   - 1234 (LM Studio): $(lsof -i :1234 | grep LISTEN | wc -l | tr -d ' ') processus"
echo "   - 18789 (Phoenix): $(lsof -i :18789 | grep LISTEN | wc -l | tr -d ' ') processus"
echo "   - 6443 (k3s): $(lsof -i :6443 | grep LISTEN | wc -l | tr -d ' ') processus"

echo ""
echo "=== Test d'isolation terminé ==="
EOF
chmod +x ~/phoenix/test-isolation.sh
```

**Exécuter le test :**
```bash
~/phoenix/test-isolation.sh
```

**Résultat attendu :**
```
=== Test d'isolation réseau Phoenix ===

1. Test accès local à Phoenix...
   ✅ Phoenix accessible localement

2. Test accès à Ollama...
   ✅ Ollama accessible

3. Test isolation Internet des pods...
   ✅ Pods isolés d'Internet

4. Network Policies actives :
   - default-deny-all   <none>
   - phoenix-policy    app=phoenix
   - postgres-policy    app=phoenix-db

5. État du pare-feu macOS :
   Firewall is enabled.

6. Ports Phoenix ouverts :
   - 11434 (Ollama): 1 processus
   - 1234 (LM Studio): 1 processus
   - 18789 (Phoenix): 1 processus
   - 6443 (k3s): 1 processus

=== Test d'isolation terminé ===
```

---

### Étape 10 : Script de sécurité global

**Pourquoi ?** Un script unique pour gérer toute la sécurité.

**Comment ?**
```bash
cat << 'EOF' > ~/phoenix/security-control.sh
#!/bin/bash

show_status() {
    echo "=== État de la sécurité Phoenix ==="
    echo ""
    echo "Pare-feu macOS:"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null
    echo ""
    echo "pf (Packet Filter):"
    sudo pfctl -s info 2>/dev/null | head -5
    echo ""
    echo "Network Policies k8s:"
    kubectl get networkpolicy -n phoenix --no-headers 2>/dev/null
    echo ""
    echo "Connexions actives:"
    netstat -an | grep -E ":(11434|1234|18789|6443)" | grep LISTEN
}

enable_security() {
    echo "Activation de toutes les protections..."

    # Pare-feu macOS
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

    # pf
    sudo pfctl -ef /etc/pf.conf 2>/dev/null

    # Network Policies
    kubectl apply -f ~/phoenix/k8s/base/network-policy-default.yaml
    kubectl apply -f ~/phoenix/k8s/base/network-policy-phoenix.yaml
    kubectl apply -f ~/phoenix/k8s/base/network-policy-postgres.yaml

    echo "✅ Protections activées"
}

disable_security() {
    echo "⚠️  Désactivation des protections (pour debug uniquement)..."

    # Supprimer les Network Policies
    kubectl delete networkpolicy --all -n phoenix 2>/dev/null

    echo "⚠️  Network Policies désactivées"
    echo "Note: Le pare-feu macOS reste actif pour la sécurité de base"
}

case "$1" in
    status)
        show_status
        ;;
    enable)
        enable_security
        ;;
    disable)
        disable_security
        ;;
    test)
        ~/phoenix/test-isolation.sh
        ;;
    *)
        echo "Usage: $0 {status|enable|disable|test}"
        echo ""
        echo "Commandes:"
        echo "  status  - Affiche l'état de la sécurité"
        echo "  enable  - Active toutes les protections"
        echo "  disable - Désactive les Network Policies (debug)"
        echo "  test    - Lance les tests d'isolation"
        ;;
esac
EOF
chmod +x ~/phoenix/security-control.sh
```

**Utilisation :**
```bash
# Voir le statut
~/phoenix/security-control.sh status

# Activer toutes les protections
~/phoenix/security-control.sh enable

# Tester l'isolation
~/phoenix/security-control.sh test
```

---

## ✅ Checklist

Avant de terminer cette partie, vérifie que :

- [ ] Le pare-feu pf est configuré et actif
- [ ] Le pare-feu applicatif macOS est activé
- [ ] Calico est installé dans k3s
- [ ] La Network Policy "deny all" est appliquée
- [ ] Les Network Policies Phoenix et PostgreSQL sont appliquées
- [ ] Ollama est configuré en mode local
- [ ] Les règles iptables sont appliquées dans la VM k3s
- [ ] Les tests d'isolation passent
- [ ] Les scripts de surveillance sont créés
- [ ] Le script de contrôle de sécurité fonctionne

---

## ⚠️ Dépannage

### Phoenix ne peut plus joindre Ollama
**Symptôme :** Erreur de connexion à l'IA
**Solution :**
1. Vérifie que la Network Policy autorise le trafic :
```bash
kubectl describe networkpolicy phoenix-policy -n phoenix
```
2. Vérifie qu'Ollama écoute sur la bonne interface :
```bash
lsof -i :11434
```

### Les pods ne démarrent plus
**Symptôme :** Pods bloqués en "ContainerCreating"
**Solution :** La policy "deny all" peut bloquer les requêtes DNS :
```bash
kubectl delete networkpolicy default-deny-all -n phoenix
```
Puis recrée-la avec les bonnes exceptions DNS.

### Impossible d'accéder à Phoenix depuis le navigateur
**Symptôme :** Connexion refusée
**Solutions :**
1. Vérifie le port-forward :
```bash
ps aux | grep port-forward
```
2. Relance-le si nécessaire :
```bash
kubectl port-forward -n phoenix svc/phoenix 18789:18789
```

### Le pare-feu bloque trop de choses
**Symptôme :** Applications qui ne marchent plus
**Solution :** Désactive temporairement pf :
```bash
sudo pfctl -d
```
Puis réajuste les règles.

### Les logs montrent des tentatives de connexion suspectes
**Symptôme :** Beaucoup de connexions refusées dans les logs
**Solution :** C'est normal si les règles fonctionnent ! Vérifie les sources :
```bash
~/phoenix/monitor-network.sh
```

---

## 🔗 Ressources

- [Documentation pf macOS](https://man.freebsd.org/cgi/man.cgi?pf.conf)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/about/)
- [macOS Security Guide](https://support.apple.com/guide/security/welcome/web)

---

## 📊 Récapitulatif de la sécurité

| Couche | Protection | Port/Service |
|--------|------------|--------------|
| macOS | Pare-feu applicatif | Toutes les apps |
| macOS | pf (Packet Filter) | 11434, 1234, 18789 |
| k3s | Network Policies | Tous les pods |
| k3s | iptables | Trafic sortant |
| Application | CORS | API Phoenix |

---

## 🎉 Félicitations !

Tu as terminé la **PARTIE 2 : INSTALLER** !

**Ce que tu as accompli :**
1. Préparé ton Mac Studio avec tous les outils nécessaires
2. Installé Ollama pour faire tourner les modèles IA nativement
3. Installé LM Studio pour tester et comparer les modèles
4. Déployé k3s, un cluster Kubernetes léger
5. Déployé Phoenix version 2026.1.30
6. Sécurisé tout le système avec une isolation réseau complète

**Tu as maintenant :**
- Une IA locale qui tourne sur le GPU M3 Ultra
- Une interface web pour interagir avec l'IA
- Un système complètement isolé d'Internet
- Des outils de surveillance et de contrôle

---

## ➡️ Prochaine partie

Dans la **PARTIE 3 : CONFIGURER**, on va personnaliser Phoenix pour tes besoins :
- Ajouter des utilisateurs
- Configurer les modèles par défaut
- Personnaliser l'interface
- Configurer les backups automatiques

**Chapitre suivant :** [3.1 - Configuration des utilisateurs](../03-configurer/01-configuration-utilisateurs.md)
