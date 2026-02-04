# 🎯 Chapitre 2 - Configuration du Proxy Squid Whitelist

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas déployer un proxy Squid dans Kubernetes qui contrôle TOUS les accès réseau sortants d'OpenClaw. C'est la deuxième ligne de défense après l'isolation du container.

- **Pourquoi un proxy ?** Sans proxy, un agent IA compromis pourrait exfiltrer des données ou télécharger du code malveillant. Le proxy force tout le trafic à passer par une whitelist stricte.
- **Architecture** : OpenClaw --> Squid Proxy --> Internet (domaines autorisés uniquement)
- **Principe Zero Trust** : Aucun accès réseau n'est autorisé par défaut. Chaque domaine doit être explicitement whitelisté.

## 🛠️ Prérequis

- Namespace `openclaw-sandbox` créé (Chapitre 1)
- kubectl configuré et fonctionnel
- Compréhension des Services Kubernetes

## 📝 Étapes détaillées

### Étape 1 : Créer la ConfigMap Squid avec whitelist

**Pourquoi ?** La configuration Squid définit quels domaines sont accessibles. On utilise une approche whitelist : tout est bloqué sauf ce qui est explicitement autorisé.

**Comment ?**

```bash
cat << 'EOF' > /tmp/squid-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: squid-config
  namespace: openclaw-sandbox
data:
  squid.conf: |
    # Configuration Squid pour OpenClaw - Whitelist stricte
    # Version: 1.0
    # Dernière mise à jour: 2024

    # === PORTS AUTORISÉS ===
    acl SSL_ports port 443
    acl Safe_ports port 80
    acl Safe_ports port 443
    acl CONNECT method CONNECT

    # === ACL SOURCES ===
    # Uniquement les pods du namespace openclaw-sandbox
    acl localnet src 10.0.0.0/8
    acl localnet src 172.16.0.0/12
    acl localnet src 192.168.0.0/16

    # === WHITELIST DOMAINES ===
    # Registres de packages Python
    acl whitelist_domains dstdomain .pypi.org
    acl whitelist_domains dstdomain .pythonhosted.org
    acl whitelist_domains dstdomain files.pythonhosted.org

    # Registres npm
    acl whitelist_domains dstdomain .npmjs.org
    acl whitelist_domains dstdomain registry.npmjs.org
    acl whitelist_domains dstdomain .npmjs.com

    # GitHub (code source uniquement, pas les releases)
    acl whitelist_domains dstdomain .github.com
    acl whitelist_domains dstdomain raw.githubusercontent.com
    acl whitelist_domains dstdomain api.github.com

    # GitLab
    acl whitelist_domains dstdomain .gitlab.com

    # Documentation officielle
    acl whitelist_domains dstdomain docs.python.org
    acl whitelist_domains dstdomain nodejs.org
    acl whitelist_domains dstdomain kubernetes.io

    # APIs LLM (si nécessaire pour certains cas)
    # ATTENTION: Décommenter UNIQUEMENT si OpenClaw doit accéder à des APIs externes
    # acl whitelist_domains dstdomain api.anthropic.com
    # acl whitelist_domains dstdomain api.openai.com

    # === RÈGLES D'ACCÈS ===
    # Bloquer les ports non sécurisés pour CONNECT
    http_access deny CONNECT !SSL_ports

    # Bloquer les ports non autorisés
    http_access deny !Safe_ports

    # Autoriser UNIQUEMENT les domaines whitelistés
    http_access allow localnet whitelist_domains

    # BLOQUER TOUT LE RESTE
    http_access deny all

    # === CONFIGURATION RÉSEAU ===
    http_port 3128

    # === LOGGING ===
    access_log /var/log/squid/access.log squid
    cache_log /var/log/squid/cache.log

    # Format de log détaillé pour audit
    logformat detailed %ts.%03tu %6tr %>a %Ss/%03>Hs %<st %rm %ru %[un %Sh/%<a %mt "%{Referer}>h" "%{User-Agent}>h"
    access_log /var/log/squid/detailed.log detailed

    # === CACHE ===
    # Désactiver le cache pour la sécurité (pas de données persistantes)
    cache deny all

    # === TIMEOUTS ===
    connect_timeout 30 seconds
    read_timeout 60 seconds
    request_timeout 60 seconds

    # === SÉCURITÉ ===
    # Masquer la version de Squid
    httpd_suppress_version_string on

    # Supprimer les headers révélateurs
    via off
    forwarded_for delete

    # === LIMITES ===
    # Taille maximale des requêtes
    request_body_max_size 10 MB
    reply_body_max_size 50 MB all

    # Connexions simultanées par client
    acl maxconn_client maxconn 10
    http_access deny maxconn_client

    # === COREDUMP ===
    coredump_dir /var/spool/squid

  whitelist.txt: |
    # Liste des domaines autorisés (pour référence)
    # Ce fichier est informatif, la vraie config est dans squid.conf

    # Python packages
    pypi.org
    files.pythonhosted.org

    # npm packages
    registry.npmjs.org

    # Code source
    github.com
    raw.githubusercontent.com
    api.github.com
    gitlab.com

    # Documentation
    docs.python.org
    nodejs.org
    kubernetes.io
EOF
```

```bash
kubectl apply -f /tmp/squid-config.yaml
```

**Vérification :**

```bash
kubectl get configmap squid-config -n openclaw-sandbox && kubectl get configmap squid-config -n openclaw-sandbox -o jsonpath='{.data.squid\.conf}' | grep -c "whitelist_domains"
```

### Étape 2 : Déployer le Pod Squid

**Pourquoi ?** Squid doit tourner dans le même namespace qu'OpenClaw pour que les Network Policies puissent le contrôler.

**Comment ?**

```bash
cat << 'EOF' > /tmp/squid-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: squid-proxy
  namespace: openclaw-sandbox
  labels:
    app: squid-proxy
    component: security
spec:
  replicas: 1
  selector:
    matchLabels:
      app: squid-proxy
  template:
    metadata:
      labels:
        app: squid-proxy
        component: security
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 13
        runAsGroup: 13
        fsGroup: 13
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: squid
        image: ubuntu/squid:latest
        ports:
        - containerPort: 3128
          protocol: TCP
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop:
              - ALL
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "128Mi"
            cpu: "100m"
        volumeMounts:
        - name: squid-config
          mountPath: /etc/squid/squid.conf
          subPath: squid.conf
          readOnly: true
        - name: squid-cache
          mountPath: /var/spool/squid
        - name: squid-logs
          mountPath: /var/log/squid
        livenessProbe:
          tcpSocket:
            port: 3128
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 3128
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: squid-config
        configMap:
          name: squid-config
      - name: squid-cache
        emptyDir:
          sizeLimit: 100Mi
      - name: squid-logs
        emptyDir:
          sizeLimit: 200Mi
EOF
```

```bash
kubectl apply -f /tmp/squid-deployment.yaml
```

**Vérification :**

```bash
kubectl get deployment squid-proxy -n openclaw-sandbox && kubectl rollout status deployment/squid-proxy -n openclaw-sandbox --timeout=60s
```

### Étape 3 : Créer le Service Squid

**Pourquoi ?** Le Service Kubernetes permet aux autres Pods d'accéder à Squid via un nom DNS stable : `squid-proxy.openclaw-sandbox.svc.cluster.local`.

**Comment ?**

```bash
cat << 'EOF' > /tmp/squid-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: squid-proxy
  namespace: openclaw-sandbox
  labels:
    app: squid-proxy
spec:
  selector:
    app: squid-proxy
  ports:
  - port: 3128
    targetPort: 3128
    protocol: TCP
    name: http-proxy
  type: ClusterIP
EOF
```

```bash
kubectl apply -f /tmp/squid-service.yaml
```

**Vérification :**

```bash
kubectl get service squid-proxy -n openclaw-sandbox && kubectl get endpoints squid-proxy -n openclaw-sandbox
```

### Étape 4 : Configurer OpenClaw pour utiliser le proxy

**Pourquoi ?** OpenClaw doit être configuré pour envoyer TOUTES ses requêtes HTTP/HTTPS via le proxy Squid.

**Comment ?**

Mets à jour la ConfigMap OpenClaw avec les variables d'environnement du proxy :

```bash
cat << 'EOF' > /tmp/openclaw-env-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openclaw-env
  namespace: openclaw-sandbox
data:
  HTTP_PROXY: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
  HTTPS_PROXY: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
  http_proxy: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
  https_proxy: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
  NO_PROXY: "localhost,127.0.0.1,.cluster.local,.svc"
  no_proxy: "localhost,127.0.0.1,.cluster.local,.svc"
  # Pour pip
  PIP_INDEX_URL: "https://pypi.org/simple/"
  PIP_TRUSTED_HOST: "pypi.org files.pythonhosted.org"
  # Pour npm
  NPM_CONFIG_REGISTRY: "https://registry.npmjs.org/"
EOF
```

```bash
kubectl apply -f /tmp/openclaw-env-config.yaml
```

**Vérification :**

```bash
kubectl get configmap openclaw-env -n openclaw-sandbox -o yaml
```

### Étape 5 : Tester le proxy avec un Pod de test

**Pourquoi ?** On doit valider que le proxy fonctionne correctement : les domaines whitelistés sont accessibles, les autres sont bloqués.

**Comment ?**

Crée un Pod de test :

```bash
cat << 'EOF' > /tmp/test-proxy.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-proxy
  namespace: openclaw-sandbox
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: test
    image: curlimages/curl:latest
    command: ["sleep", "600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    env:
    - name: HTTP_PROXY
      value: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
    - name: HTTPS_PROXY
      value: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
    - name: http_proxy
      value: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
    - name: https_proxy
      value: "http://squid-proxy.openclaw-sandbox.svc.cluster.local:3128"
  restartPolicy: Never
EOF
```

```bash
kubectl apply -f /tmp/test-proxy.yaml && sleep 10 && kubectl get pod test-proxy -n openclaw-sandbox
```

Test des domaines autorisés :

```bash
kubectl exec test-proxy -n openclaw-sandbox -- curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://pypi.org && echo " - pypi.org (doit être 200)"
```

Test des domaines bloqués :

```bash
kubectl exec test-proxy -n openclaw-sandbox -- curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://google.com 2>&1 && echo " - google.com (doit être 403 ou timeout)"
```

**Vérification :**

```bash
kubectl exec test-proxy -n openclaw-sandbox -- curl -s -x http://squid-proxy:3128 -I https://github.com 2>&1 | head -5
```

Nettoie le Pod de test :

```bash
kubectl delete pod test-proxy -n openclaw-sandbox --grace-period=0 --force 2>/dev/null || true
```

### Étape 6 : Configurer le monitoring des logs Squid

**Pourquoi ?** Les logs Squid sont essentiels pour l'audit de sécurité. Ils montrent toutes les tentatives d'accès, réussies ou bloquées.

**Comment ?**

Vérifie les logs en temps réel :

```bash
kubectl logs -f deployment/squid-proxy -n openclaw-sandbox --tail=20 2>/dev/null || echo "Logs non disponibles - vérifier que le pod est running"
```

Pour extraire les accès bloqués :

```bash
kubectl exec deployment/squid-proxy -n openclaw-sandbox -- cat /var/log/squid/access.log 2>/dev/null | grep "DENIED" | tail -10 || echo "Pas d'accès bloqués ou logs non disponibles"
```

**Vérification :**

```bash
kubectl exec deployment/squid-proxy -n openclaw-sandbox -- ls -la /var/log/squid/ 2>/dev/null || echo "Vérifier que le pod Squid est running"
```

### Étape 7 : Ajouter des domaines à la whitelist (procédure)

**Pourquoi ?** Tu auras parfois besoin d'autoriser de nouveaux domaines pour OpenClaw. Voici la procédure sécurisée.

**Comment ?**

1. **Évaluer le besoin** : Le domaine est-il vraiment nécessaire ? Y a-t-il une alternative locale ?

2. **Vérifier la réputation** : Le domaine est-il légitime ? Appartient-il à une organisation de confiance ?

3. **Ajouter à la ConfigMap** : Édite la ConfigMap Squid :

```bash
kubectl edit configmap squid-config -n openclaw-sandbox
```

Ajoute la ligne suivante dans la section ACL (remplace `nouveau-domaine.com`) :

```
acl whitelist_domains dstdomain .nouveau-domaine.com
```

4. **Redémarrer Squid** :

```bash
kubectl rollout restart deployment/squid-proxy -n openclaw-sandbox && kubectl rollout status deployment/squid-proxy -n openclaw-sandbox
```

5. **Tester l'accès** :

```bash
kubectl run test-new-domain --rm -it --restart=Never -n openclaw-sandbox --image=curlimages/curl -- curl -x http://squid-proxy:3128 -s -o /dev/null -w "%{http_code}" https://nouveau-domaine.com
```

**Vérification :**

Documente chaque ajout dans un fichier de suivi :

```bash
echo "$(date): Ajout de nouveau-domaine.com - Raison: [RAISON] - Approuvé par: [NOM]" >> /tmp/whitelist-changelog.txt
```

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] ConfigMap `squid-config` créée avec la whitelist
- [ ] Deployment `squid-proxy` en état Running
- [ ] Service `squid-proxy` accessible sur le port 3128
- [ ] ConfigMap `openclaw-env` avec les variables proxy
- [ ] Les domaines whitelistés sont accessibles (code 200)
- [ ] Les domaines non-whitelistés sont bloqués (code 403)

```bash
echo "=== Vérification Proxy Squid ===" && kubectl get deployment,service,configmap -n openclaw-sandbox -l app=squid-proxy && kubectl get pods -n openclaw-sandbox -l app=squid-proxy -o wide && echo "=== Proxy OK ==="
```

## ⚠️ Dépannage

### Erreur : "Connection refused" vers le proxy

**Cause** : Le pod Squid n'est pas prêt ou le Service n'est pas configuré.

**Solution** :

```bash
kubectl get pods -n openclaw-sandbox -l app=squid-proxy && kubectl describe service squid-proxy -n openclaw-sandbox
```

### Erreur : "403 Forbidden" sur un domaine whitelisté

**Cause** : Le domaine n'est pas correctement ajouté à la whitelist ou il y a une erreur de syntaxe.

**Solution** :

```bash
kubectl get configmap squid-config -n openclaw-sandbox -o jsonpath='{.data.squid\.conf}' | grep -i "domaine"
```

Vérifie que le domaine commence par un point (`.domaine.com`) pour inclure les sous-domaines.

### Erreur : "Timeout" sur les requêtes

**Cause** : Les Network Policies bloquent le trafic ou DNS ne résout pas.

**Solution** :

```bash
kubectl exec deployment/squid-proxy -n openclaw-sandbox -- nslookup pypi.org 2>/dev/null || echo "DNS non disponible depuis Squid"
```

### Les logs Squid sont vides

**Cause** : Le volume des logs n'est pas monté correctement ou Squid n'a pas démarré.

**Solution** :

```bash
kubectl describe pod -n openclaw-sandbox -l app=squid-proxy | grep -A20 "Volumes"
```

### Squid utilise trop de mémoire

**Cause** : Le cache est activé ou les limites ne sont pas définies.

**Solution** : Vérifie que `cache deny all` est dans la configuration et que les `resources.limits` sont définis.

## 🔗 Ressources

- **Squid Documentation** : Configuration officielle
  - http://www.squid-cache.org/Doc/config/
- **OWASP Proxy Security** : Bonnes pratiques
  - https://owasp.org/www-community/controls/Proxy_Security
- **CIS Controls** : Network Segmentation
  - https://www.cisecurity.org/controls/
- **NIST SP 800-41** : Guidelines on Firewalls and Firewall Policy
  - https://csrc.nist.gov/publications/detail/sp/800-41/rev-1/final

## ➡️ Prochaine étape

Le proxy Squid contrôle maintenant les accès réseau sortants. Mais OpenClaw a besoin d'accéder à des secrets (API keys, tokens). Dans le prochain chapitre, nous allons configurer la **protection des credentials avec Kubernetes Secrets** de manière sécurisée.

Rendez-vous au [Chapitre 3 - Protection des Credentials](03-protection-credentials.md).
