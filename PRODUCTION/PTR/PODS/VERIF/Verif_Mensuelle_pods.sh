

# =====================================================================================
# /Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS/PTR/verif_mensuelle_pods.sh
# =====================================================================================
#!/bin/bash
# Version : 1.1
# Date : 02/02/2026
# Objet : Vérification mensuelle manuelle des PODS CLAWBOT

BASE="/Users/ethanbernier/Library/CloudStorage/OneDrive-Phoenix/ClaudeCodeFolder/PRODUCTION/PODS"
SAVE="$BASE/SAVE/SAVE_Clawbot_POD"
PTR="$BASE/PTR"
DATE_FR=$(date +"%d-%m-%Y_%Hh%M")
DATE_EN=$(date +"%Y-%m-%d_%H-%M")

mkdir -p "$SAVE"

echo "# PTR FR – $DATE_FR" > "$PTR/PTR_$DATE_FR_FR.md"
echo "# PTR EN – $DATE_EN" > "$PTR/PTR_$DATE_EN_EN.md"

docker ps -a >> "$PTR/PTR_$DATE_FR_FR.md"
kubectl get pods -A >> "$PTR/PTR_$DATE_FR_FR.md"
kubectl get svc -A >> "$PTR/PTR_$DATE_FR_FR.md"
kubectl get pvc -A >> "$PTR/PTR_$DATE_FR_FR.md"
kubectl get --raw /healthz >> "$PTR/PTR_$DATE_FR_FR.md"

cp -r ~/.kube "$SAVE/kubeconfig_$DATE_FR"
docker inspect $(docker ps -aq) > "$SAVE/docker_state_$DATE_FR.json"

echo "PTR mensuelle générée"