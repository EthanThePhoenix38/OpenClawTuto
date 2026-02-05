# 🎯 Chapitre 4 - Network Policies (Deny-All + Whitelist)

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas implémenter des Network Policies Kubernetes qui contrôlent strictement tous les flux réseau vers et depuis OpenClaw. C'est la couche de défense réseau de ton architecture Zero Trust.

- **Pourquoi les Network Policies ?** Par défaut, tous les Pods Kubernetes peuvent communiquer entre eux. C'est dangereux : un Pod compromis pourrait attaquer d'autres services.
- **Approche Deny-All + Whitelist** : On bloque TOUT par défaut, puis on autorise explicitement uniquement les flux nécessaires.
- **Microsegmentation** : Chaque composant (OpenClaw, Squid, LLM) a ses propres règles réseau.

## 🛠️ Prérequis

- Namespace `openclaw-sandbox` avec Pods configurés (Chapitres 1-3)
- Proxy Squid déployé et fonctionnel
- Un CNI qui supporte les Network Policies (Calico, Cilium, ou autre)

**Important** : Vérifie que ton cluster supporte les Network Policies :

```bash
kubectl api-resources | grep networkpolicies
```

## 📝 Étapes détaillées

### Étape 1 : Vérifier le support des Network Policies

**Pourquoi ?** Tous les clusters Kubernetes ne supportent pas les Network Policies par défaut. Le CNI (Container Network Interface) doit les implémenter.

**Comment ?**

Vérifie le CNI installé :

```bash
kubectl get pods -n kube-system -o wide | grep -E "calico|cilium|weave|flannel" || echo "CNI non identifié - vérifier manuellement"
```

Si tu utilises un cluster local (kind, minikube), active le support :

Pour kind avec Calico :
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml 2>/dev/null || echo "Calico déjà installé ou non applicable"
```

**Vérification :**

```bash
kubectl get networkpolicies -A 2>/dev/null && echo "Network Policies supportées" || echo "ATTENTION: Network Policies non supportées"
```

### Étape 2 : Créer la politique Deny-All par défaut

**Pourquoi ?** La première règle de sécurité réseau Zero Trust est de tout bloquer par défaut. Aucun trafic entrant ni sortant n'est autorisé sans règle explicite.

**Comment ?**

```bash
cat << 'EOF' > /tmp/network-policy-deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: openclaw-sandbox
spec:
  podSelector: {}  # S'applique à TOUS les pods du namespace
  policyTypes:
  - Ingress
  - Egress
  # Pas de règles = tout est bloqué
EOF
```

```bash
kubectl apply -f /tmp/network-policy-deny-all.yaml
```

**Vérification :**

```bash
kubectl get networkpolicy default-deny-all -n openclaw-sandbox && kubectl describe networkpolicy default-deny-all -n openclaw-sandbox
```

### Étape 3 : Autoriser le trafic DNS

**Pourquoi ?** Sans DNS, aucune résolution de noms ne fonctionne. Les Pods ne peuvent pas résoudre les noms de services Kubernetes ni les domaines externes.

**Comment ?**

```bash
cat << 'EOF' > /tmp/network-policy-allow-dns.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: openclaw-sandbox
spec:
  podSelector: {}  # S'applique à tous les pods
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
```

```bash
kubectl apply -f /tmp/network-policy-allow-dns.yaml
```

**Vérification :**

```bash
kubectl get networkpolicy allow-dns -n openclaw-sandbox -o yaml | grep -A20 "egress"
```

### Étape 4 : Configurer les règles pour OpenClaw

**Pourquoi ?** OpenClaw doit pouvoir communiquer avec le proxy Squid et le service LLM local (hors Docker). On définit précisément ces flux.

**Comment ?**

```bash
cat << 'EOF' > /tmp/network-policy-openclaw.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: openclaw-network-policy
  namespace: openclaw-sandbox
spec:
  podSelector:
    matchLabels:
      app: openclaw
  policyTypes:
  - Ingress
  - Egress

  ingress:
  # Autoriser le trafic depuis le service d'API interne uniquement
  - from:
    - podSelector:
        matchLabels:
          app: openclaw-api
    ports:
    - protocol: TCP
      port: 8080

  egress:
  # 1. Accès au proxy Squid (seul chemin vers Internet)
  - to:
    - podSelector:
        matchLabels:
          app: squid-proxy
    ports:
    - protocol: TCP
      port: 3128

  # 2. Accès au LLM local (hors cluster, sur le Mac)
  # Le LLM tourne sur le Mac hôte, pas dans Kubernetes
  - to:
    - ipBlock:
        cidr: 192.168.0.0/16  # Réseau local Mac
    ports:
    - protocol: TCP
      port: 11434  # Port Ollama
    - protocol: TCP
      port: 8000   # Port API LLM custom

  # 3. Accès aux services Kubernetes internes
  - to:
    - podSelector:
        matchLabels:
          app: openclaw-api
    ports:
    - protocol: TCP
      port: 8080
EOF
```

```bash
kubectl apply -f /tmp/network-policy-openclaw.yaml
```

**Vérification :**

```bash
kubectl get networkpolicy openclaw-network-policy -n openclaw-sandbox && kubectl describe networkpolicy openclaw-network-policy -n openclaw-sandbox | grep -A30 "Spec"
```

### Étape 5 : Configurer les règles pour Squid Proxy

**Pourquoi ?** Squid est le seul point de sortie vers Internet. Il doit accepter les connexions d'OpenClaw et pouvoir accéder aux domaines whitelistés.

**Comment ?**

```bash
cat << 'EOF' > /tmp/network-policy-squid.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: squid-proxy-network-policy
  namespace: openclaw-sandbox
spec:
  podSelector:
    matchLabels:
      app: squid-proxy
  policyTypes:
  - Ingress
  - Egress

  ingress:
  # Accepter les connexions depuis OpenClaw uniquement
  - from:
    - podSelector:
        matchLabels:
          app: openclaw
    ports:
    - protocol: TCP
      port: 3128

  egress:
  # Accès à Internet (HTTPS uniquement)
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        # Bloquer les réseaux privés (pas d'accès au Mac ni au cluster)
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
        - 169.254.0.0/16
    ports:
    - protocol: TCP
      port: 443  # HTTPS uniquement
    - protocol: TCP
      port: 80   # HTTP (redirections)
EOF
```

```bash
kubectl apply -f /tmp/network-policy-squid.yaml
```

**Vérification :**

```bash
kubectl get networkpolicy squid-proxy-network-policy -n openclaw-sandbox && kubectl describe networkpolicy squid-proxy-network-policy -n openclaw-sandbox | grep -A50 "Spec"
```

### Étape 6 : Bloquer l'accès direct au Mac depuis les containers

**Pourquoi ?** C'est une règle CRITIQUE : OpenClaw ne doit JAMAIS pouvoir accéder directement aux ressources du Mac (fichiers, services, SSH). Seul le LLM local est accessible via des ports spécifiques.

**Comment ?**

La politique `openclaw-network-policy` autorise déjà uniquement les ports LLM. Ajoutons une politique explicite de blocage pour plus de clarté :

```bash
cat << 'EOF' > /tmp/network-policy-block-host.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-direct-host-access
  namespace: openclaw-sandbox
  annotations:
    description: "Bloque l'accès direct au Mac sauf ports LLM explicitement autorisés"
spec:
  podSelector:
    matchLabels:
      app: openclaw
  policyTypes:
  - Egress
  egress:
  # Cette règle est PLUS RESTRICTIVE que la règle générale
  # Elle s'applique spécifiquement aux réseaux du Mac
  - to:
    - ipBlock:
        cidr: 192.168.0.0/16
    ports:
    # SEULS ces ports sont autorisés vers le Mac
    - protocol: TCP
      port: 11434  # Ollama
    - protocol: TCP
      port: 8000   # API LLM custom
    # TOUS les autres ports sont BLOQUÉS implicitement
    # Notamment :
    # - Port 22 (SSH) : BLOQUÉ
    # - Port 80/443 (Web) : BLOQUÉ
    # - Port 5432 (PostgreSQL) : BLOQUÉ
    # - Port 3306 (MySQL) : BLOQUÉ
    # - Port 6379 (Redis) : BLOQUÉ
EOF
```

```bash
kubectl apply -f /tmp/network-policy-block-host.yaml
```

**Vérification :**

```bash
kubectl get networkpolicy block-direct-host-access -n openclaw-sandbox && echo "Ports autorisés vers le Mac: 11434 (Ollama), 8000 (API LLM)"
```

### Étape 7 : Tester les Network Policies

**Pourquoi ?** Les Network Policies sont complexes. Il faut valider que les flux autorisés fonctionnent ET que les flux bloqués sont bien bloqués.

**Comment ?**

Crée un Pod de test :

```bash
cat << 'EOF' > /tmp/test-network-policy.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-netpol
  namespace: openclaw-sandbox
  labels:
    app: openclaw  # Simule OpenClaw pour tester les politiques
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: test
    image: nicolaka/netshoot:latest
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
  restartPolicy: Never
EOF
```

```bash
kubectl apply -f /tmp/test-network-policy.yaml && sleep 10 && kubectl get pod test-netpol -n openclaw-sandbox
```

**Tests de connectivité :**

Test 1 - DNS (doit fonctionner) :
```bash
kubectl exec test-netpol -n openclaw-sandbox -- nslookup google.com 2>&1 | head -5
```

Test 2 - Proxy Squid (doit fonctionner) :
```bash
kubectl exec test-netpol -n openclaw-sandbox -- nc -zv squid-proxy 3128 2>&1 || echo "Connexion Squid OK ou timeout attendu"
```

Test 3 - Internet direct (doit être BLOQUÉ) :
```bash
kubectl exec test-netpol -n openclaw-sandbox -- timeout 5 nc -zv google.com 443 2>&1 && echo "ERREUR: Internet direct accessible!" || echo "OK: Internet direct bloqué"
```

Test 4 - SSH vers le Mac (doit être BLOQUÉ) :
```bash
kubectl exec test-netpol -n openclaw-sandbox -- timeout 5 nc -zv 192.168.1.1 22 2>&1 && echo "ERREUR: SSH accessible!" || echo "OK: SSH bloqué"
```

Nettoie le Pod de test :
```bash
kubectl delete pod test-netpol -n openclaw-sandbox --grace-period=0 --force 2>/dev/null || true
```

**Vérification :**

```bash
echo "=== Résumé des Network Policies ===" && kubectl get networkpolicy -n openclaw-sandbox
```

### Étape 8 : Documenter les flux réseau autorisés

**Pourquoi ?** La documentation des flux réseau est essentielle pour l'audit de sécurité et la maintenance.

**Comment ?**

Crée une ConfigMap de documentation :

```bash
cat << 'EOF' > /tmp/network-flows-doc.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: network-flows-documentation
  namespace: openclaw-sandbox
  labels:
    documentation: network-security
data:
  flows.md: |
    # Flux Réseau Autorisés - OpenClaw Sandbox

    ## Architecture Réseau
    ```
    [OpenClaw Pod] ---> [Squid Proxy] ---> [Internet Whitelisté]
         |
         +---> [LLM Local sur Mac:11434/8000]
    ```

    ## Flux Autorisés

    | Source | Destination | Port | Protocole | Description |
    |--------|-------------|------|-----------|-------------|
    | openclaw | squid-proxy | 3128 | TCP | Proxy HTTP/HTTPS |
    | openclaw | Mac (192.168.x.x) | 11434 | TCP | Ollama API |
    | openclaw | Mac (192.168.x.x) | 8000 | TCP | API LLM custom |
    | openclaw | kube-dns | 53 | UDP/TCP | Résolution DNS |
    | squid-proxy | Internet | 443 | TCP | HTTPS sortant |
    | squid-proxy | Internet | 80 | TCP | HTTP sortant |

    ## Flux BLOQUÉS

    | Source | Destination | Port | Raison |
    |--------|-------------|------|--------|
    | openclaw | Internet direct | * | Doit passer par Squid |
    | openclaw | Mac | 22 | SSH interdit |
    | openclaw | Mac | * | Tous ports sauf LLM |
    | openclaw | Autres namespaces | * | Isolation namespace |
    | squid-proxy | Réseaux privés | * | Pas d'accès interne |

    ## Dernière mise à jour
    Date: $(date)
    Révisé par: [À COMPLÉTER]
EOF
```

```bash
kubectl apply -f /tmp/network-flows-doc.yaml
```

**Vérification :**

```bash
kubectl get configmap network-flows-documentation -n openclaw-sandbox -o jsonpath='{.data.flows\.md}' | head -30
```

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] CNI supporte les Network Policies (Calico, Cilium, etc.)
- [ ] Politique `default-deny-all` appliquée
- [ ] DNS autorisé vers kube-system
- [ ] OpenClaw peut accéder à Squid (port 3128)
- [ ] OpenClaw peut accéder au LLM local (ports 11434, 8000)
- [ ] OpenClaw NE PEUT PAS accéder à Internet directement
- [ ] OpenClaw NE PEUT PAS accéder au SSH du Mac (port 22)
- [ ] Documentation des flux créée

```bash
echo "=== Vérification Network Policies ===" && kubectl get networkpolicy -n openclaw-sandbox && echo "" && echo "Nombre de policies: $(kubectl get networkpolicy -n openclaw-sandbox --no-headers | wc -l)" && echo "=== Network OK ==="
```

## ⚠️ Dépannage

### Erreur : "NetworkPolicy has no effect"

**Cause** : Le CNI ne supporte pas les Network Policies.

**Solution** : Installe Calico ou Cilium :

```bash
kubectl get pods -n kube-system | grep -E "calico|cilium" || echo "Installer un CNI compatible"
```

### Erreur : "DNS resolution failed"

**Cause** : La politique DNS n'autorise pas le trafic vers kube-dns.

**Solution** :

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide && kubectl get networkpolicy allow-dns -n openclaw-sandbox -o yaml
```

### Erreur : "Connection to Squid refused"

**Cause** : La politique OpenClaw ou Squid bloque le trafic.

**Solution** :

```bash
kubectl describe networkpolicy openclaw-network-policy -n openclaw-sandbox | grep -A10 "squid"
```

### Le traffic vers Internet fonctionne sans proxy

**Cause** : La politique deny-all n'est pas correctement appliquée ou le CNI ne l'implémente pas.

**Solution** :

```bash
kubectl get networkpolicy default-deny-all -n openclaw-sandbox && kubectl describe networkpolicy default-deny-all -n openclaw-sandbox
```

### Je ne peux plus accéder aux Pods pour debug

**Cause** : Les politiques bloquent aussi ton accès kubectl exec.

**Solution** : Crée une politique temporaire pour le debug :

```bash
kubectl label pod <nom-pod> -n openclaw-sandbox debug=true --overwrite
```

Puis crée une politique autorisant le trafic pour les Pods labellés `debug=true`.

## 🔗 Ressources

- **Kubernetes Network Policies** : Documentation officielle
  - https://kubernetes.io/docs/concepts/services-networking/network-policies/
- **Calico Network Policies** : Guide complet
  - https://docs.tigera.io/calico/latest/network-policy/
- **CIS Kubernetes Benchmark** : Section 5.3 (Network Policies)
  - https://www.cisecurity.org/benchmark/kubernetes
- **NIST SP 800-125B** : Secure Virtual Network Configuration
  - https://csrc.nist.gov/publications/detail/sp/800-125b/final

## ➡️ Prochaine étape

Les Network Policies contrôlent maintenant tous les flux réseau. Mais la sécurité ne s'arrête pas à la configuration : il faut régulièrement **auditer** l'ensemble du système pour détecter les vulnérabilités.

Rendez-vous au [Chapitre 5 - Audit Sécurité (CVE/OWASP/NIST)](05-audit-securite.md).
