# 🎯 Chapitre 1 - Sandbox et Isolation des Containers

## 📋 Ce que tu vas apprendre

Dans ce chapitre, tu vas comprendre et implémenter l'isolation stricte entre Phoenix (dans Kubernetes) et ton Mac Studio M3 Ultra. C'est la fondation de toute l'architecture de sécurité Zero Trust.

- **Pourquoi isoler ?** Un agent IA peut exécuter du code arbitraire. Sans isolation, une erreur ou une injection malveillante pourrait compromettre tout ton système.
- **Architecture cible** : Phoenix tourne dans un namespace Kubernetes dédié, avec des restrictions sur les commandes, les chemins de fichiers et les ressources réseau.
- **Principe clé** : Defense in Depth - plusieurs couches de protection qui se renforcent mutuellement.

## 🛠️ Prérequis

- Mac Studio M3 Ultra avec macOS 14+ (Sonoma)
- Kubernetes local opérationnel (voir Partie 2)
- kubectl configuré et fonctionnel
- Connaissance basique des concepts de sécurité (permissions, namespaces)

## 📝 Étapes détaillées

### Étape 1 : Créer le namespace isolé pour Phoenix

**Pourquoi ?** Un namespace Kubernetes crée une frontière logique qui limite la portée des ressources et des permissions. C'est le premier niveau d'isolation.

**Comment ?**

```bash
kubectl create namespace phoenix-sandbox
```

Applique des labels de sécurité au namespace :

```bash
kubectl label namespace phoenix-sandbox security-level=high isolation=strict environment=production
```

**Vérification :**

```bash
kubectl get namespace phoenix-sandbox --show-labels
```

Tu dois voir les labels `security-level=high`, `isolation=strict` et `environment=production`.

### Étape 2 : Configurer le SecurityContext restrictif

**Pourquoi ?** Le SecurityContext définit les privilèges du container. On veut le minimum absolu : pas de root, pas de capabilities dangereuses, système de fichiers en lecture seule où possible.

**Comment ?**

Crée le fichier de configuration du Pod Phoenix :

```bash
cat << 'EOF' > /tmp/phoenix-pod-security.yaml
apiVersion: v1
kind: Pod
metadata:
  name: phoenix-agent
  namespace: phoenix-sandbox
  labels:
    app: phoenix
    security-tier: sandboxed
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: phoenix
    image: phoenix:latest
    imagePullPolicy: IfNotPresent
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
      privileged: false
    resources:
      limits:
        memory: "2Gi"
        cpu: "2"
      requests:
        memory: "512Mi"
        cpu: "500m"
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
    - name: workspace
      mountPath: /workspace
      readOnly: false
    - name: config
      mountPath: /app/config
      readOnly: true
  volumes:
  - name: tmp-volume
    emptyDir:
      sizeLimit: 500Mi
  - name: workspace
    emptyDir:
      sizeLimit: 1Gi
  - name: config
    configMap:
      name: phoenix-config
  serviceAccountName: phoenix-restricted
  automountServiceAccountToken: false
EOF
```

**Vérification :**

```bash
kubectl apply --dry-run=client -f /tmp/phoenix-pod-security.yaml && echo "Configuration valide"
```

### Étape 3 : Créer le ServiceAccount restrictif

**Pourquoi ?** Le ServiceAccount définit l'identité du Pod dans Kubernetes. Un compte dédié avec permissions minimales empêche l'escalade de privilèges.

**Comment ?**

```bash
cat << 'EOF' > /tmp/phoenix-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: phoenix-restricted
  namespace: phoenix-sandbox
automountServiceAccountToken: false
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: phoenix-minimal-role
  namespace: phoenix-sandbox
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["phoenix-config"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: phoenix-minimal-binding
  namespace: phoenix-sandbox
subjects:
- kind: ServiceAccount
  name: phoenix-restricted
  namespace: phoenix-sandbox
roleRef:
  kind: Role
  name: phoenix-minimal-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

```bash
kubectl apply -f /tmp/phoenix-serviceaccount.yaml
```

**Vérification :**

```bash
kubectl get serviceaccount phoenix-restricted -n phoenix-sandbox && kubectl get role,rolebinding -n phoenix-sandbox
```

### Étape 4 : Configurer le sandbox des commandes (allow-list)

**Pourquoi ?** Phoenix peut exécuter des commandes shell. On doit limiter strictement les commandes autorisées pour éviter l'exécution de code malveillant.

**Comment ?**

Crée la ConfigMap avec la liste blanche des commandes :

```bash
cat << 'EOF' > /tmp/phoenix-sandbox-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: phoenix-config
  namespace: phoenix-sandbox
data:
  sandbox.yaml: |
    # Configuration du Sandbox Phoenix
    version: "1.0"

    # Commandes autorisées (ALLOW-LIST STRICT)
    allowed_commands:
      # Lecture de fichiers
      - cat
      - head
      - tail
      - less
      - more
      - wc

      # Navigation et listing
      - ls
      - pwd
      - find
      - tree

      # Manipulation de texte
      - grep
      - sed
      - awk
      - sort
      - uniq
      - cut
      - tr

      # Développement
      - python3
      - pip
      - node
      - npm
      - git

      # Utilitaires
      - echo
      - date
      - which
      - env
      - basename
      - dirname

    # Commandes INTERDITES (block-list explicite)
    blocked_commands:
      - rm
      - rmdir
      - dd
      - mkfs
      - mount
      - umount
      - chmod
      - chown
      - sudo
      - su
      - passwd
      - useradd
      - userdel
      - curl
      - wget
      - nc
      - netcat
      - ssh
      - scp
      - rsync
      - kill
      - killall
      - pkill
      - reboot
      - shutdown
      - systemctl
      - service

    # Chemins autorisés (ALLOW-LIST STRICT)
    allowed_paths:
      read:
        - /workspace
        - /app
        - /tmp
      write:
        - /workspace
        - /tmp

    # Chemins INTERDITS (block-list explicite)
    blocked_paths:
      - /etc
      - /var
      - /root
      - /home
      - /usr
      - /bin
      - /sbin
      - /proc
      - /sys
      - /dev
      - "~/.ssh"
      - "**/.env"
      - "**/*.key"
      - "**/*.pem"
      - "**/credentials*"
      - "**/secret*"

    # Patterns de fichiers sensibles à JAMAIS exposer
    sensitive_patterns:
      - "*.key"
      - "*.pem"
      - "*.p12"
      - "*.pfx"
      - "id_rsa*"
      - "id_ed25519*"
      - "*.env"
      - ".env*"
      - "*secret*"
      - "*credential*"
      - "*password*"
      - "*token*"
      - "kubeconfig*"
      - ".kube/config"

    # Limites de ressources
    resource_limits:
      max_file_size_mb: 10
      max_output_lines: 1000
      max_execution_time_seconds: 30
      max_memory_mb: 512

    # Configuration réseau
    network:
      allow_outbound: false
      proxy_required: true
      proxy_url: "http://squid-proxy.phoenix-sandbox.svc.cluster.local:3128"
EOF
```

```bash
kubectl apply -f /tmp/phoenix-sandbox-config.yaml
```

**Vérification :**

```bash
kubectl get configmap phoenix-config -n phoenix-sandbox -o yaml | head -50
```

### Étape 5 : Implémenter l'isolation des clés SSH

**Pourquoi ?** Les clés SSH donnent accès à des serveurs distants. Elles ne doivent JAMAIS être accessibles depuis le sandbox Phoenix, même en lecture.

**Comment ?**

Cette protection est multi-couche :

1. **Volume non monté** : Le dossier `~/.ssh` du Mac n'est jamais monté dans le container
2. **Pattern bloqué** : Le sandbox bloque tout accès aux fichiers `id_rsa*`, `id_ed25519*`
3. **Network Policy** : Pas d'accès SSH sortant (port 22 bloqué)

Vérifie que la configuration est correcte :

```bash
kubectl get configmap phoenix-config -n phoenix-sandbox -o jsonpath='{.data.sandbox\.yaml}' | grep -A5 "sensitive_patterns"
```

**Vérification :**

```bash
echo "Test : vérification que ~/.ssh n'est pas dans les volumes montés" && kubectl get pod phoenix-agent -n phoenix-sandbox -o jsonpath='{.spec.volumes[*].name}' 2>/dev/null || echo "Pod non encore déployé - configuration OK"
```

### Étape 6 : Configurer les Pod Security Standards (PSS)

**Pourquoi ?** Les Pod Security Standards sont la méthode native Kubernetes pour appliquer des politiques de sécurité au niveau du namespace.

**Comment ?**

Applique le niveau "restricted" (le plus strict) :

```bash
kubectl label namespace phoenix-sandbox pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=latest pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/warn-version=latest pod-security.kubernetes.io/audit=restricted pod-security.kubernetes.io/audit-version=latest --overwrite
```

**Vérification :**

```bash
kubectl get namespace phoenix-sandbox -o jsonpath='{.metadata.labels}' | jq .
```

Tu dois voir `pod-security.kubernetes.io/enforce: restricted`.

### Étape 7 : Tester l'isolation

**Pourquoi ?** Une configuration non testée est une configuration qui ne fonctionne pas. On doit valider que chaque couche de protection est active.

**Comment ?**

Crée un Pod de test minimal :

```bash
cat << 'EOF' > /tmp/test-isolation.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-isolation
  namespace: phoenix-sandbox
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: test
    image: busybox:latest
    command: ["sleep", "300"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
  serviceAccountName: phoenix-restricted
  automountServiceAccountToken: false
EOF
```

```bash
kubectl apply -f /tmp/test-isolation.yaml && sleep 5 && kubectl get pod test-isolation -n phoenix-sandbox
```

**Vérification :**

```bash
kubectl exec test-isolation -n phoenix-sandbox -- id && kubectl exec test-isolation -n phoenix-sandbox -- cat /etc/shadow 2>&1 | head -1
```

Tu dois voir `uid=1000` et une erreur de permission pour `/etc/shadow`.

Nettoie le Pod de test :

```bash
kubectl delete pod test-isolation -n phoenix-sandbox --grace-period=0
```

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] Le namespace `phoenix-sandbox` existe avec les labels de sécurité
- [ ] Le ServiceAccount `phoenix-restricted` est créé avec permissions minimales
- [ ] La ConfigMap `phoenix-config` contient la configuration du sandbox
- [ ] Les Pod Security Standards sont appliqués au niveau "restricted"
- [ ] Les clés SSH sont exclues de tout montage de volume
- [ ] Le test d'isolation montre que root est impossible

```bash
echo "=== Vérification complète ===" && kubectl get namespace phoenix-sandbox --show-labels && kubectl get serviceaccount,role,rolebinding -n phoenix-sandbox && kubectl get configmap phoenix-config -n phoenix-sandbox && echo "=== Isolation OK ==="
```

## ⚠️ Dépannage

### Erreur : "Pod rejected by PodSecurity"

**Cause** : Le Pod ne respecte pas les Pod Security Standards "restricted".

**Solution** : Vérifie que ton Pod a :
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]`
- `seccompProfile.type: RuntimeDefault`

```bash
kubectl describe namespace phoenix-sandbox | grep -A10 "pod-security"
```

### Erreur : "Permission denied" pour les volumes

**Cause** : Le UID/GID du container ne correspond pas aux permissions des fichiers.

**Solution** : Assure-toi que `fsGroup` est défini dans le SecurityContext :

```bash
kubectl get pod <nom-pod> -n phoenix-sandbox -o jsonpath='{.spec.securityContext.fsGroup}'
```

### Erreur : "ServiceAccount not found"

**Cause** : Le ServiceAccount n'existe pas dans le namespace.

**Solution** : Recrée-le :

```bash
kubectl apply -f /tmp/phoenix-serviceaccount.yaml
```

### Le sandbox ne bloque pas certaines commandes

**Cause** : Le sandbox applicatif (Phoenix) doit lire et appliquer la ConfigMap.

**Solution** : Vérifie que le volume `config` est bien monté et que Phoenix lit le fichier `sandbox.yaml` au démarrage.

## 🔗 Ressources

- **NIST SP 800-190** : Application Container Security Guide
  - https://csrc.nist.gov/publications/detail/sp/800-190/final
- **CIS Kubernetes Benchmark** : Bonnes pratiques de sécurité
  - https://www.cisecurity.org/benchmark/kubernetes
- **Kubernetes Pod Security Standards** : Documentation officielle
  - https://kubernetes.io/docs/concepts/security/pod-security-standards/
- **OWASP Container Security** : Guide de sécurité des containers
  - https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html

## ➡️ Prochaine étape

Maintenant que l'isolation de base est en place, nous allons configurer le **proxy Squid** pour contrôler strictement les accès réseau sortants. C'est la deuxième couche de défense qui empêche Phoenix d'accéder à Internet sans autorisation explicite.

Rendez-vous au [Chapitre 2 - Configuration du Proxy Squid](02-proxy-squid.md).
