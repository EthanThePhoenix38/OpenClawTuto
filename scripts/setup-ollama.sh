#!/bin/bash
# =============================================================================
# Script de configuration Ollama pour OpenClaw
# Version: 1.0.0
# Auteur: Ethan Bernier (ORCID: 0009-0008-9839-5763)
# Description: Installation et configuration d'Ollama sur Mac/Linux
# =============================================================================
#
# USAGE :
#   chmod +x setup-ollama.sh
#   ./setup-ollama.sh                 # Installation complète
#   ./setup-ollama.sh --models        # Télécharger les modèles recommandés
#   ./setup-ollama.sh --status        # Vérifier l'état
#   ./setup-ollama.sh --gpu           # Vérifier le support GPU
#
# PRÉREQUIS :
#   - macOS 12+ (Apple Silicon recommandé) ou Linux
#   - 16 Go RAM minimum pour les modèles 7B
#   - 64 Go RAM pour les modèles 70B
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly LOG_FILE="/tmp/setup-ollama-$(date +%Y%m%d-%H%M%S).log"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Modèles recommandés
declare -A RECOMMENDED_MODELS=(
    ["llama3.1:8b"]="4.7 Go - Rapide, bon pour le quotidien"
    ["llama3.1:70b"]="40 Go - Puissant, nécessite 64 Go RAM"
    ["codellama:13b"]="7 Go - Spécialisé code"
    ["mistral:7b"]="4 Go - Équilibré, multilingue"
    ["deepseek-coder:6.7b"]="4 Go - Code, très efficace"
    ["qwen2:7b"]="4.4 Go - Multilingue, bon en français"
)

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

detect_os() {
    local os
    os="$(uname -s)"
    case "$os" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      die "Système non supporté: $os" ;;
    esac
}

# -----------------------------------------------------------------------------
# Détection du hardware
# -----------------------------------------------------------------------------

detect_hardware() {
    log INFO "Détection du hardware..."

    local os
    os="$(detect_os)"

    if [[ "$os" == "macos" ]]; then
        # Détection Mac
        local chip
        chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")

        local ram_bytes
        ram_bytes=$(sysctl -n hw.memsize)
        local ram_gb=$((ram_bytes / 1024 / 1024 / 1024))

        # Vérifier Apple Silicon
        if sysctl -n hw.optional.arm64 2>/dev/null | grep -q "1"; then
            local gpu_cores
            gpu_cores=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i "Total Number of Cores" | head -1 | awk '{print $NF}' || echo "Unknown")

            log OK "Apple Silicon détecté"
            log INFO "  Processeur: $chip"
            log INFO "  RAM: ${ram_gb} Go"
            log INFO "  GPU Cores: $gpu_cores"

            # Recommandations
            if [[ $ram_gb -ge 64 ]]; then
                log OK "  → Modèles 70B supportés"
            elif [[ $ram_gb -ge 32 ]]; then
                log OK "  → Modèles 13B-34B recommandés"
            elif [[ $ram_gb -ge 16 ]]; then
                log OK "  → Modèles 7B-8B recommandés"
            else
                log WARN "  → RAM limitée, modèles 3B-7B uniquement"
            fi
        else
            log INFO "Intel Mac détecté"
            log INFO "  Processeur: $chip"
            log INFO "  RAM: ${ram_gb} Go"
            log WARN "  → Performance GPU limitée (pas de Metal natif)"
        fi
    else
        # Linux
        local cpu
        cpu=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)

        local ram_kb
        ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local ram_gb=$((ram_kb / 1024 / 1024))

        log INFO "Linux détecté"
        log INFO "  CPU: $cpu"
        log INFO "  RAM: ${ram_gb} Go"

        # Vérifier NVIDIA GPU
        if check_command nvidia-smi; then
            local gpu_info
            gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo "Erreur")
            log OK "GPU NVIDIA détecté: $gpu_info"
        elif [[ -d /sys/class/drm/card0 ]]; then
            log INFO "GPU intégré détecté (AMD/Intel)"
        else
            log WARN "Aucun GPU dédié détecté"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Installation d'Ollama
# -----------------------------------------------------------------------------

install_ollama() {
    log STEP "Installation d'Ollama..."

    if check_command ollama; then
        local version
        version=$(ollama --version 2>/dev/null | head -1 || echo "Unknown")
        log OK "Ollama déjà installé: $version"

        # Proposer la mise à jour
        read -rp "Mettre à jour Ollama ? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    local os
    os="$(detect_os)"

    if [[ "$os" == "macos" ]]; then
        install_ollama_macos
    else
        install_ollama_linux
    fi
}

install_ollama_macos() {
    log INFO "Installation d'Ollama sur macOS..."

    # Méthode 1: Homebrew (recommandée)
    if check_command brew; then
        log INFO "Installation via Homebrew..."
        brew install ollama
    else
        # Méthode 2: Script officiel
        log INFO "Installation via script officiel..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi

    log OK "Ollama installé"
}

install_ollama_linux() {
    log INFO "Installation d'Ollama sur Linux..."

    # Script officiel
    curl -fsSL https://ollama.com/install.sh | sh

    # Configurer le service systemd
    if check_command systemctl; then
        sudo systemctl enable ollama
        sudo systemctl start ollama
        log OK "Service Ollama démarré"
    fi

    log OK "Ollama installé"
}

# -----------------------------------------------------------------------------
# Démarrage d'Ollama
# -----------------------------------------------------------------------------

start_ollama() {
    log STEP "Démarrage d'Ollama..."

    # Vérifier si Ollama tourne déjà
    if curl -s --connect-timeout 2 http://localhost:11434/api/tags &> /dev/null; then
        log OK "Ollama est déjà actif"
        return 0
    fi

    local os
    os="$(detect_os)"

    if [[ "$os" == "macos" ]]; then
        # Sur Mac, lancer en background
        log INFO "Démarrage d'Ollama en arrière-plan..."
        ollama serve &> /tmp/ollama.log &
        local pid=$!
        echo "$pid" > /tmp/ollama.pid

        # Attendre le démarrage
        local retries=30
        while [[ $retries -gt 0 ]]; do
            if curl -s --connect-timeout 1 http://localhost:11434/api/tags &> /dev/null; then
                log OK "Ollama démarré (PID: $pid)"
                return 0
            fi
            sleep 1
            ((retries--))
        done

        log ERROR "Ollama n'a pas démarré. Vérifiez /tmp/ollama.log"
        return 1
    else
        # Sur Linux, utiliser systemd
        if check_command systemctl; then
            sudo systemctl start ollama
            sleep 2
            if systemctl is-active --quiet ollama; then
                log OK "Service Ollama démarré"
            else
                log ERROR "Le service Ollama n'a pas démarré"
                sudo systemctl status ollama
                return 1
            fi
        else
            # Fallback: démarrage manuel
            ollama serve &> /tmp/ollama.log &
            sleep 5
        fi
    fi
}

# -----------------------------------------------------------------------------
# Téléchargement des modèles
# -----------------------------------------------------------------------------

download_models() {
    log STEP "Téléchargement des modèles..."

    # Vérifier qu'Ollama tourne
    if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
        start_ollama
    fi

    echo ""
    echo "Modèles recommandés pour OpenClaw :"
    echo ""

    local i=1
    local models=()
    for model in "${!RECOMMENDED_MODELS[@]}"; do
        echo "  $i) $model - ${RECOMMENDED_MODELS[$model]}"
        models+=("$model")
        ((i++))
    done

    echo ""
    echo "  a) Télécharger tous les modèles essentiels (8B)"
    echo "  q) Quitter"
    echo ""

    read -rp "Choix (numéro, 'a' ou 'q'): " choice

    case "$choice" in
        q|Q)
            return 0
            ;;
        a|A)
            # Télécharger les modèles essentiels
            download_model "llama3.1:8b"
            download_model "mistral:7b"
            download_model "codellama:7b"
            ;;
        [1-9])
            local idx=$((choice - 1))
            if [[ $idx -lt ${#models[@]} ]]; then
                download_model "${models[$idx]}"
            else
                log ERROR "Choix invalide"
            fi
            ;;
        *)
            log ERROR "Choix invalide"
            ;;
    esac
}

download_model() {
    local model="$1"

    log INFO "Téléchargement de $model..."
    echo ""

    if ollama pull "$model"; then
        log OK "$model téléchargé"
    else
        log ERROR "Échec du téléchargement de $model"
    fi
}

# -----------------------------------------------------------------------------
# Statut
# -----------------------------------------------------------------------------

show_status() {
    log INFO "État d'Ollama"
    echo ""

    # Vérifier si Ollama est installé
    if ! check_command ollama; then
        log ERROR "Ollama n'est pas installé"
        return 1
    fi

    local version
    version=$(ollama --version 2>/dev/null | head -1 || echo "Unknown")
    log OK "Version: $version"

    # Vérifier si Ollama tourne
    if curl -s --connect-timeout 2 http://localhost:11434/api/tags &> /dev/null; then
        log OK "Service: Actif (port 11434)"
    else
        log WARN "Service: Inactif"
        return 0
    fi

    # Lister les modèles
    echo ""
    echo "=== Modèles installés ==="
    ollama list
    echo ""

    # Espace disque utilisé
    local models_dir
    if [[ "$(detect_os)" == "macos" ]]; then
        models_dir="$HOME/.ollama/models"
    else
        models_dir="/usr/share/ollama/.ollama/models"
    fi

    if [[ -d "$models_dir" ]]; then
        local size
        size=$(du -sh "$models_dir" 2>/dev/null | cut -f1)
        log INFO "Espace utilisé: $size"
    fi

    # Test de génération
    echo ""
    read -rp "Tester avec un prompt simple ? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        log INFO "Test de génération..."
        local model
        model=$(ollama list | awk 'NR==2 {print $1}')
        if [[ -n "$model" ]]; then
            echo "Modèle: $model"
            echo "Prompt: 'Say hello in French'"
            echo ""
            ollama run "$model" "Say hello in French in one sentence" 2>/dev/null || true
        else
            log WARN "Aucun modèle disponible pour le test"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Vérification GPU
# -----------------------------------------------------------------------------

check_gpu() {
    log INFO "Vérification du support GPU..."
    echo ""

    local os
    os="$(detect_os)"

    if [[ "$os" == "macos" ]]; then
        # macOS - Apple Metal
        log INFO "macOS utilise Apple Metal pour l'accélération GPU"

        if sysctl -n hw.optional.arm64 2>/dev/null | grep -q "1"; then
            log OK "Apple Silicon détecté - Metal activé automatiquement"

            # Afficher les specs GPU
            system_profiler SPDisplaysDataType 2>/dev/null | grep -A10 "Chipset Model" | head -15
        else
            log WARN "Intel Mac - Metal disponible mais moins performant"
        fi

        # Vérifier l'utilisation GPU pendant une inférence
        echo ""
        read -rp "Lancer un benchmark GPU ? [y/N] " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            benchmark_gpu
        fi
    else
        # Linux - NVIDIA CUDA ou ROCm
        if check_command nvidia-smi; then
            log OK "GPU NVIDIA détecté"
            nvidia-smi
        elif check_command rocm-smi; then
            log OK "GPU AMD (ROCm) détecté"
            rocm-smi
        else
            log WARN "Aucun GPU dédié détecté - CPU uniquement"
        fi
    fi
}

benchmark_gpu() {
    log INFO "Benchmark GPU..."

    # Vérifier qu'un modèle est disponible
    local model
    model=$(ollama list 2>/dev/null | awk 'NR==2 {print $1}')

    if [[ -z "$model" ]]; then
        log WARN "Aucun modèle disponible. Téléchargez d'abord un modèle."
        return 1
    fi

    log INFO "Modèle utilisé: $model"
    echo ""

    # Lancer une inférence et mesurer
    local start_time
    start_time=$(date +%s.%N)

    echo "Génération d'un texte de 100 tokens..."
    ollama run "$model" "Write a 100-word paragraph about artificial intelligence." --verbose 2>&1 | tail -5

    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(echo "$end_time - $start_time" | bc)

    echo ""
    log OK "Temps total: ${duration}s"

    # Sur Mac, afficher l'activité GPU
    if [[ "$(detect_os)" == "macos" ]]; then
        echo ""
        log INFO "Pour monitorer le GPU en temps réel:"
        echo "  sudo powermetrics --samplers gpu_power -i 1000"
    fi
}

# -----------------------------------------------------------------------------
# Configuration pour OpenClaw
# -----------------------------------------------------------------------------

configure_for_openclaw() {
    log STEP "Configuration pour OpenClaw..."

    # Vérifier qu'Ollama tourne
    if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
        log ERROR "Ollama n'est pas actif"
        return 1
    fi

    # Vérifier qu'au moins un modèle est installé
    local models
    models=$(ollama list 2>/dev/null | tail -n +2 | wc -l)

    if [[ $models -eq 0 ]]; then
        log WARN "Aucun modèle installé"
        read -rp "Télécharger llama3.1:8b maintenant ? [Y/n] " response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            download_model "llama3.1:8b"
        fi
    fi

    # Afficher la configuration
    echo ""
    log OK "Configuration Ollama pour OpenClaw :"
    echo ""
    echo "  OLLAMA_HOST=http://localhost:11434"
    echo "  (ou http://host.docker.internal:11434 depuis un container)"
    echo ""

    # Tester la connectivité
    log INFO "Test de l'API Ollama..."
    local response
    response=$(curl -s http://localhost:11434/api/tags)

    if echo "$response" | grep -q "models"; then
        log OK "API Ollama fonctionnelle"
    else
        log ERROR "L'API Ollama ne répond pas correctement"
    fi
}

# -----------------------------------------------------------------------------
# Point d'entrée
# -----------------------------------------------------------------------------

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTION]

Options:
  (aucune)          Installation complète
  --models          Télécharger des modèles
  --status          Vérifier l'état d'Ollama
  --gpu             Vérifier le support GPU
  --start           Démarrer Ollama
  --stop            Arrêter Ollama
  --configure       Configurer pour OpenClaw
  --help            Afficher cette aide

Exemples:
  $SCRIPT_NAME                    # Installation complète
  $SCRIPT_NAME --models           # Télécharger des modèles
  $SCRIPT_NAME --gpu              # Benchmark GPU
EOF
}

main() {
    echo "=============================================="
    echo " Configuration Ollama pour OpenClaw"
    echo " Version: 1.0.0"
    echo "=============================================="
    echo ""

    case "${1:-}" in
        ""|--install)
            detect_hardware
            echo ""
            install_ollama
            start_ollama
            echo ""
            download_models
            configure_for_openclaw
            ;;
        --models)
            download_models
            ;;
        --status)
            show_status
            ;;
        --gpu)
            detect_hardware
            check_gpu
            ;;
        --start)
            start_ollama
            ;;
        --stop)
            log INFO "Arrêt d'Ollama..."
            pkill ollama 2>/dev/null || true
            log OK "Ollama arrêté"
            ;;
        --configure)
            configure_for_openclaw
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
