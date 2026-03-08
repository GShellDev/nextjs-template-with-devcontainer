#!/usr/bin/env bash
set -Eeuo pipefail

LOG_LEVEL="normal"   # silent | normal | verbose

log() {
    local level="$1"
    shift || true

    case "$LOG_LEVEL" in
        silent)
            [[ "$level" == "error" ]] && printf '%s\n' "$*" >&2
            ;;
        normal)
            [[ "$level" == "info" || "$level" == "error" ]] && printf '%s\n' "$*"
            ;;
        verbose)
            printf '[%s] %s\n' "$level" "$*"
            ;;
    esac
}

die() {
    log error "$*"
    exit 1
}

run_as_root_if_needed() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

detect_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        die "Nenhum gerenciador de pacotes suportado foi encontrado."
    fi
}

install_zsh() {
    if command -v zsh >/dev/null 2>&1; then
        log info "zsh já está instalado em: $(command -v zsh)"
        return 0
    fi

    local pm
    pm="$(detect_pkg_manager)"

    case "$pm" in
        apt)
            log info "Instalando zsh via apt..."
            run_as_root_if_needed apt-get update
            run_as_root_if_needed apt-get install -y zsh
            ;;
        apk)
            log info "Instalando zsh via apk..."
            run_as_root_if_needed apk add --no-cache zsh
            ;;
        dnf)
            log info "Instalando zsh via dnf..."
            run_as_root_if_needed dnf install -y zsh
            ;;
        yum)
            log info "Instalando zsh via yum..."
            run_as_root_if_needed yum install -y zsh
            ;;
        pacman)
            log info "Instalando zsh via pacman..."
            run_as_root_if_needed pacman -Sy --noconfirm zsh
            ;;
        *)
            die "Gerenciador de pacotes não suportado: $pm"
            ;;
    esac

    command -v zsh >/dev/null 2>&1 || die "Falha ao instalar zsh."
    log info "zsh instalado com sucesso em: $(command -v zsh)"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --silent)
                LOG_LEVEL="silent"
                shift
                ;;
            --verbose)
                LOG_LEVEL="verbose"
                shift
                ;;
            --help|-h)
                cat <<EOF
Uso:
  $0 [--silent|--verbose]
EOF
                exit 0
                ;;
            *)
                die "Argumento inválido: $1"
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    install_zsh
}

main "$@"