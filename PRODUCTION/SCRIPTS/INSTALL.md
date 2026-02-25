#!/bin/bash
# Capsule
# Nom: desinstallation.sh
# Auteur: Ethan Bernier
# Version: 1.0.0
# Date: 2026-02-02
# Description: Désinstallation séquentielle (Mac) Phoenix/k3s (namespace) + option suppression VM multipass. Sauvegarde avant action. Affiche et copie la sortie dans le presse-papier.

set -euo pipefail

REPO_ROOT="/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder"
PTR_PODS_DIR="${REPO_ROOT}/PRODUCTION/PTR/PODS"
SAVE_DIR="${PTR_PODS_DIR}/SAVE"
DATE_ISO="$(date +%F)"
STAMP="$(date +%F_%H%M%S)"
RUN_DIR="${SAVE_DIR}/PTR_PODS_${DATE_ISO}"
OUT_TXT="${RUN_DIR}/desinstallation_output_${STAMP}.txt"

KUBECONFIG_PATH="${HOME}/.kube/k3s-config"

mkdir -p "${RUN_DIR}"
mkdir -p "${RUN_DIR}/backup"

{
  echo "=== DESINSTALLATION PODS — ${STAMP} ==="
  echo "Machine: macOS (Terminal) — utilisateur: $(whoami)"
  echo "Repo: ${REPO_ROOT}"
  echo

  echo "1) Sauvegardes locales"
  if [ -f "${KUBECONFIG_PATH}" ]; then
    cp -f "${KUBECONFIG_PATH}" "${RUN_DIR}/backup/k3s-config.backup.${STAMP}"
    echo " - Backup kubeconfig: ${RUN_DIR}/backup/k3s-config.backup.${STAMP}"
  else
    echo " - Aucun kubeconfig à sauvegarder: ${KUBECONFIG_PATH}"
  fi

  echo
  echo "2) Suppression Phoenix (namespace) — si kubectl disponible"
  if command -v kubectl >/dev/null 2>&1; then
    export KUBECONFIG="${KUBECONFIG_PATH}"
    if kubectl get ns phoenix >/dev/null 2>&1; then
      echo " - kubectl delete namespace phoenix"
      kubectl delete namespace phoenix --wait=true || true
      echo " - Namespace phoenix supprimé (ou en suppression)"
    else
      echo " - Namespace phoenix absent"
    fi
  else
    echo " - kubectl NON INSTALLÉ, suppression namespace impossible"
  fi

  echo
  echo "3) Option suppression VM multipass (k3s-master)"
  echo " - ATTENTION: suppression VM = perte cluster"
  echo " - Action exécutée: suppression VM si multipass présent ET VM existante"
  if command -v multipass >/dev/null 2>&1; then
    if multipass info k3s-master >/dev/null 2>&1; then
      echo " - multipass stop k3s-master"
      multipass stop k3s-master || true
      echo " - multipass delete k3s-master"
      multipass delete k3s-master || true
      echo " - multipass purge"
      multipass purge || true
      echo " - VM k3s-master supprimée"
    else
      echo " - VM k3s-master absente"
    fi
  else
    echo " - multipass NON INSTALLÉ"
  fi

  echo
  echo "4) Étape suivante (manuelle)"
  echo " - Réinstallation: ${REPO_ROOT}/PRODUCTION/SCRIPTS/install.md"
  echo " - Vérification: ${PTR_PODS_DIR}/VERIF/verif_mensuelle_pods.sh"

  echo
  echo "=== FIN DESINSTALLATION — Rapport: ${OUT_TXT} ==="
} | tee "${OUT_TXT}" | tee /dev/tty | pbcopy
/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/SCRIPTS/install.md


## INSTALLATION SEQUENTIELLE ##

# Installation séquentielle — PODS (k3s + Phoenix) — Mac (Mensuel / Reconstruction)
Version: 1.0.0
Date: 2026-02-02
Exécution: macOS (Terminal) uniquement

## Pré-requis
- Homebrew installé
- Accès Internet
- Ne jamais exécuter les commandes macOS dans la VM (Multipass shell)

## 1) Installer les outils Mac (si manquants)
Commande (Multipass):
- brew install --cask multipass | tee /dev/tty | pbcopy

Résultat attendu:
- Installation terminée sans erreur

Commande (kubectl):
- brew install kubernetes-cli | tee /dev/tty | pbcopy

Résultat attendu:
- "kubernetes-cli" installé

## 2) Créer / Recréer la VM k3s-master
Commande:
- multipass launch --name k3s-master --cpus 4 --memory 6G --disk 60G 22.04 | tee /dev/tty | pbcopy

Résultat attendu:
- VM créée
- Aucune erreur

Vérification:
- multipass info k3s-master | tee /dev/tty | pbcopy

Résultat attendu:
- State: Running
- IPv4: X.X.X.X

## 3) Installer k3s dans la VM
Commande:
- multipass exec k3s-master -- bash -lc "curl -sfL https://get.k3s.io | sh -" | tee /dev/tty | pbcopy

Résultat attendu:
- Installation sans erreur

## 4) Récupérer le kubeconfig sur le Mac
Commande:
- mkdir -p "$HOME/.kube" && multipass exec k3s-master -- sudo cat /etc/rancher/k3s/k3s.yaml > "$HOME/.kube/k3s-config" && chmod 600 "$HOME/.kube/k3s-config" && echo "KUBECONFIG=$HOME/.kube/k3s-config" | tee /dev/tty | pbcopy

Résultat attendu:
- Fichier créé: ~/.kube/k3s-config
- Permissions restrictives appliquées

## 5) Mettre à jour l’IP du serveur dans kubeconfig
Commande:
- K3S_IP="$(multipass info k3s-master | awk -F': ' '/^IPv4:/{print $2}' | head -n1)" && [ -n "$K3S_IP" ] && sed -i '' "s/127.0.0.1/$K3S_IP/g" "$HOME/.kube/k3s-config" && echo "$K3S_IP" | tee /dev/tty | pbcopy

Résultat attendu:
- Affichage de l’IP k3s-master
- Kubeconfig pointe vers l’IP VM (plus 127.0.0.1)

## 6) Vérifier kubectl (connexion cluster)
Commande:
- export KUBECONFIG="$HOME/.kube/k3s-config" && kubectl cluster-info 2>&1 | tee /dev/tty | pbcopy

Résultat attendu:
- "Kubernetes control plane is running at https://<IP>:6443" (ou équivalent)
- Pas d’erreur

Commande:
- export KUBECONFIG="$HOME/.kube/k3s-config" && kubectl get nodes -o wide 2>&1 | tee /dev/tty | pbcopy

Résultat attendu:
- 1 node au moins en Ready

## 7) Créer le namespace phoenix
Commande:
- export KUBECONFIG="$HOME/.kube/k3s-config" && (kubectl get ns phoenix >/dev/null 2>&1 && echo "Namespace phoenix déjà présent" || kubectl create ns phoenix) 2>&1 | tee /dev/tty | pbcopy

Résultat attendu:
- "namespace/phoenix created" ou "déjà présent"

## 8) Déployer Phoenix (si manifests disponibles)
Hypothèse d’emplacement (repo):
- /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/SCRIPTS/k8s/

Commande:
- export KUBECONFIG="$HOME/.kube/k3s-config" && kubectl apply -R -f "/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/SCRIPTS/k8s" 2>&1 | tee /dev/tty | pbcopy

Résultat attendu:
- Création/MAJ des ressources (deployments, services, secrets, configmaps, pvc)
- Aucun message d’erreur

Vérification:
- export KUBECONFIG="$HOME/.kube/k3s-config" && kubectl get pods -n phoenix -o wide 2>&1 | tee /dev/tty | pbcopy

Résultat attendu:
- Pods en Running / Ready

## 9) Vérification mensuelle (PTR)
Commande:
- /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PTR/PODS/VERIF/verif_mensuelle_pods.sh

Résultat attendu:
- Dossier PTR_PODS_YYYY-MM-DD créé
- Rapport verif_output_*.txt généré
- Sortie copiée dans le presse-papier

## 10) Mise à jour mensuelle (packages)
macOS (Homebrew):
- brew update && brew upgrade | tee /dev/tty | pbcopy

Résultat attendu:
- Mise à jour sans erreur

VM Ubuntu (k3s-master):
- multipass exec k3s-master -- sudo apt update && multipass exec k3s-master -- sudo apt -y upgrade | tee /dev/tty | pbcopy

Résultat attendu:
- Paquets mis à jour sans erreur
