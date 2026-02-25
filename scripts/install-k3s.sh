#!/bin/bash
# =============================================================================
# Script d'installation k3s pour Phoenix
# Version: 1.0.0
# Auteur: Ethan Bernier (ORCID: 0009-0008-9839-5763)
# Description: Installation et configuration de k3s sur Mac/Linux
# =============================================================================
#
# USAGE :
#   chmod +x install-k3s.sh
#   ./install-k3s.sh
#
# PRÉREQUIS :
#   - macOS 12+ avec Rosetta 2 (pour ARM) ou Linux
#   - Docker Desktop installé (pour Mac)
#   - 8 Go RAM minimum
#   - curl, sudo
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly LOG_FILE="/tmp/k3s-install-$(date +%Y%m%d-%H%M%S).log"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Versions
readonly K3S_VERSION="v1.29.0+k3s1"  # Version stable LTS

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
    esac

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

check_command() {
    command -v "$1" &> /dev/null
}

die() {
    log ERROR "$1"
    exit 1
}

# -----------------------------------------------------------------------------
# Détection du système
# -----------------------------------------------------------------------------

detect_os() {
    local os
    os="$(uname -s)"

    case "$os" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      die "Système non supporté: $os" ;;
    esac
}

detect_arch() {
    local arch
    arch="$(uname -m)"

    case "$arch" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64)   echo "arm64" ;;
        *)       die "Architecture non supportée: $arch" ;;
    esac
}

# -----------------------------------------------------------------------------
# Vérification des prérequis
# -----------------------------------------------------------------------------

check_prerequisites() {
    log INFO "Vérification des prérequis..."

    local os
    os="$(detect_os)"

    # Vérifier curl
    if ! check_command curl; then
        die "curl n'est pas installé. Installez-le d'abord."
    fi
    log OK "curl trouvé"

    # Vérifier sudo
    if ! check_command sudo; then
        die "sudo n'est pas installé."
    fi
    log OK "sudo trouvé"

    # Vérifications spécifiques macOS
    if [[ "$os" == "macos" ]]; then
        # Vérifier Docker Desktop
        if ! check_command docker; then
            die "Docker Desktop n'est pas installé. Téléchargez-le sur https://docker.com"
        fi
        log OK "Docker trouvé"

        # Vérifier que Docker tourne
        if ! docker info &> /dev/null; then
            die "Docker ne tourne pas. Lancez Docker Desktop."
        fi
        log OK "Docker est actif"

        # Vérifier Homebrew
        if ! check_command brew; then
            log WARN "Homebrew non trouvé. Installation recommandée."
        else
            log OK "Homebrew trouvé"
        fi
    fi

    # Vérifier la RAM
    local ram_gb
    if [[ "$os" == "macos" ]]; then
        ram_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    else
        ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    fi

    if [[ "$ram_gb" -lt 8 ]]; then
        log WARN "RAM détectée: ${ram_gb} Go. 8 Go minimum recommandé."
    else
        log OK "RAM: ${ram_gb} Go"
    fi

    log OK "Tous les prérequis sont satisfaits"
}

# -----------------------------------------------------------------------------
# Installation k3s (Linux natif)
# -----------------------------------------------------------------------------

install_k3s_linux() {
    log INFO "Installation de k3s sur Linux..."

    # Options d'installation
    local install_opts=(
        "--write-kubeconfig-mode" "644"
        "--disable" "traefik"           # On n'utilise pas l'ingress par défaut
        "--disable" "servicelb"         # Pas de LoadBalancer
        "--flannel-backend" "host-gw"   # Meilleure performance réseau
    )

    # Télécharger et installer k3s
    log INFO "Téléchargement de k3s..."
    curl -sfL https://get.k3s.io | \
        INSTALL_K3S_VERSION="$K3S_VERSION" \
        INSTALL_K3S_EXEC="${install_opts[*]}" \
        sh -

    # Attendre que k3s démarre
    log INFO "Attente du démarrage de k3s..."
    sleep 10

    # Vérifier l'installation
    if sudo k3s kubectl get nodes &> /dev/null; then
        log OK "k3s installé avec succès"
    else
        die "k3s n'a pas démarré correctement"
    fi

    # Configurer kubectl pour l'utilisateur
    setup_kubectl_linux
}

setup_kubectl_linux() {
    log INFO "Configuration de kubectl..."

    mkdir -p "$HOME/.kube"

    # Copier la config
    sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
    chmod 600 "$HOME/.kube/config"

    log OK "kubectl configuré"

    # Ajouter l'alias au shell
    local shell_rc
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_rc="$HOME/.bashrc"
    fi

    if [[ -n "${shell_rc:-}" ]]; then
        if ! grep -q "alias k=" "$shell_rc"; then
            echo "" >> "$shell_rc"
            echo "# Kubernetes aliases" >> "$shell_rc"
            echo "alias k='kubectl'" >> "$shell_rc"
            echo "alias kns='kubectl config set-context --current --namespace'" >> "$shell_rc"
            log OK "Aliases ajoutés à $shell_rc"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Installation k3s (macOS via Docker)
# -----------------------------------------------------------------------------

install_k3s_macos() {
    log INFO "Installation de k3s sur macOS via Docker..."

    # Sur Mac, k3s tourne dans un container Docker
    # Alternative: utiliser Rancher Desktop ou k3d

    log WARN "k3s natif n'est pas supporté sur macOS."
    log INFO "Options disponibles :"
    echo ""
    echo "  1. Rancher Desktop (recommandé)"
    echo "     brew install --cask rancher"
    echo ""
    echo "  2. k3d (k3s dans Docker)"
    echo "     brew install k3d"
    echo "     k3d cluster create phoenix --api-port 6443 -p '18789:18789@loadbalancer'"
    echo ""
    echo "  3. Docker Desktop Kubernetes"
    echo "     Activer Kubernetes dans les préférences Docker Desktop"
    echo ""

    # Proposer l'installation de k3d
    read -rp "Voulez-vous installer k3d maintenant ? [y/N] " response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        install_k3d_macos
    else
        log INFO "Installation annulée. Choisissez une option manuellement."
        exit 0
    fi
}

install_k3d_macos() {
    log INFO "Installation de k3d..."

    # Vérifier Homebrew
    if ! check_command brew; then
        log INFO "Installation de Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Installer k3d
    brew install k3d

    # Installer kubectl si pas présent
    if ! check_command kubectl; then
        brew install kubectl
    fi

    log OK "k3d installé"

    # Créer le cluster
    create_k3d_cluster
}

create_k3d_cluster() {
    log INFO "Création du cluster k3d..."

    # Vérifier si le cluster existe déjà
    if k3d cluster list 2>/dev/null | grep -q "phoenix"; then
        log WARN "Le cluster 'phoenix' existe déjà"
        read -rp "Voulez-vous le supprimer et recréer ? [y/N] " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            k3d cluster delete phoenix
        else
            return 0
        fi
    fi

    # Créer le cluster
    k3d cluster create phoenix \
        --api-port 6443 \
        --servers 1 \
        --agents 0 \
        --port "18789:18789@loadbalancer" \
        --port "31789:31789@loadbalancer" \
        --k3s-arg "--disable=traefik@server:0" \
        --k3s-arg "--disable=servicelb@server:0" \
        --wait

    log OK "Cluster k3d 'phoenix' créé"

    # Configurer kubectl
    k3d kubeconfig merge phoenix --kubeconfig-switch-context

    log OK "kubectl configuré pour le cluster 'phoenix'"
}

# -----------------------------------------------------------------------------
# Post-installation
# -----------------------------------------------------------------------------

post_install() {
    log INFO "Configuration post-installation..."

    # Vérifier que kubectl fonctionne
    if ! kubectl cluster-info &> /dev/null; then
        die "kubectl ne peut pas se connecter au cluster"
    fi

    # Afficher les infos du cluster
    echo ""
    log INFO "Informations du cluster :"
    kubectl cluster-info
    echo ""

    # Afficher les nodes
    log INFO "Nodes :"
    kubectl get nodes -o wide
    echo ""

    # Créer le namespace phoenix
    if ! kubectl get namespace phoenix &> /dev/null; then
        kubectl create namespace phoenix
        log OK "Namespace 'phoenix' créé"
    else
        log OK "Namespace 'phoenix' existe déjà"
    fi

    log OK "Installation terminée !"
    echo ""
    echo "Prochaines étapes :"
    echo "  1. Configurer Ollama : ./setup-ollama.sh"
    echo "  2. Déployer Phoenix : ./deploy-phoenix.sh"
    echo ""
    echo "Logs de l'installation : $LOG_FILE"
}

# -----------------------------------------------------------------------------
# Désinstallation
# -----------------------------------------------------------------------------

uninstall_k3s() {
    log WARN "Désinstallation de k3s..."

    local os
    os="$(detect_os)"

    if [[ "$os" == "linux" ]]; then
        if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
            sudo /usr/local/bin/k3s-uninstall.sh
            log OK "k3s désinstallé"
        else
            log WARN "Script de désinstallation non trouvé"
        fi
    else
        # macOS avec k3d
        if check_command k3d; then
            k3d cluster delete phoenix 2>/dev/null || true
            log OK "Cluster k3d supprimé"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Point d'entrée
# -----------------------------------------------------------------------------

main() {
    echo "=============================================="
    echo " Installation k3s pour Phoenix"
    echo " Version: 1.0.0"
    echo "=============================================="
    echo ""

    # Parser les arguments
    case "${1:-install}" in
        install)
            check_prerequisites

            local os
            os="$(detect_os)"

            if [[ "$os" == "linux" ]]; then
                install_k3s_linux
            else
                install_k3s_macos
            fi

            post_install
            ;;
        uninstall)
            uninstall_k3s
            ;;
        status)
            kubectl cluster-info
            kubectl get nodes -o wide
            ;;
        *)
            echo "Usage: $SCRIPT_NAME {install|uninstall|status}"
            exit 1
            ;;
    esac
}

main "$@"
