# 📋 Annexe B - Commandes de Référence

> **Toutes les commandes sont en UNE SEULE LIGNE et prêtes à copier-coller.**

---

## 🍺 Homebrew

### Installation
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Mise à jour
```bash
brew update && brew upgrade
```

### Nettoyage
```bash
brew cleanup --prune=all
```

---

## 🦙 Ollama

### Installation
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Télécharger un modèle
```bash
ollama pull llama3.1:70b
```

### Lister les modèles
```bash
ollama list
```

### Lancer un modèle
```bash
ollama run llama3.1:70b
```

### Vérifier le statut
```bash
curl -s http://localhost:11434/api/tags | jq
```

### Arrêter Ollama
```bash
pkill ollama
```

### Voir les logs
```bash
tail -f ~/.ollama/logs/server.log
```

---

## ☸️ k3s (Kubernetes)

### Installation
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 --disable traefik" sh -
```

### Configurer kubectl
```bash
mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $(id -u):$(id -g) ~/.kube/config
```

### Vérifier l'installation
```bash
kubectl cluster-info
```

### Voir tous les pods
```bash
kubectl get pods --all-namespaces
```

### Voir les nodes
```bash
kubectl get nodes -o wide
```

### Arrêter k3s
```bash
sudo systemctl stop k3s
```

### Désinstaller k3s
```bash
/usr/local/bin/k3s-uninstall.sh
```

---

## 🦞 OpenClaw

### Installation globale
```bash
npm install -g openclaw@latest
```

### Onboarding
```bash
openclaw onboard --install-daemon
```

### Lancer le Gateway
```bash
openclaw gateway
```

### Vérifier le statut
```bash
openclaw status
```

### Audit de sécurité
```bash
openclaw security audit
```

### Audit avec corrections
```bash
openclaw security audit --fix
```

### Voir les logs
```bash
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

### Mettre à jour
```bash
openclaw update --channel stable
```

### Liste des canaux connectés
```bash
openclaw channels list
```

---

## 🐳 Docker

### Build une image
```bash
docker build -t openclaw-secure:latest .
```

### Lancer un container
```bash
docker run -d --name openclaw -p 18789:18789 openclaw-secure:latest
```

### Voir les containers
```bash
docker ps -a
```

### Logs d'un container
```bash
docker logs -f openclaw
```

### Entrer dans un container
```bash
docker exec -it openclaw /bin/sh
```

### Arrêter tous les containers
```bash
docker stop $(docker ps -q)
```

### Nettoyer Docker
```bash
docker system prune -af --volumes
```

---

## 📦 Kubernetes (kubectl)

### Namespaces

```bash
kubectl create namespace openclaw
```

```bash
kubectl get namespaces
```

```bash
kubectl delete namespace openclaw
```

### Pods

```bash
kubectl get pods -n openclaw
```

```bash
kubectl get pods -n openclaw -o wide
```

```bash
kubectl describe pod <nom-pod> -n openclaw
```

```bash
kubectl logs <nom-pod> -n openclaw
```

```bash
kubectl logs -f <nom-pod> -n openclaw
```

```bash
kubectl exec -it <nom-pod> -n openclaw -- /bin/sh
```

```bash
kubectl delete pod <nom-pod> -n openclaw
```

### Deployments

```bash
kubectl get deployments -n openclaw
```

```bash
kubectl describe deployment openclaw -n openclaw
```

```bash
kubectl rollout restart deployment/openclaw -n openclaw
```

```bash
kubectl rollout status deployment/openclaw -n openclaw
```

```bash
kubectl scale deployment/openclaw --replicas=2 -n openclaw
```

### Services

```bash
kubectl get services -n openclaw
```

```bash
kubectl describe service openclaw -n openclaw
```

```bash
kubectl port-forward svc/openclaw 18789:18789 -n openclaw
```

### Secrets

```bash
kubectl get secrets -n openclaw
```

```bash
kubectl create secret generic api-keys --from-literal=anthropic=sk-ant-xxx -n openclaw
```

```bash
kubectl describe secret api-keys -n openclaw
```

```bash
kubectl get secret api-keys -n openclaw -o jsonpath='{.data.anthropic}' | base64 -d
```

### ConfigMaps

```bash
kubectl get configmaps -n openclaw
```

```bash
kubectl describe configmap openclaw-config -n openclaw
```

### Network Policies

```bash
kubectl get networkpolicies -n openclaw
```

```bash
kubectl describe networkpolicy deny-all -n openclaw
```

### Événements

```bash
kubectl get events -n openclaw --sort-by='.lastTimestamp'
```

### Ressources

```bash
kubectl top pods -n openclaw
```

```bash
kubectl top nodes
```

### Apply / Delete

```bash
kubectl apply -f manifest.yaml
```

```bash
kubectl apply -f kubernetes/ -n openclaw
```

```bash
kubectl delete -f manifest.yaml
```

---

## 🔒 Sécurité

### Scanner les vulnérabilités (Trivy)
```bash
trivy image openclaw-secure:latest
```

### Vérifier les CVE npm
```bash
npm audit
```

### Corriger les CVE npm
```bash
npm audit fix
```

### Vérifier les ports ouverts
```bash
lsof -i -P -n | grep LISTEN
```

### Vérifier les connexions réseau
```bash
netstat -an | grep ESTABLISHED
```

---

## 🔧 Dépannage

### Vérifier si un port est utilisé
```bash
lsof -i :18789
```

### Tuer un processus sur un port
```bash
kill -9 $(lsof -t -i :18789)
```

### Vérifier l'espace disque
```bash
df -h
```

### Vérifier la mémoire
```bash
vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+(\w+)[:\s]+(\d+)/ and printf("%-16s % 16.2f Mi\n", "$1:", $2 * $size / 1048576);'
```

### Vérifier les processus CPU
```bash
top -o cpu
```

### Redémarrer le réseau Docker (Mac)
```bash
docker-machine restart default
```

### Reset k3s (ATTENTION: supprime tout)
```bash
sudo k3s-killall.sh && sudo rm -rf /var/lib/rancher/k3s
```

---

## 📊 Monitoring

### Prometheus - exposer localement
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### Grafana - exposer localement
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Récupérer mot de passe Grafana
```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

---

## 💾 Backup

### Backup manuel
```bash
~/scripts/backup-openclaw.sh
```

### Restauration
```bash
~/scripts/restore-openclaw.sh
```

### Lister les backups
```bash
ls -la ~/backups/openclaw/
```

### Vérifier checksums
```bash
cd ~/backups/openclaw && sha256sum -c openclaw_backup_*_checksums.sha256
```

---

## 🌐 Réseau

### Tester la connectivité Ollama
```bash
curl -s http://localhost:11434/api/tags
```

### Tester la connectivité OpenClaw
```bash
curl -s http://localhost:18789/health
```

### Tester DNS
```bash
nslookup api.anthropic.com
```

### Tester HTTPS
```bash
curl -I https://api.anthropic.com
```

---

## 🔑 Git

### Cloner ce repo
```bash
git clone https://github.com/EthanThePhoenix38/Openclaw.git
```

### Commit signé
```bash
git commit -S -m "feat: description"
```

### Push
```bash
git push origin main
```

### Pull avec rebase
```bash
git pull --rebase origin main
```

---

## 📝 Helm

### Ajouter un repo
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

### Mettre à jour les repos
```bash
helm repo update
```

### Installer un chart
```bash
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Lister les releases
```bash
helm list --all-namespaces
```

### Désinstaller
```bash
helm uninstall prometheus -n monitoring
```

---

## 🛠️ macOS Spécifiques

### Vérifier la version macOS
```bash
sw_vers
```

### Vérifier le modèle Mac
```bash
system_profiler SPHardwareDataType | grep "Model Name"
```

### Vérifier la RAM
```bash
system_profiler SPHardwareDataType | grep "Memory"
```

### Vérifier le GPU
```bash
system_profiler SPDisplaysDataType | grep "Chipset Model"
```

### Ouvrir le gestionnaire de sécurité
```bash
open "x-apple.systempreferences:com.apple.preference.security"
```

---

## 📚 Ressources

- **kubectl Cheat Sheet** : https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Docker Cheat Sheet** : https://docs.docker.com/get-started/docker_cheatsheet.pdf
- **Helm Cheat Sheet** : https://helm.sh/docs/intro/cheatsheet/
