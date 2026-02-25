#!/bin/bash
# =============================================================================
# Script de déploiement Phoenix sur Kubernetes
# Version: 1.0.0
# Auteur: Ethan Bernier (ORCID: 0009-0008-9839-5763)
# Description: Déploie Phoenix et ses dépendances sur k3s/k8s
# =============================================================================
#
# USAGE :
#   chmod +x deploy-phoenix.sh
#   ./deploy-phoenix.sh                    # Déploiement complet
#   ./deploy-phoenix.sh --dry-run          # Simulation
#   ./deploy-phoenix.sh --delete           # Suppression
#   ./deploy-phoenix.sh --status           # État actuel
#
# PRÉREQUIS :
#   - kubectl configuré et connecté à un cluster
#   - Fichiers kubernetes/*.yaml présents
#   - Ollama actif sur le host (port 11434)
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly K8S_DIR="$PROJECT_DIR/kubernetes"
readonly LOG_FILE="/tmp/deploy-phoenix-$(date +%Y%m%d-%H%M%S).log"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Configuration
readonly NAMESPACE="phoenix"
readonly TIMEOUT="300s"

# -----------------------------------------------------------------------------
# Fonctions utilitaires
# -----------------------------------------------------------------------------

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    case "$level" in
        INFO)  echo -e "${BLUE}[INFO]${NC} $message" ;;
        OK)    echo -e "${GREEN}[✓]${NC} $message" ;;
        WARN)  echo -e "${YELLOW}[⚠]${NC} $message" ;;
        ERROR) echo -e "${RED}[✗]${NC} $message" ;;
        STEP)  echo -e "${CYAN}[→]${NC} $message" ;;
    esac

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

die() {
    log ERROR "$1"
    exit 1
}

check_command() {
    command -v "$1" &> /dev/null
}

# -----------------------------------------------------------------------------
# Vérification des prérequis
# -----------------------------------------------------------------------------

check_prerequisites() {
    log INFO "Vérification des prérequis..."

    # kubectl
    if ! check_command kubectl; then
        die "kubectl n'est pas installé"
    fi
    log OK "kubectl trouvé"

    # Connexion au cluster
    if ! kubectl cluster-info &> /dev/null; then
        die "kubectl ne peut pas se connecter au cluster"
    fi
    log OK "Cluster accessible"

    # Fichiers Kubernetes
    if [[ ! -d "$K8S_DIR" ]]; then
        die "Répertoire kubernetes/ non trouvé: $K8S_DIR"
    fi

    local required_files=(
        "namespace.yaml"
        "configmap.yaml"
        "secrets.yaml"
        "deployment.yaml"
        "service.yaml"
        "network-policy.yaml"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$K8S_DIR/$file" ]]; then
            die "Fichier manquant: $K8S_DIR/$file"
        fi
    done
    log OK "Fichiers Kubernetes présents"

    # Vérifier Ollama sur le host
    if curl -s --connect-timeout 2 http://localhost:11434/api/tags &> /dev/null; then
        log OK "Ollama accessible sur le host (port 11434)"
    else
        log WARN "Ollama non accessible sur localhost:11434"
        log WARN "Les modèles locaux ne seront pas disponibles"
    fi

    log OK "Prérequis validés"
}

# -----------------------------------------------------------------------------
# Création des secrets
# -----------------------------------------------------------------------------

create_secrets_interactive() {
    log INFO "Configuration des secrets..."

    # Vérifier si les secrets existent déjà
    if kubectl get secret phoenix-api-keys -n "$NAMESPACE" &> /dev/null; then
        log OK "Secrets déjà configurés"
        return 0
    fi

    echo ""
    echo "Configuration des clés API (laisser vide pour ignorer) :"
    echo ""

    # Anthropic
    read -rsp "Clé API Anthropic (Claude): " anthropic_key
    echo ""

    # OpenAI
    read -rsp "Clé API OpenAI (optionnel): " openai_key
    echo ""

    # Créer le secret
    local args=()

    if [[ -n "$anthropic_key" ]]; then
        args+=("--from-literal=anthropic-api-key=$anthropic_key")
    fi

    if [[ -n "$openai_key" ]]; then
        args+=("--from-literal=openai-api-key=$openai_key")
    fi

    if [[ ${#args[@]} -gt 0 ]]; then
        kubectl create secret generic phoenix-api-keys \
            "${args[@]}" \
            -n "$NAMESPACE" \
            --dry-run=client -o yaml | kubectl apply -f -
        log OK "Secrets créés"
    else
        log WARN "Aucune clé API fournie. Utilisation des LLM locaux uniquement."
        # Créer un secret vide pour éviter les erreurs
        kubectl create secret generic phoenix-api-keys \
            --from-literal=placeholder=empty \
            -n "$NAMESPACE" \
            --dry-run=client -o yaml | kubectl apply -f -
    fi
}

# -----------------------------------------------------------------------------
# Déploiement
# -----------------------------------------------------------------------------

deploy() {
    local dry_run="${1:-false}"
    local kubectl_args=""

    if [[ "$dry_run" == "true" ]]; then
        kubectl_args="--dry-run=client"
        log INFO "Mode simulation (dry-run)"
    fi

    log STEP "Déploiement d'Phoenix sur Kubernetes..."
    echo ""

    # 1. Namespace
    log STEP "Création du namespace..."
    kubectl apply -f "$K8S_DIR/namespace.yaml" $kubectl_args
    log OK "Namespace créé"

    # Attendre que le namespace soit prêt
    if [[ "$dry_run" != "true" ]]; then
        sleep 2
    fi

    # 2. ConfigMaps
    log STEP "Application des ConfigMaps..."
    kubectl apply -f "$K8S_DIR/configmap.yaml" $kubectl_args
    log OK "ConfigMaps appliquées"

    # 3. Secrets (interactif si pas dry-run)
    if [[ "$dry_run" != "true" ]]; then
        create_secrets_interactive
    else
        log STEP "Secrets (simulation)..."
        kubectl apply -f "$K8S_DIR/secrets.yaml" $kubectl_args
    fi

    # 4. Network Policies
    log STEP "Application des Network Policies..."
    kubectl apply -f "$K8S_DIR/network-policy.yaml" $kubectl_args
    log OK "Network Policies appliquées"

    # 5. Services
    log STEP "Création des Services..."
    kubectl apply -f "$K8S_DIR/service.yaml" $kubectl_args
    log OK "Services créés"

    # 6. Deployment
    log STEP "Déploiement des pods..."
    kubectl apply -f "$K8S_DIR/deployment.yaml" $kubectl_args
    log OK "Deployment appliqué"

    # Attendre que les pods soient prêts
    if [[ "$dry_run" != "true" ]]; then
        wait_for_pods
    fi

    echo ""
    log OK "Déploiement terminé !"
}

wait_for_pods() {
    log INFO "Attente du démarrage des pods..."

    # Attendre le deployment Phoenix
    if kubectl rollout status deployment/phoenix -n "$NAMESPACE" --timeout="$TIMEOUT"; then
        log OK "Deployment phoenix prêt"
    else
        log WARN "Le deployment phoenix n'est pas prêt"
        log INFO "Vérifiez avec: kubectl logs -n phoenix -l app=phoenix"
    fi

    # Attendre Squid
    if kubectl rollout status deployment/squid-proxy -n "$NAMESPACE" --timeout="60s"; then
        log OK "Deployment squid-proxy prêt"
    else
        log WARN "Le deployment squid-proxy n'est pas prêt"
    fi
}

# -----------------------------------------------------------------------------
# Vérification de l'état
# -----------------------------------------------------------------------------

show_status() {
    log INFO "État du déploiement Phoenix"
    echo ""

    # Namespace
    echo "=== Namespace ==="
    kubectl get namespace "$NAMESPACE" 2>/dev/null || echo "Namespace non trouvé"
    echo ""

    # Pods
    echo "=== Pods ==="
    kubectl get pods -n "$NAMESPACE" -o wide 2>/dev/null || echo "Aucun pod"
    echo ""

    # Services
    echo "=== Services ==="
    kubectl get services -n "$NAMESPACE" 2>/dev/null || echo "Aucun service"
    echo ""

    # Deployments
    echo "=== Deployments ==="
    kubectl get deployments -n "$NAMESPACE" 2>/dev/null || echo "Aucun deployment"
    echo ""

    # Network Policies
    echo "=== Network Policies ==="
    kubectl get networkpolicies -n "$NAMESPACE" 2>/dev/null || echo "Aucune network policy"
    echo ""

    # Events récents
    echo "=== Events récents ==="
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || echo "Aucun event"
    echo ""

    # Test de connectivité
    echo "=== Test de connectivité ==="
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=phoenix -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

    if [[ -n "$pod_name" ]]; then
        # Test health endpoint
        if kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s http://localhost:18789/health 2>/dev/null; then
            echo ""
            log OK "Phoenix répond sur /health"
        else
            log WARN "Phoenix ne répond pas"
        fi
    else
        log WARN "Aucun pod Phoenix trouvé"
    fi
}

# -----------------------------------------------------------------------------
# Port-forward
# -----------------------------------------------------------------------------

start_port_forward() {
    log INFO "Démarrage du port-forward..."

    # Vérifier si un port-forward tourne déjà
    if pgrep -f "kubectl.*port-forward.*18789" > /dev/null; then
        log WARN "Un port-forward est déjà actif"
        return 0
    fi

    # Lancer le port-forward en background
    kubectl port-forward -n "$NAMESPACE" svc/phoenix 18789:18789 &
    local pf_pid=$!

    sleep 2

    if kill -0 "$pf_pid" 2>/dev/null; then
        log OK "Port-forward actif sur localhost:18789"
        echo "PID: $pf_pid"
        echo "Pour arrêter: kill $pf_pid"
    else
        log ERROR "Le port-forward a échoué"
    fi
}

# -----------------------------------------------------------------------------
# Suppression
# -----------------------------------------------------------------------------

delete_deployment() {
    log WARN "Suppression du déploiement Phoenix..."

    read -rp "Êtes-vous sûr ? Cela supprimera tous les pods et données. [y/N] " response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log INFO "Annulé"
        return 0
    fi

    # Supprimer dans l'ordre inverse
    log STEP "Suppression des deployments..."
    kubectl delete -f "$K8S_DIR/deployment.yaml" --ignore-not-found

    log STEP "Suppression des services..."
    kubectl delete -f "$K8S_DIR/service.yaml" --ignore-not-found

    log STEP "Suppression des network policies..."
    kubectl delete -f "$K8S_DIR/network-policy.yaml" --ignore-not-found

    log STEP "Suppression des secrets..."
    kubectl delete secret phoenix-api-keys -n "$NAMESPACE" --ignore-not-found

    log STEP "Suppression des configmaps..."
    kubectl delete -f "$K8S_DIR/configmap.yaml" --ignore-not-found

    # Ne pas supprimer le namespace par défaut (garde les PVC)
    read -rp "Supprimer aussi le namespace (et les données persistantes) ? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log STEP "Suppression du namespace..."
        kubectl delete namespace "$NAMESPACE" --ignore-not-found
    fi

    log OK "Suppression terminée"
}

# -----------------------------------------------------------------------------
# Logs
# -----------------------------------------------------------------------------

show_logs() {
    local follow="${1:-false}"

    if [[ "$follow" == "true" ]]; then
        kubectl logs -n "$NAMESPACE" -l app=phoenix -f
    else
        kubectl logs -n "$NAMESPACE" -l app=phoenix --tail=100
    fi
}

# -----------------------------------------------------------------------------
# Point d'entrée
# -----------------------------------------------------------------------------

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTION]

Options:
  (aucune)          Déploiement complet
  --dry-run         Simulation sans modification
  --status          Afficher l'état actuel
  --logs            Afficher les logs (dernières 100 lignes)
  --logs-follow     Suivre les logs en temps réel
  --port-forward    Démarrer le port-forward vers localhost:18789
  --delete          Supprimer le déploiement
  --help            Afficher cette aide

Exemples:
  $SCRIPT_NAME                    # Déployer
  $SCRIPT_NAME --dry-run          # Simuler
  $SCRIPT_NAME --status           # Vérifier l'état
  $SCRIPT_NAME --logs-follow      # Suivre les logs
EOF
}

main() {
    echo "=============================================="
    echo " Déploiement Phoenix sur Kubernetes"
    echo " Version: 1.0.0"
    echo "=============================================="
    echo ""

    case "${1:-}" in
        ""|--deploy)
            check_prerequisites
            deploy false
            echo ""
            echo "Accès à Phoenix :"
            echo "  kubectl port-forward -n phoenix svc/phoenix 18789:18789"
            echo "  Puis: http://localhost:18789"
            ;;
        --dry-run)
            check_prerequisites
            deploy true
            ;;
        --status)
            show_status
            ;;
        --logs)
            show_logs false
            ;;
        --logs-follow)
            show_logs true
            ;;
        --port-forward)
            start_port_forward
            ;;
        --delete)
            delete_deployment
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Option inconnue: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
