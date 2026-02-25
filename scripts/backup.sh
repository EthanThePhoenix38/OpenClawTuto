#!/usr/bin/env bash
# =============================================================================
# Phoenix Backup Script
# Version: 1.0.0
# Auteur: Ethan Bernier (ORCID: 0009-0008-9839-5763)
# Description: Sauvegarde automatisée avec stratégie 3-2-1
# =============================================================================
#
# STRATÉGIE 3-2-1 :
# - 3 copies des données
# - 2 supports de stockage différents
# - 1 copie hors site (offsite)
#
# USAGE :
#   ./backup.sh [OPTIONS]
#
# OPTIONS :
#   --full          Sauvegarde complète (configs + données + logs)
#   --config        Sauvegarde des configurations uniquement
#   --data          Sauvegarde des données uniquement
#   --restore FILE  Restaurer depuis une archive
#   --list          Lister les sauvegardes disponibles
#   --clean DAYS    Supprimer les sauvegardes > N jours
#   --verify FILE   Vérifier l'intégrité d'une archive
#   --offsite       Synchroniser avec stockage distant (rsync/rclone)
#   --dry-run       Simuler sans exécuter
#   --help          Afficher l'aide
#
# EXEMPLES :
#   ./backup.sh --full                    # Sauvegarde complète
#   ./backup.sh --config --dry-run        # Simuler backup configs
#   ./backup.sh --restore backup.tar.gz   # Restaurer
#   ./backup.sh --clean 30                # Supprimer backups > 30 jours
#   ./backup.sh --offsite                 # Sync vers stockage distant
#
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Couleurs pour les messages
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Répertoires
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly BACKUP_DIR="${BACKUP_DIR:-$HOME/phoenix-backups}"
readonly BACKUP_OFFSITE="${BACKUP_OFFSITE:-}"
readonly BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Horodatage
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

# Namespace Kubernetes
readonly K8S_NAMESPACE="phoenix"

# Mode simulation
DRY_RUN=false

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Vérifier si une commande existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Exécuter ou simuler une commande
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

# Calculer la taille d'un fichier en format lisible
human_size() {
    local file="$1"
    if [ -f "$file" ]; then
        if command_exists numfmt; then
            stat -f%z "$file" 2>/dev/null | numfmt --to=iec || stat --printf="%s" "$file" 2>/dev/null | numfmt --to=iec || echo "N/A"
        else
            ls -lh "$file" | awk '{print $5}'
        fi
    else
        echo "N/A"
    fi
}

# =============================================================================
# AFFICHAGE DE L'AIDE
# =============================================================================

show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                     Phoenix Backup Script v1.0.0                             ║
║                    Sauvegarde Automatisée 3-2-1                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

USAGE:
    ./backup.sh [OPTIONS]

OPTIONS:
    --full          Sauvegarde complète (configs + données + logs + secrets)
    --config        Sauvegarde des fichiers de configuration uniquement
    --data          Sauvegarde des données persistantes uniquement
    --logs          Sauvegarde des logs uniquement
    --k8s           Exporter les ressources Kubernetes (YAML)
    --restore FILE  Restaurer depuis une archive
    --list          Lister les sauvegardes disponibles
    --clean DAYS    Supprimer les sauvegardes plus anciennes que N jours
    --verify FILE   Vérifier l'intégrité d'une archive
    --offsite       Synchroniser avec stockage distant
    --dry-run       Simuler les opérations sans les exécuter
    --help          Afficher cette aide

VARIABLES D'ENVIRONNEMENT:
    BACKUP_DIR              Répertoire de sauvegarde (défaut: ~/phoenix-backups)
    BACKUP_OFFSITE          Destination offsite pour rsync/rclone
    BACKUP_RETENTION_DAYS   Rétention en jours (défaut: 30)

EXEMPLES:
    # Sauvegarde complète
    ./backup.sh --full

    # Sauvegarde configs uniquement (simulation)
    ./backup.sh --config --dry-run

    # Restaurer depuis une archive
    ./backup.sh --restore ~/phoenix-backups/backup_20260130_143022.tar.gz

    # Nettoyer les vieilles sauvegardes
    ./backup.sh --clean 30

    # Synchroniser avec stockage distant
    BACKUP_OFFSITE="user@server:/backups/phoenix" ./backup.sh --offsite

STRATÉGIE 3-2-1:
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  3 copies    │  Local + NAS/Disque externe + Cloud/Offsite             │
    │  2 supports  │  SSD local + NAS/HDD externe                            │
    │  1 offsite   │  Serveur distant ou stockage cloud                      │
    └─────────────────────────────────────────────────────────────────────────┘

CONTENU DES SAUVEGARDES:
    --full    → kubernetes/, docker/, scripts/, config/, data/, logs/
    --config  → kubernetes/, docker/, scripts/, config/
    --data    → data/ (PersistentVolumes, bases de données)
    --logs    → logs/ (journaux d'application et système)
    --k8s     → Export YAML de toutes les ressources Kubernetes

EOF
}

# =============================================================================
# INITIALISATION
# =============================================================================

init_backup_dir() {
    log_step "Initialisation du répertoire de sauvegarde..."

    if [ ! -d "$BACKUP_DIR" ]; then
        run_cmd mkdir -p "$BACKUP_DIR"
        run_cmd chmod 700 "$BACKUP_DIR"
        log_success "Répertoire créé : $BACKUP_DIR"
    else
        log_info "Répertoire existant : $BACKUP_DIR"
    fi

    # Créer les sous-répertoires
    for subdir in full config data logs k8s; do
        run_cmd mkdir -p "$BACKUP_DIR/$subdir"
    done
}

# =============================================================================
# SAUVEGARDE DES CONFIGURATIONS
# =============================================================================

backup_configs() {
    local output_file="$BACKUP_DIR/config/config_${TIMESTAMP}.tar.gz"

    log_step "Sauvegarde des configurations..."

    local dirs_to_backup=()

    # Vérifier les répertoires existants
    [ -d "$PROJECT_ROOT/kubernetes" ] && dirs_to_backup+=("kubernetes")
    [ -d "$PROJECT_ROOT/docker" ] && dirs_to_backup+=("docker")
    [ -d "$PROJECT_ROOT/scripts" ] && dirs_to_backup+=("scripts")
    [ -d "$PROJECT_ROOT/config" ] && dirs_to_backup+=("config")

    if [ ${#dirs_to_backup[@]} -eq 0 ]; then
        log_warning "Aucun répertoire de configuration trouvé"
        return 1
    fi

    log_info "Répertoires inclus : ${dirs_to_backup[*]}"

    # Créer l'archive (exclure les fichiers sensibles)
    run_cmd tar -czvf "$output_file" \
        -C "$PROJECT_ROOT" \
        --exclude='*.env' \
        --exclude='.env*' \
        --exclude='*secret*' \
        --exclude='*.key' \
        --exclude='*.pem' \
        --exclude='node_modules' \
        --exclude='.git' \
        "${dirs_to_backup[@]}"

    if [ "$DRY_RUN" = false ] && [ -f "$output_file" ]; then
        local size=$(human_size "$output_file")
        log_success "Configuration sauvegardée : $output_file ($size)"

        # Créer un checksum
        if command_exists sha256sum; then
            sha256sum "$output_file" > "${output_file}.sha256"
        elif command_exists shasum; then
            shasum -a 256 "$output_file" > "${output_file}.sha256"
        fi
    fi
}

# =============================================================================
# SAUVEGARDE DES DONNÉES
# =============================================================================

backup_data() {
    local output_file="$BACKUP_DIR/data/data_${TIMESTAMP}.tar.gz"

    log_step "Sauvegarde des données..."

    # Répertoires de données potentiels
    local data_paths=(
        "$HOME/.phoenix"
        "$HOME/.ollama/models"
        "/var/lib/phoenix"
    )

    local dirs_to_backup=()

    for path in "${data_paths[@]}"; do
        if [ -d "$path" ]; then
            dirs_to_backup+=("$path")
            log_info "Inclus : $path"
        fi
    done

    # Exporter les PersistentVolumes si kubectl disponible
    if command_exists kubectl; then
        log_info "Export des données Kubernetes PV..."

        # Lister les PVCs du namespace
        local pvcs=$(kubectl get pvc -n "$K8S_NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

        if [ -n "$pvcs" ]; then
            log_info "PVCs trouvés : $pvcs"
        fi
    fi

    if [ ${#dirs_to_backup[@]} -eq 0 ]; then
        log_warning "Aucune donnée à sauvegarder"
        return 0
    fi

    # Créer l'archive
    run_cmd tar -czvf "$output_file" "${dirs_to_backup[@]}" 2>/dev/null || true

    if [ "$DRY_RUN" = false ] && [ -f "$output_file" ]; then
        local size=$(human_size "$output_file")
        log_success "Données sauvegardées : $output_file ($size)"

        # Checksum
        if command_exists sha256sum; then
            sha256sum "$output_file" > "${output_file}.sha256"
        elif command_exists shasum; then
            shasum -a 256 "$output_file" > "${output_file}.sha256"
        fi
    fi
}

# =============================================================================
# SAUVEGARDE DES LOGS
# =============================================================================

backup_logs() {
    local output_file="$BACKUP_DIR/logs/logs_${TIMESTAMP}.tar.gz"

    log_step "Sauvegarde des logs..."

    local log_paths=(
        "/var/log/phoenix"
        "$HOME/.phoenix/logs"
        "/tmp/phoenix"
    )

    local dirs_to_backup=()

    for path in "${log_paths[@]}"; do
        if [ -d "$path" ]; then
            dirs_to_backup+=("$path")
            log_info "Inclus : $path"
        fi
    done

    # Exporter les logs Kubernetes
    if command_exists kubectl; then
        local k8s_logs_dir="$BACKUP_DIR/logs/k8s_${TIMESTAMP}"
        run_cmd mkdir -p "$k8s_logs_dir"

        # Récupérer les logs des pods
        local pods=$(kubectl get pods -n "$K8S_NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

        for pod in $pods; do
            log_info "Export logs : $pod"
            run_cmd kubectl logs "$pod" -n "$K8S_NAMESPACE" > "$k8s_logs_dir/${pod}.log" 2>/dev/null || true

            # Logs du container précédent (si crash)
            run_cmd kubectl logs "$pod" -n "$K8S_NAMESPACE" --previous > "$k8s_logs_dir/${pod}_previous.log" 2>/dev/null || true
        done

        dirs_to_backup+=("$k8s_logs_dir")
    fi

    if [ ${#dirs_to_backup[@]} -eq 0 ]; then
        log_warning "Aucun log à sauvegarder"
        return 0
    fi

    # Créer l'archive
    run_cmd tar -czvf "$output_file" "${dirs_to_backup[@]}" 2>/dev/null || true

    if [ "$DRY_RUN" = false ] && [ -f "$output_file" ]; then
        local size=$(human_size "$output_file")
        log_success "Logs sauvegardés : $output_file ($size)"
    fi

    # Nettoyer le répertoire temporaire
    [ -d "$k8s_logs_dir" ] && rm -rf "$k8s_logs_dir"
}

# =============================================================================
# EXPORT KUBERNETES
# =============================================================================

backup_k8s() {
    local output_file="$BACKUP_DIR/k8s/k8s_${TIMESTAMP}.tar.gz"
    local temp_dir="$BACKUP_DIR/k8s/temp_${TIMESTAMP}"

    log_step "Export des ressources Kubernetes..."

    if ! command_exists kubectl; then
        log_error "kubectl non disponible"
        return 1
    fi

    # Vérifier l'accès au cluster
    if ! kubectl cluster-info &>/dev/null; then
        log_error "Impossible de se connecter au cluster Kubernetes"
        return 1
    fi

    run_cmd mkdir -p "$temp_dir"

    # Ressources à exporter
    local resources=(
        "namespace"
        "deployment"
        "service"
        "configmap"
        "secret"
        "networkpolicy"
        "ingress"
        "serviceaccount"
        "role"
        "rolebinding"
        "persistentvolumeclaim"
    )

    for resource in "${resources[@]}"; do
        log_info "Export : $resource"
        run_cmd kubectl get "$resource" -n "$K8S_NAMESPACE" -o yaml > "$temp_dir/${resource}.yaml" 2>/dev/null || true
    done

    # Exporter les secrets (sans les valeurs sensibles)
    log_info "Export secrets (métadonnées uniquement)..."
    kubectl get secrets -n "$K8S_NAMESPACE" -o json | \
        jq 'del(.items[].data)' > "$temp_dir/secrets_metadata.json" 2>/dev/null || true

    # Créer l'archive
    run_cmd tar -czvf "$output_file" -C "$temp_dir" .

    # Nettoyer
    rm -rf "$temp_dir"

    if [ "$DRY_RUN" = false ] && [ -f "$output_file" ]; then
        local size=$(human_size "$output_file")
        log_success "Ressources K8s exportées : $output_file ($size)"
    fi
}

# =============================================================================
# SAUVEGARDE COMPLÈTE
# =============================================================================

backup_full() {
    local output_file="$BACKUP_DIR/full/full_${TIMESTAMP}.tar.gz"

    log_step "Sauvegarde COMPLÈTE..."
    echo ""

    # Créer un répertoire temporaire
    local temp_dir=$(mktemp -d)

    # Sauvegarder chaque composant
    backup_configs && cp "$BACKUP_DIR/config/config_${TIMESTAMP}.tar.gz" "$temp_dir/" 2>/dev/null || true
    backup_data && cp "$BACKUP_DIR/data/data_${TIMESTAMP}.tar.gz" "$temp_dir/" 2>/dev/null || true
    backup_logs && cp "$BACKUP_DIR/logs/logs_${TIMESTAMP}.tar.gz" "$temp_dir/" 2>/dev/null || true
    backup_k8s && cp "$BACKUP_DIR/k8s/k8s_${TIMESTAMP}.tar.gz" "$temp_dir/" 2>/dev/null || true

    # Créer un manifest
    cat > "$temp_dir/MANIFEST.txt" << EOF
═══════════════════════════════════════════════════════════════════════════════
                         Phoenix Full Backup
═══════════════════════════════════════════════════════════════════════════════

Date de création : $DATE_HUMAN
Timestamp        : $TIMESTAMP
Hostname         : $(hostname)
Utilisateur      : $(whoami)

Contenu :
- config_${TIMESTAMP}.tar.gz  : Fichiers de configuration
- data_${TIMESTAMP}.tar.gz    : Données persistantes
- logs_${TIMESTAMP}.tar.gz    : Journaux
- k8s_${TIMESTAMP}.tar.gz     : Ressources Kubernetes

Restauration :
    ./backup.sh --restore $output_file

Vérification :
    ./backup.sh --verify $output_file

═══════════════════════════════════════════════════════════════════════════════
EOF

    # Créer l'archive finale
    run_cmd tar -czvf "$output_file" -C "$temp_dir" .

    # Nettoyer
    rm -rf "$temp_dir"

    if [ "$DRY_RUN" = false ] && [ -f "$output_file" ]; then
        local size=$(human_size "$output_file")

        # Créer checksum
        if command_exists sha256sum; then
            sha256sum "$output_file" > "${output_file}.sha256"
        elif command_exists shasum; then
            shasum -a 256 "$output_file" > "${output_file}.sha256"
        fi

        echo ""
        log_success "═══════════════════════════════════════════════════════════════════"
        log_success "SAUVEGARDE COMPLÈTE TERMINÉE"
        log_success "Fichier : $output_file"
        log_success "Taille  : $size"
        log_success "═══════════════════════════════════════════════════════════════════"
    fi
}

# =============================================================================
# RESTAURATION
# =============================================================================

restore_backup() {
    local archive_file="$1"

    log_step "Restauration depuis : $archive_file"

    if [ ! -f "$archive_file" ]; then
        log_error "Fichier non trouvé : $archive_file"
        return 1
    fi

    # Vérifier l'intégrité si checksum disponible
    if [ -f "${archive_file}.sha256" ]; then
        log_info "Vérification de l'intégrité..."
        if command_exists sha256sum; then
            if ! sha256sum -c "${archive_file}.sha256" &>/dev/null; then
                log_error "Checksum invalide ! Archive corrompue."
                return 1
            fi
        elif command_exists shasum; then
            if ! shasum -a 256 -c "${archive_file}.sha256" &>/dev/null; then
                log_error "Checksum invalide ! Archive corrompue."
                return 1
            fi
        fi
        log_success "Intégrité vérifiée"
    else
        log_warning "Pas de checksum disponible - impossible de vérifier l'intégrité"
    fi

    # Demander confirmation
    echo ""
    log_warning "ATTENTION : La restauration va écraser les fichiers existants !"
    read -p "Continuer ? (yes/no) : " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "Restauration annulée"
        return 0
    fi

    # Créer un répertoire de restauration
    local restore_dir="$BACKUP_DIR/restore_${TIMESTAMP}"
    run_cmd mkdir -p "$restore_dir"

    # Extraire l'archive
    log_info "Extraction de l'archive..."
    run_cmd tar -xzvf "$archive_file" -C "$restore_dir"

    # Lister le contenu
    log_info "Contenu extrait :"
    ls -la "$restore_dir"

    echo ""
    log_success "Archive extraite dans : $restore_dir"
    log_info "Pour compléter la restauration, copiez les fichiers manuellement"
    log_info "ou appliquez les manifests Kubernetes avec kubectl apply"
}

# =============================================================================
# LISTER LES SAUVEGARDES
# =============================================================================

list_backups() {
    log_step "Sauvegardes disponibles dans $BACKUP_DIR"
    echo ""

    for type in full config data logs k8s; do
        if [ -d "$BACKUP_DIR/$type" ]; then
            local count=$(find "$BACKUP_DIR/$type" -name "*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')
            echo -e "${CYAN}[$type]${NC} ($count fichiers)"

            find "$BACKUP_DIR/$type" -name "*.tar.gz" -exec ls -lh {} \; 2>/dev/null | \
                awk '{print "  " $9 " (" $5 ")"}' | sort -r | head -10
            echo ""
        fi
    done

    # Calculer l'espace total utilisé
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo -e "${YELLOW}Espace total utilisé : $total_size${NC}"
}

# =============================================================================
# NETTOYER LES VIEILLES SAUVEGARDES
# =============================================================================

clean_backups() {
    local days="${1:-$BACKUP_RETENTION_DAYS}"

    log_step "Nettoyage des sauvegardes > $days jours..."

    local count=0

    while IFS= read -r file; do
        if [ -n "$file" ]; then
            log_info "Suppression : $file"
            run_cmd rm -f "$file"
            run_cmd rm -f "${file}.sha256"
            ((count++))
        fi
    done < <(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +"$days" 2>/dev/null)

    if [ $count -eq 0 ]; then
        log_info "Aucune sauvegarde à supprimer"
    else
        log_success "$count fichier(s) supprimé(s)"
    fi
}

# =============================================================================
# VÉRIFIER L'INTÉGRITÉ
# =============================================================================

verify_backup() {
    local archive_file="$1"

    log_step "Vérification de : $archive_file"

    if [ ! -f "$archive_file" ]; then
        log_error "Fichier non trouvé : $archive_file"
        return 1
    fi

    # Test d'intégrité de l'archive
    log_info "Test d'intégrité tar..."
    if run_cmd tar -tzf "$archive_file" &>/dev/null; then
        log_success "Archive tar valide"
    else
        log_error "Archive tar corrompue !"
        return 1
    fi

    # Vérifier le checksum
    if [ -f "${archive_file}.sha256" ]; then
        log_info "Vérification du checksum SHA256..."
        if command_exists sha256sum; then
            if sha256sum -c "${archive_file}.sha256"; then
                log_success "Checksum valide"
            else
                log_error "Checksum invalide !"
                return 1
            fi
        elif command_exists shasum; then
            if shasum -a 256 -c "${archive_file}.sha256"; then
                log_success "Checksum valide"
            else
                log_error "Checksum invalide !"
                return 1
            fi
        fi
    else
        log_warning "Pas de fichier checksum (.sha256)"
    fi

    # Afficher le contenu
    log_info "Contenu de l'archive :"
    tar -tzvf "$archive_file" | head -20

    local file_count=$(tar -tzf "$archive_file" | wc -l | tr -d ' ')
    local size=$(human_size "$archive_file")

    echo ""
    log_success "Archive valide : $file_count fichiers, $size"
}

# =============================================================================
# SYNCHRONISATION OFFSITE
# =============================================================================

sync_offsite() {
    log_step "Synchronisation offsite..."

    if [ -z "$BACKUP_OFFSITE" ]; then
        log_error "Variable BACKUP_OFFSITE non définie"
        log_info "Exemple : BACKUP_OFFSITE='user@server:/backups/phoenix' ./backup.sh --offsite"
        return 1
    fi

    # Détecter l'outil disponible
    local sync_tool=""

    if command_exists rclone; then
        sync_tool="rclone"
    elif command_exists rsync; then
        sync_tool="rsync"
    else
        log_error "Aucun outil de synchronisation trouvé (rclone ou rsync requis)"
        return 1
    fi

    log_info "Utilisation de : $sync_tool"
    log_info "Destination : $BACKUP_OFFSITE"

    case "$sync_tool" in
        rsync)
            run_cmd rsync -avz --progress "$BACKUP_DIR/" "$BACKUP_OFFSITE/"
            ;;
        rclone)
            run_cmd rclone sync "$BACKUP_DIR" "$BACKUP_OFFSITE" --progress
            ;;
    esac

    log_success "Synchronisation terminée"
}

# =============================================================================
# POINT D'ENTRÉE PRINCIPAL
# =============================================================================

main() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           Phoenix Backup Script v1.0.0                           ║${NC}"
    echo -e "${CYAN}║           $(date '+%Y-%m-%d %H:%M:%S')                                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Parser les arguments
    local action=""
    local action_arg=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                action="full"
                shift
                ;;
            --config)
                action="config"
                shift
                ;;
            --data)
                action="data"
                shift
                ;;
            --logs)
                action="logs"
                shift
                ;;
            --k8s)
                action="k8s"
                shift
                ;;
            --restore)
                action="restore"
                action_arg="$2"
                shift 2
                ;;
            --list)
                action="list"
                shift
                ;;
            --clean)
                action="clean"
                action_arg="${2:-$BACKUP_RETENTION_DAYS}"
                shift
                [[ "${1:-}" =~ ^[0-9]+$ ]] && shift
                ;;
            --verify)
                action="verify"
                action_arg="$2"
                shift 2
                ;;
            --offsite)
                action="offsite"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                log_warning "Mode simulation activé (aucune modification)"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Option inconnue : $1"
                echo "Utilisez --help pour l'aide"
                exit 1
                ;;
        esac
    done

    # Action par défaut
    if [ -z "$action" ]; then
        show_help
        exit 0
    fi

    # Initialiser le répertoire de backup
    init_backup_dir

    # Exécuter l'action
    case "$action" in
        full)
            backup_full
            ;;
        config)
            backup_configs
            ;;
        data)
            backup_data
            ;;
        logs)
            backup_logs
            ;;
        k8s)
            backup_k8s
            ;;
        restore)
            restore_backup "$action_arg"
            ;;
        list)
            list_backups
            ;;
        clean)
            clean_backups "$action_arg"
            ;;
        verify)
            verify_backup "$action_arg"
            ;;
        offsite)
            sync_offsite
            ;;
    esac

    echo ""
    log_info "Terminé : $(date '+%Y-%m-%d %H:%M:%S')"
}

# Exécuter
main "$@"
