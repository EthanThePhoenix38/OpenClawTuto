# 🎯 2.1 - Prérequis Mac Studio M3 Ultra

## 📋 Ce que tu vas apprendre
- Comment vérifier que ton Mac Studio est prêt pour Phoenix
- Comment installer Homebrew (le "magasin d'apps" pour développeurs)
- Comment installer tous les outils en ligne de commande nécessaires
- Comment vérifier que tout fonctionne correctement

## 🛠️ Prérequis
- Un Mac Studio avec puce M3 Ultra
- macOS Sonoma 14.0 ou plus récent
- Connexion Internet active
- Compte administrateur sur le Mac

## 📝 Étapes détaillées

### Étape 1 : Vérifier ton Mac Studio

**Pourquoi ?** On doit s'assurer que ton Mac a la bonne puce et assez de mémoire pour faire tourner les IA localement.

**Comment ?**
1. Clique sur la pomme  en haut à gauche de l'écran
2. Clique sur "À propos de ce Mac"
3. Regarde les informations affichées

**Ce que tu dois voir :**
- **Puce :** Apple M3 Ultra
- **Mémoire :** 64 Go minimum (128 Go recommandé pour les gros modèles)
- **macOS :** Sonoma 14.0 ou plus récent

**Vérification en Terminal :**
```bash
# Ouvre le Terminal (Cmd + Espace, tape "Terminal", Entrée)
# Copie-colle cette commande pour voir les infos de ta puce
sysctl -n machdep.cpu.brand_string && system_profiler SPHardwareDataType | grep -E "(Chip|Memory|Model)"
```

**Résultat attendu :**
```
Apple M3 Ultra
      Chip: Apple M3 Ultra
      Total Number of Cores: 24 (16 performance and 8 efficiency)
      Memory: 128 GB
```

---

### Étape 2 : Installer les outils de développement Apple

**Pourquoi ?** Ces outils contiennent les commandes de base dont Homebrew a besoin pour fonctionner.

**Comment ?**
1. Ouvre le Terminal (Cmd + Espace, tape "Terminal", appuie sur Entrée)
2. Copie-colle cette commande :

```bash
xcode-select --install
```

3. Une fenêtre popup va apparaître
4. Clique sur "Installer"
5. Accepte les conditions d'utilisation
6. Attends la fin de l'installation (environ 5-10 minutes)

**Vérification :**
```bash
xcode-select -p
```

**Résultat attendu :**
```
/Library/Developer/CommandLineTools
```

---

### Étape 3 : Installer Homebrew

**Pourquoi ?** Homebrew, c'est comme un App Store pour les outils de développeurs. Il va nous permettre d'installer plein de choses facilement avec une seule commande.

**Comment ?**
1. Dans le Terminal, copie-colle cette commande :

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Entre ton mot de passe quand demandé (tu ne verras pas les caractères, c'est normal)
3. Appuie sur Entrée quand on te demande de confirmer
4. Attends la fin de l'installation (2-5 minutes)

**Important !** À la fin, Homebrew te dit d'exécuter des commandes. Fais-le :

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile && eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Vérification :**
```bash
brew --version
```

**Résultat attendu :**
```
Homebrew 4.x.x
```

---

### Étape 4 : Installer Node.js version 22

**Pourquoi ?** Phoenix a besoin de Node.js version 22 ou plus pour fonctionner. C'est le moteur qui fait tourner l'application.

**Comment ?**
```bash
brew install node@22 && echo 'export PATH="/opt/homebrew/opt/node@22/bin:$PATH"' >> ~/.zprofile && source ~/.zprofile
```

**Vérification :**
```bash
node --version && npm --version
```

**Résultat attendu :**
```
v22.x.x
10.x.x
```

**Si la version est inférieure à 22 :**
```bash
brew unlink node && brew link --force node@22
```

---

### Étape 5 : Installer les outils CLI essentiels

**Pourquoi ?** Ces outils nous permettront de gérer les conteneurs, télécharger des fichiers et manipuler des données.

**Comment ?**
```bash
brew install curl wget jq yq git
```

**Vérification de chaque outil :**
```bash
echo "curl: $(curl --version | head -1)" && echo "wget: $(wget --version | head -1)" && echo "jq: $(jq --version)" && echo "yq: $(yq --version)" && echo "git: $(git --version)"
```

**Résultat attendu :**
```
curl: curl 8.x.x ...
wget: GNU Wget 1.x.x ...
jq: jq-1.x
yq: yq version 4.x.x
git: git version 2.x.x
```

---

### Étape 6 : Installer Docker Desktop

**Pourquoi ?** Docker permet de créer des "boîtes isolées" (conteneurs) pour faire tourner des applications sans qu'elles interfèrent avec ton système.

**Comment ?**
1. Ouvre Safari ou ton navigateur préféré
2. Va sur : https://www.docker.com/products/docker-desktop/
3. Clique sur "Download for Mac - Apple Silicon"
4. Ouvre le fichier Docker.dmg téléchargé
5. Glisse Docker dans le dossier Applications
6. Ouvre Docker depuis le dossier Applications
7. Accepte les conditions d'utilisation
8. Entre ton mot de passe si demandé

**Configuration importante :**
1. Clique sur l'icône Docker dans la barre de menu (petite baleine)
2. Clique sur "Settings" (roue dentée)
3. Va dans "Resources"
4. Configure :
   - **CPUs :** 8
   - **Memory :** 16 GB
   - **Swap :** 4 GB
5. Clique sur "Apply & Restart"

**Vérification :**
```bash
docker --version && docker compose version
```

**Résultat attendu :**
```
Docker version 24.x.x, build xxxxx
Docker Compose version v2.x.x
```

---

### Étape 7 : Installer kubectl

**Pourquoi ?** kubectl est l'outil qui permet de parler à Kubernetes (et k3s). C'est comme une télécommande pour gérer tes conteneurs.

**Comment ?**
```bash
brew install kubectl
```

**Vérification :**
```bash
kubectl version --client
```

**Résultat attendu :**
```
Client Version: v1.x.x
Kustomize Version: v5.x.x
```

---

### Étape 8 : Créer les dossiers de travail

**Pourquoi ?** On va créer un endroit bien organisé pour tous nos fichiers Phoenix.

**Comment ?**
```bash
mkdir -p ~/phoenix/{config,data,models,logs,backups} && cd ~/phoenix && ls -la
```

**Vérification :**
```bash
ls -la ~/phoenix/
```

**Résultat attendu :**
```
total 0
drwxr-xr-x  7 tonnom  staff  224 ... .
drwxr-x---+ ... tonnom  staff  ... ..
drwxr-xr-x  2 tonnom  staff   64 ... backups
drwxr-xr-x  2 tonnom  staff   64 ... config
drwxr-xr-x  2 tonnom  staff   64 ... data
drwxr-xr-x  2 tonnom  staff   64 ... logs
drwxr-xr-x  2 tonnom  staff   64 ... models
```

---

### Étape 9 : Vérifier la mémoire GPU disponible

**Pourquoi ?** Le M3 Ultra partage sa mémoire entre le CPU et le GPU. On doit vérifier qu'il y a assez de place pour les modèles IA.

**Comment ?**
```bash
system_profiler SPDisplaysDataType | grep -A 5 "Metal Support"
```

**Pour voir la mémoire totale utilisable par le GPU :**
```bash
sysctl hw.memsize | awk '{print "Mémoire totale: " $2/1024/1024/1024 " GB"}'
```

**Résultat attendu :**
```
Mémoire totale: 128 GB
```

Le M3 Ultra peut utiliser jusqu'à 75% de cette mémoire pour le GPU (soit ~96 GB pour un modèle de 128 GB).

---

### Étape 10 : Script de vérification finale

**Pourquoi ?** On va créer un petit script qui vérifie tout d'un coup pour être sûr que tout est prêt.

**Comment ?**
```bash
cat << 'EOF' > ~/phoenix/check-prerequisites.sh
#!/bin/bash
echo "=== Vérification des prérequis Phoenix ==="
echo ""
echo "1. Système :"
sysctl -n machdep.cpu.brand_string
system_profiler SPHardwareDataType | grep "Memory:"
echo ""
echo "2. Outils installés :"
echo "   - Homebrew: $(brew --version 2>/dev/null | head -1 || echo 'NON INSTALLÉ')"
echo "   - Node.js: $(node --version 2>/dev/null || echo 'NON INSTALLÉ')"
echo "   - npm: $(npm --version 2>/dev/null || echo 'NON INSTALLÉ')"
echo "   - Docker: $(docker --version 2>/dev/null || echo 'NON INSTALLÉ')"
echo "   - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'NON INSTALLÉ')"
echo "   - curl: $(curl --version 2>/dev/null | head -1 || echo 'NON INSTALLÉ')"
echo "   - jq: $(jq --version 2>/dev/null || echo 'NON INSTALLÉ')"
echo ""
echo "3. Dossiers Phoenix :"
ls -d ~/phoenix/*/ 2>/dev/null || echo "   Dossiers non créés"
echo ""
echo "=== Vérification terminée ==="
EOF
chmod +x ~/phoenix/check-prerequisites.sh
```

**Exécuter la vérification :**
```bash
~/phoenix/check-prerequisites.sh
```

**Résultat attendu :**
```
=== Vérification des prérequis Phoenix ===

1. Système :
Apple M3 Ultra
      Memory: 128 GB

2. Outils installés :
   - Homebrew: Homebrew 4.x.x
   - Node.js: v22.x.x
   - npm: 10.x.x
   - Docker: Docker version 24.x.x
   - kubectl: Client Version: v1.x.x
   - curl: curl 8.x.x
   - jq: jq-1.x

3. Dossiers Phoenix :
/Users/tonnom/phoenix/backups/
/Users/tonnom/phoenix/config/
/Users/tonnom/phoenix/data/
/Users/tonnom/phoenix/logs/
/Users/tonnom/phoenix/models/

=== Vérification terminée ===
```

---

## ✅ Checklist

Avant de passer au chapitre suivant, vérifie que :

- [ ] Tu as un Mac Studio avec puce M3 Ultra
- [ ] macOS Sonoma 14.0+ est installé
- [ ] Les outils de développement Apple (xcode-select) sont installés
- [ ] Homebrew est installé et fonctionne
- [ ] Node.js version 22+ est installé
- [ ] npm est installé
- [ ] curl, wget, jq, yq, git sont installés
- [ ] Docker Desktop est installé et configuré
- [ ] kubectl est installé
- [ ] Les dossiers ~/phoenix/ sont créés
- [ ] Le script de vérification passe sans erreur

---

## ⚠️ Dépannage

### Homebrew ne s'installe pas
**Symptôme :** Message d'erreur pendant l'installation
**Solution :**
```bash
sudo rm -rf /opt/homebrew && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### La commande brew n'est pas trouvée
**Symptôme :** `zsh: command not found: brew`
**Solution :**
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile && source ~/.zprofile
```

### Node.js n'est pas en version 22
**Symptôme :** `node --version` affiche v18 ou v20
**Solution :**
```bash
brew unlink node && brew install node@22 && brew link --force node@22
```

### Docker ne démarre pas
**Symptôme :** Docker reste bloqué au démarrage
**Solution :**
1. Quitte Docker complètement (clic droit sur l'icône > Quit)
2. Ouvre Terminal et exécute :
```bash
rm -rf ~/Library/Group\ Containers/group.com.docker && rm -rf ~/Library/Containers/com.docker.docker
```
3. Relance Docker depuis Applications

### xcode-select échoue
**Symptôme :** Erreur pendant l'installation des outils
**Solution :**
```bash
sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install
```

### Pas assez de mémoire affichée
**Symptôme :** Moins de 64 GB affichés
**Solution :** Vérifie que tu as bien un Mac Studio M3 Ultra. Les modèles de base ont 64 GB, ce qui reste suffisant pour des modèles jusqu'à 40B paramètres.

---

## 🔗 Ressources

- [Documentation Homebrew](https://docs.brew.sh/)
- [Documentation Docker Desktop Mac](https://docs.docker.com/desktop/install/mac-install/)
- [Guide Apple Silicon pour développeurs](https://developer.apple.com/documentation/apple-silicon)
- [Node.js Documentation](https://nodejs.org/docs/latest-v22.x/api/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## ➡️ Prochaine étape

Ton Mac Studio est maintenant prêt ! Dans le prochain chapitre, on va installer **Ollama**, le serveur qui va faire tourner les modèles d'IA directement sur ta puce M3 Ultra.

**Chapitre suivant :** [2.2 - Installation Ollama NATIF avec config GPU M3](./02-installation-ollama.md)
