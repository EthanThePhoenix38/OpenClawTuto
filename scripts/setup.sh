#!/usr/bin/env bash
# =============================================================================
# Phoenix — Script d'installation One-Click (Onboarding)
# Version: 2.0.0
# Auteur: Ethan Bernier (ORCID: 0009-0008-9839-5763)
# Date: 2026-02-13
# Description: Assistant interactif pour configurer et lancer Phoenix
# =============================================================================
#
# USAGE :
#   ./scripts/setup.sh              # Onboarding interactif complet
#   ./scripts/setup.sh --profile local   # Forcer un profil
#   ./scripts/setup.sh --help       # Aide
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Couleurs et formatage
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Emojis
CHECK="✅"
CROSS="❌"
WARN="⚠️ "
ROCKET="🚀"
SHIELD="🛡️ "
LOCK="🔐"
GEAR="⚙️ "
PACKAGE="📦"
DOCKER_EMOJI="🐳"
CLOUD="☁️ "
HOME_EMOJI="🏠"

# -----------------------------------------------------------------------------
# Variables globales
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="${PROJECT_DIR}/docker"
ENV_FILE="${DOCKER_DIR}/.env"
ENV_EXAMPLE="${DOCKER_DIR}/.env.example"
COMPOSE_FILE="${DOCKER_DIR}/docker-compose.yml"

PROFILE=""
FORCE_PROFILE=""
MIN_DOCKER_VERSION="24.0"
MIN_RAM_GB=8
PHOENIX_VERSION="2026.1.30"

# -----------------------------------------------------------------------------
# Fonctions utilitaires
# -----------------------------------------------------------------------------
print_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                              ║"
    echo "  ║     🦞  Phoenix Secure Deployment — Setup Wizard  🦞       ║"
    echo "  ║                  Version ${PHOENIX_VERSION}                         ║"
    echo "  ║                                                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DIM}  Post-CVE-2026-25253 Ultra-Secure Configuration${NC}"
    echo ""
}

print_step() {
    echo -e "\n${BLUE}${BOLD}━━━ $1 ━━━${NC}\n"
}

print_ok() {
    echo -e "  ${GREEN}${CHECK} $1${NC}"
}

print_warn() {
    echo -e "  ${YELLOW}${WARN} $1${NC}"
}

print_err() {
    echo -e "  ${RED}${CROSS} $1${NC}"
}

print_info() {
    echo -e "  ${CYAN}${GEAR} $1${NC}"
}

ask() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local result=""

    if [[ -n "$default" ]]; then
        echo -ne "  ${BOLD}${prompt}${NC} ${DIM}[${default}]${NC}: "
    else
        echo -ne "  ${BOLD}${prompt}${NC}: "
    fi
    read -r result
    result="${result:-$default}"
    eval "$var_name='$result'"
}

ask_secret() {
    local prompt="$1"
    local var_name="$2"
    local result=""
    echo -ne "  ${BOLD}${prompt}${NC}: "
    read -rs result
    echo ""
    eval "$var_name='$result'"
}

confirm() {
    local prompt="$1"
    local answer=""
    echo -ne "  ${BOLD}${prompt}${NC} ${DIM}[O/n]${NC}: "
    read -r answer
    [[ "$answer" =~ ^[OoYy]?$ ]]
}

# -----------------------------------------------------------------------------
# Vérifications système
# -----------------------------------------------------------------------------
check_prerequisites() {
    print_step "${PACKAGE} Vérification des prérequis"

    local all_ok=true

    # Docker
    if command -v docker &>/dev/null; then
        local docker_version
        docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0")
        print_ok "Docker installé (v${docker_version})"

        # Vérifier que Docker tourne
        if docker info &>/dev/null; then
            print_ok "Docker daemon actif"
        else
            print_err "Docker daemon ne répond pas — lancez Docker Desktop"
            all_ok=false
        fi
    else
        print_err "Docker non installé — https://docs.docker.com/get-docker/"
        all_ok=false
    fi

    # Docker Compose
    if docker compose version &>/dev/null; then
        local compose_version
        compose_version=$(docker compose version --short 2>/dev/null || echo "?")
        print_ok "Docker Compose installé (v${compose_version})"
    else
        print_err "Docker Compose non installé"
        all_ok=false
    fi

    # RAM disponible
    if [[ "$(uname)" == "Darwin" ]]; then
        local total_ram_gb
        total_ram_gb=$(( $(sysctl -n hw.memsize) / 1073741824 ))
        if (( total_ram_gb >= MIN_RAM_GB )); then
            print_ok "RAM : ${total_ram_gb} Go (minimum : ${MIN_RAM_GB} Go)"
        else
            print_warn "RAM : ${total_ram_gb} Go (recommandé : ${MIN_RAM_GB} Go+)"
        fi
    fi

    # Architecture
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        print_ok "Architecture : Apple Silicon (${arch}) ${CHECK}"
    else
        print_info "Architecture : ${arch}"
    fi

    # Ollama (optionnel)
    if command -v ollama &>/dev/null; then
        print_ok "Ollama installé (LLM locaux disponibles)"
    else
        print_warn "Ollama non installé — LLM locaux indisponibles"
        print_info "  Installer : curl -fsSL https://ollama.com/install.sh | sh"
    fi

    if [[ "$all_ok" == false ]]; then
        echo ""
        print_err "Certains prérequis manquent. Corrigez-les puis relancez ce script."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Choix du profil de déploiement
# -----------------------------------------------------------------------------
choose_profile() {
    print_step "${ROCKET} Choix du mode de déploiement"

    if [[ -n "$FORCE_PROFILE" ]]; then
        PROFILE="$FORCE_PROFILE"
        print_info "Profil forcé : ${PROFILE}"
        return
    fi

    echo -e "  Choisissez votre mode de déploiement :\n"
    echo -e "  ${GREEN}${BOLD}1) ${HOME_EMOJI}  local${NC}  — Docker simple, LLM locaux (Ollama/LM Studio)"
    echo -e "     ${DIM}Usage personnel, pas de proxy, rapide à configurer${NC}\n"
    echo -e "  ${BLUE}${BOLD}2) ${SHIELD} k3d${NC}    — Docker + proxy Squid + monitoring Prometheus/Grafana"
    echo -e "     ${DIM}Zero-Trust, isolation réseau, whitelist internet stricte${NC}\n"
    echo -e "  ${MAGENTA}${BOLD}3) ${CLOUD} koyeb${NC}  — Cloud Koyeb, API keys obligatoires"
    echo -e "     ${DIM}Hébergement cloud, pas de LLM local, scalable${NC}\n"

    local choice
    ask "Votre choix (1/2/3)" "1" choice

    case "$choice" in
        1|local)  PROFILE="local" ;;
        2|k3d)    PROFILE="k3d" ;;
        3|koyeb)  PROFILE="koyeb" ;;
        *)
            print_err "Choix invalide. Utilisation du profil 'local'."
            PROFILE="local"
            ;;
    esac

    echo ""
    print_ok "Profil sélectionné : ${BOLD}${PROFILE}${NC}"
}

# -----------------------------------------------------------------------------
# Configuration de la sécurité
# -----------------------------------------------------------------------------
configure_security() {
    print_step "${LOCK} Configuration de la sécurité"

    echo -e "  ${YELLOW}${BOLD}IMPORTANT : Ces paramètres protègent votre instance Phoenix.${NC}"
    echo -e "  ${DIM}Conformité post-CVE-2026-25253 (RCE critique patchée en v2026.1.29)${NC}\n"

    # Token gateway
    local generated_token
    generated_token=$(openssl rand -hex 32 2>/dev/null || head -c 64 /dev/urandom | xxd -p | tr -d '\n' | head -c 64)

    echo -e "  ${BOLD}Token d'authentification gateway :${NC}"
    echo -e "  ${DIM}Un token sécurisé a été généré automatiquement.${NC}"

    if confirm "Utiliser le token généré automatiquement ?"; then
        GATEWAY_TOKEN="$generated_token"
        print_ok "Token généré automatiquement"
    else
        ask_secret "Entrez votre token personnalisé (min 32 caractères)" GATEWAY_TOKEN
        if (( ${#GATEWAY_TOKEN} < 32 )); then
            print_warn "Token trop court — utilisation du token généré"
            GATEWAY_TOKEN="$generated_token"
        fi
    fi

    # Auth mode
    AUTH_MODE="token"
    print_ok "Mode d'authentification : token (recommandé)"

    # DM Access
    DM_ACCESS="pairing"
    print_ok "Politique DM : pairing (couplage sécurisé)"

    # mDNS
    MDNS_MODE="off"
    print_ok "Découverte mDNS : désactivée (production)"

    # Sandbox
    SANDBOX_SCOPE="agent"
    print_ok "Sandbox scope : agent"

    SANDBOX_MODE="non-main"
    print_ok "Sandbox mode : non-main"

    # Control UI
    CONTROL_UI_INSECURE="false"
    print_ok "Control UI auth non-sécurisée : désactivée"
}

# -----------------------------------------------------------------------------
# Configuration des API Keys
# -----------------------------------------------------------------------------
configure_api_keys() {
    print_step "🔑 Configuration des clés API"

    ANTHROPIC_KEY=""
    OPENAI_KEY=""
    GOOGLE_KEY=""
    MISTRAL_KEY=""

    if [[ "$PROFILE" == "koyeb" ]]; then
        echo -e "  ${YELLOW}${BOLD}En mode cloud, au moins une clé API est OBLIGATOIRE.${NC}\n"
    else
        echo -e "  ${DIM}En mode local/k3d, les clés sont optionnelles si vous utilisez Ollama.${NC}\n"
    fi

    if confirm "Configurer une clé Anthropic (Claude) ?"; then
        ask_secret "  Clé Anthropic (sk-ant-...)" ANTHROPIC_KEY
        [[ -n "$ANTHROPIC_KEY" ]] && print_ok "Clé Anthropic configurée"
    fi

    if confirm "Configurer une clé OpenAI (GPT) ?"; then
        ask_secret "  Clé OpenAI (sk-...)" OPENAI_KEY
        [[ -n "$OPENAI_KEY" ]] && print_ok "Clé OpenAI configurée"
    fi

    if confirm "Configurer une clé Google AI (Gemini) ?"; then
        ask_secret "  Clé Google AI" GOOGLE_KEY
        [[ -n "$GOOGLE_KEY" ]] && print_ok "Clé Google AI configurée"
    fi

    if confirm "Configurer une clé Mistral AI ?"; then
        ask_secret "  Clé Mistral AI" MISTRAL_KEY
        [[ -n "$MISTRAL_KEY" ]] && print_ok "Clé Mistral AI configurée"
    fi

    # Vérification koyeb
    if [[ "$PROFILE" == "koyeb" ]] && [[ -z "$ANTHROPIC_KEY" ]] && [[ -z "$OPENAI_KEY" ]] && [[ -z "$GOOGLE_KEY" ]] && [[ -z "$MISTRAL_KEY" ]]; then
        print_err "Mode koyeb : au moins une clé API est requise !"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Configuration du monitoring (k3d)
# -----------------------------------------------------------------------------
configure_monitoring() {
    if [[ "$PROFILE" != "k3d" ]]; then
        return
    fi

    print_step "📊 Configuration du monitoring"

    local grafana_pw
    local generated_pw
    generated_pw=$(openssl rand -base64 16 2>/dev/null || echo "ChangeMe$(date +%s)")

    echo -e "  ${DIM}Grafana sera accessible sur http://localhost:3000${NC}\n"

    ask "Mot de passe admin Grafana" "$generated_pw" grafana_pw
    GRAFANA_PW="$grafana_pw"
    print_ok "Mot de passe Grafana configuré"

    ask "Rétention Prometheus (jours)" "7" PROMETHEUS_RETENTION
    print_ok "Rétention : ${PROMETHEUS_RETENTION} jours"
}

# -----------------------------------------------------------------------------
# Génération du fichier .env
# -----------------------------------------------------------------------------
generate_env() {
    print_step "📝 Génération du fichier .env"

    if [[ -f "$ENV_FILE" ]]; then
        local backup="${ENV_FILE}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$ENV_FILE" "$backup"
        print_warn "Fichier .env existant sauvegardé : $(basename "$backup")"
    fi

    cat > "$ENV_FILE" <<EOF
# =============================================================================
# Phoenix .env — Généré par setup.sh le $(date '+%Y-%m-%d %H:%M:%S')
# Profil : ${PROFILE}
# =============================================================================

# Mode de déploiement
DEPLOY_MODE=${PROFILE}

# --- Sécurité (post-CVE-2026-25253) ---
PHOENIX_AUTH_MODE=${AUTH_MODE}
PHOENIX_GATEWAY_TOKEN=${GATEWAY_TOKEN}
PHOENIX_DM_ACCESS=${DM_ACCESS}
PHOENIX_MDNS_MODE=${MDNS_MODE}
PHOENIX_CONTROL_UI_INSECURE_AUTH=${CONTROL_UI_INSECURE}
PHOENIX_SANDBOX_SCOPE=${SANDBOX_SCOPE}
PHOENIX_SANDBOX_MODE=${SANDBOX_MODE}

# --- Serveur ---
PHOENIX_PORT=18789
PHOENIX_HOST=$( [[ "$PROFILE" == "koyeb" ]] && echo "0.0.0.0" || echo "127.0.0.1" )
PHOENIX_LOG_LEVEL=info
TZ=Europe/Paris

# --- API Keys ---
ANTHROPIC_API_KEY=${ANTHROPIC_KEY}
OPENAI_API_KEY=${OPENAI_KEY}
GOOGLE_AI_API_KEY=${GOOGLE_KEY}
MISTRAL_API_KEY=${MISTRAL_KEY}
EOF

    # LLM locaux (local & k3d uniquement)
    if [[ "$PROFILE" != "koyeb" ]]; then
        cat >> "$ENV_FILE" <<EOF

# --- LLM Locaux ---
OLLAMA_HOST=http://host.docker.internal:11434
LM_STUDIO_HOST=http://host.docker.internal:1234
EOF
    fi

    # Proxy (k3d uniquement)
    if [[ "$PROFILE" == "k3d" ]]; then
        cat >> "$ENV_FILE" <<EOF

# --- Proxy Squid (whitelist) ---
HTTP_PROXY=http://squid:3128
HTTPS_PROXY=http://squid:3128
NO_PROXY=localhost,127.0.0.1,host.docker.internal,ollama

# --- Monitoring ---
GRAFANA_PASSWORD=${GRAFANA_PW}
PROMETHEUS_RETENTION_DAYS=${PROMETHEUS_RETENTION}
EOF
    fi

    # Ressources
    cat >> "$ENV_FILE" <<EOF

# --- Ressources ---
PHOENIX_CPU_LIMIT=2
PHOENIX_MEM_LIMIT=2G
PHOENIX_CPU_RESERVATION=0.5
PHOENIX_MEM_RESERVATION=512M
PHOENIX_PIDS_LIMIT=256
PHOENIX_TMPFS_SIZE=1073741824
EOF

    chmod 600 "$ENV_FILE"
    print_ok "Fichier .env généré (permissions 600)"
}

# -----------------------------------------------------------------------------
# Lancement
# -----------------------------------------------------------------------------
launch_stack() {
    print_step "${DOCKER_EMOJI} Lancement de la stack"

    echo -e "  ${BOLD}Profil : ${CYAN}${PROFILE}${NC}"
    echo -e "  ${BOLD}Compose : ${DIM}${COMPOSE_FILE}${NC}"
    echo ""

    if ! confirm "Lancer Phoenix maintenant ?"; then
        echo ""
        print_info "Pour lancer manuellement :"
        echo -e "    ${BOLD}cd ${DOCKER_DIR} && docker compose --profile ${PROFILE} up -d${NC}"
        echo ""
        return
    fi

    echo ""
    print_info "Démarrage en cours..."

    cd "$DOCKER_DIR"
    docker compose --profile "$PROFILE" up -d

    echo ""
    print_ok "Stack démarrée !"
    echo ""

    # Attendre le healthcheck
    print_info "Vérification du healthcheck..."
    local retries=0
    local max_retries=12

    while (( retries < max_retries )); do
        if curl -sf http://localhost:18789/health &>/dev/null; then
            print_ok "Phoenix est opérationnel !"
            break
        fi
        retries=$((retries + 1))
        sleep 5
    done

    if (( retries >= max_retries )); then
        print_warn "Le healthcheck n'a pas répondu dans les 60s"
        print_info "Vérifiez : docker compose --profile ${PROFILE} logs -f phoenix"
    fi
}

# -----------------------------------------------------------------------------
# Résumé final
# -----------------------------------------------------------------------------
print_summary() {
    print_step "${ROCKET} Installation terminée"

    echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "  ${GREEN}${BOLD}║  🦞 Phoenix est prêt !                          ║${NC}"
    echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Profil :${NC}       ${PROFILE}"
    echo -e "  ${BOLD}Gateway :${NC}      http://localhost:18789"

    if [[ "$PROFILE" == "k3d" ]]; then
        echo -e "  ${BOLD}Prometheus :${NC}   http://localhost:9090"
        echo -e "  ${BOLD}Grafana :${NC}      http://localhost:3000 (admin / ***)"
        echo -e "  ${BOLD}Proxy Squid :${NC}  Actif (whitelist stricte)"
    fi

    echo ""
    echo -e "  ${BOLD}Commandes utiles :${NC}"
    echo -e "    docker compose --profile ${PROFILE} logs -f        ${DIM}# Logs${NC}"
    echo -e "    docker compose --profile ${PROFILE} ps             ${DIM}# État${NC}"
    echo -e "    docker compose --profile ${PROFILE} down           ${DIM}# Arrêter${NC}"
    echo -e "    docker compose exec phoenix phoenix security audit --deep"
    echo ""
    echo -e "  ${YELLOW}${BOLD}${LOCK} Gardez votre token en sécurité :${NC}"
    echo -e "    ${DIM}${ENV_FILE}${NC}"
    echo ""
    echo -e "  ${DIM}📖 Documentation : https://github.com/EthanThePhoenix38/Phoenix${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Aide
# -----------------------------------------------------------------------------
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --profile <local|k3d|koyeb>  Forcer un profil (saute le choix interactif)"
    echo "  --help                        Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0                    # Onboarding interactif"
    echo "  $0 --profile local   # Installation locale directe"
    echo "  $0 --profile k3d     # Installation k3d avec proxy + monitoring"
    echo ""
}

# -----------------------------------------------------------------------------
# Parsing des arguments
# -----------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                FORCE_PROFILE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_err "Option inconnue : $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"
    print_banner
    check_prerequisites
    choose_profile
    configure_security
    configure_api_keys
    configure_monitoring
    generate_env
    launch_stack
    print_summary
}

main "$@"
