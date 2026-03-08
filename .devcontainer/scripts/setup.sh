#!/usr/bin/env bash
set -Eeuo pipefail

LOG_LEVEL="normal"   # silent | normal | verbose

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_ZSH_SCRIPT="$SCRIPT_DIR/zsh.install.sh"
INSTALL_OHMYZSH_SCRIPT="$SCRIPT_DIR/ohmyzsh.install.sh"
INSTALL_THEME_SCRIPT="$SCRIPT_DIR/kali-theme.install.sh"

TARGET_USER="${SUDO_USER:-${USER:-}}"
ALL_USERS=false
CHANGE_SHELL=false
INSTALL_THEME=false
THEME_NAME=""
PLUGINS=""
OHMYZSH_DIR=""
TEMPLATE_FILE=""
FORCE_ENV=""
SKIP_ZSH=false
SKIP_OHMYZSH=false
SKIP_SHELL=false
SKIP_THEME=false

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

require_file() {
    [[ -f "$1" ]] || die "Script não encontrado: $1"
}

detect_environment() {
    if [[ -n "${REMOTE_CONTAINERS:-}" || -n "${CODESPACES:-}" || -f "/.dockerenv" ]]; then
        printf '%s\n' "container"
        return 0
    fi

    if grep -qi microsoft /proc/version 2>/dev/null; then
        printf '%s\n' "wsl"
        return 0
    fi

    printf '%s\n' "host"
}

run_script() {
    local script="$1"
    shift
    require_file "$script"

    log info "Executando: $script $*"

    case "$LOG_LEVEL" in
        silent)
            bash "$script" --silent "$@"
            ;;
        verbose)
            bash "$script" --verbose "$@"
            ;;
        *)
            bash "$script" "$@"
            ;;
    esac
}

resolve_target_user() {
    if [[ -z "${TARGET_USER:-}" ]]; then
        TARGET_USER="$(id -un)"
    fi

    if $ALL_USERS; then
        return 0
    fi

    id "$TARGET_USER" >/dev/null 2>&1 || die "Usuário alvo inválido: $TARGET_USER"
}

build_ohmyzsh_args() {
    local -n _out_ref=$1
    _out_ref=()

    if $ALL_USERS; then
        _out_ref+=(--all-users)
    else
        _out_ref+=(--user "$TARGET_USER")
    fi

    [[ -n "$OHMYZSH_DIR" ]] && _out_ref+=(--dir "$OHMYZSH_DIR")
    [[ -n "$THEME_NAME" ]] && _out_ref+=(--theme "$THEME_NAME")
    [[ -n "$PLUGINS" ]] && _out_ref+=(--plugins "$PLUGINS")
    [[ -n "$TEMPLATE_FILE" ]] && _out_ref+=(--template "$TEMPLATE_FILE")

    return 0
}

build_shell_args() {
    local -n _out_ref=$1
    _out_ref=()

    if $ALL_USERS; then
        return 0
    fi

    _out_ref+=(--user "$TARGET_USER" --change-shell)

    [[ -n "$OHMYZSH_DIR" ]] && _out_ref+=(--dir "$OHMYZSH_DIR")
    return 0
}

build_theme_args() {
    local -n _out_ref=$1
    _out_ref=()

    if $ALL_USERS; then
        _out_ref+=(--all-users)
    else
        _out_ref+=(--user "$TARGET_USER")
    fi

    return 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                [[ $# -ge 2 ]] || die "Faltou valor para --user"
                TARGET_USER="$2"
                shift 2
                ;;
            --all-users)
                ALL_USERS=true
                shift
                ;;
            --change-shell)
                CHANGE_SHELL=true
                shift
                ;;
            --install-theme)
                INSTALL_THEME=true
                shift
                ;;
            --theme)
                [[ $# -ge 2 ]] || die "Faltou valor para --theme"
                THEME_NAME="$2"
                shift 2
                ;;
            --plugins)
                [[ $# -ge 2 ]] || die "Faltou valor para --plugins"
                PLUGINS="$2"
                shift 2
                ;;
            --dir)
                [[ $# -ge 2 ]] || die "Faltou valor para --dir"
                OHMYZSH_DIR="$2"
                shift 2
                ;;
            --template)
                [[ $# -ge 2 ]] || die "Faltou valor para --template"
                TEMPLATE_FILE="$2"
                shift 2
                ;;
            --env)
                [[ $# -ge 2 ]] || die "Faltou valor para --env"
                FORCE_ENV="$2"
                shift 2
                ;;
            --skip-zsh)
                SKIP_ZSH=true
                shift
                ;;
            --skip-oh-my-zsh)
                SKIP_OHMYZSH=true
                shift
                ;;
            --skip-shell)
                SKIP_SHELL=true
                shift
                ;;
            --skip-theme)
                SKIP_THEME=true
                shift
                ;;
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
  $0 [opções]

Opções principais:
  --user <nome>         Usuário alvo
  --all-users           Instalação compartilhada / todos os usuários
  --change-shell        Troca shell padrão para zsh
  --install-theme       Executa também o script de tema
  --theme <nome>        Tema padrão do Oh My Zsh
  --plugins "<lista>"   Plugins padrão
  --dir <path>          Diretório do Oh My Zsh
  --template <path>     Template do zshrc compartilhado
  --env <tipo>          Força ambiente: container | wsl | host

Pular etapas:
  --skip-zsh
  --skip-oh-my-zsh
  --skip-shell
  --skip-theme

Logs:
  --silent
  --verbose
EOF
                exit 0
                ;;
            *)
                die "Argumento inválido: $1"
                ;;
        esac
    done
}

apply_default_policy() {
    local env_type="$1"

    case "$env_type" in
        container)
            if $ALL_USERS; then
                log info "Ambiente container detectado, mas --all-users foi solicitado explicitamente."
            else
                log info "Ambiente container detectado: usando instalação por usuário."
            fi
            ;;
        wsl|host)
            log info "Ambiente $env_type detectado."
            ;;
        *)
            die "Ambiente não suportado: $env_type"
            ;;
    esac

    if [[ "$(id -u)" -eq 0 ]] && ! $ALL_USERS && [[ -z "${TARGET_USER:-}" ]]; then
        die "Executando como root sem --all-users requer --user <nome>."
    fi
}

main() {
    parse_args "$@"

    local env_type
    if [[ -n "$FORCE_ENV" ]]; then
        env_type="$FORCE_ENV"
    else
        env_type="$(detect_environment)"
    fi

    apply_default_policy "$env_type"
    resolve_target_user

    local ohmyzsh_args=()
    local shell_args=()
    local theme_args=()

    build_ohmyzsh_args ohmyzsh_args
    build_shell_args shell_args
    build_theme_args theme_args

    if ! $SKIP_ZSH; then
        log info "Etapa 1/4: instalando zsh..."
        run_script "$INSTALL_ZSH_SCRIPT"
    else
        log info "Etapa 1/4: instalação do zsh ignorada."
    fi

    if ! $SKIP_OHMYZSH; then
        log info "Etapa 2/4: instalando/configurando Oh My Zsh..."
        run_script "$INSTALL_OHMYZSH_SCRIPT" "${ohmyzsh_args[@]}"
    else
        log info "Etapa 2/4: instalação do Oh My Zsh ignorada."
    fi

    if $CHANGE_SHELL && ! $SKIP_SHELL; then
        if $ALL_USERS; then
            log info "Etapa 3/4: mudança de shell ignorada aqui; trate isso com uma rotina específica para todos os usuários, se desejar."
        else
            log info "Etapa 3/4: ajustando shell padrão via ohmyzsh.install.sh..."
            run_script "$INSTALL_OHMYZSH_SCRIPT" "${shell_args[@]}"
        fi
    else
        log info "Etapa 3/4: configuração de shell não solicitada."
    fi

    if $INSTALL_THEME && ! $SKIP_THEME; then
        if [[ -f "$INSTALL_THEME_SCRIPT" ]]; then
            log info "Etapa 4/4: instalando tema..."
            run_script "$INSTALL_THEME_SCRIPT" "${theme_args[@]}"
        else
            log info "Etapa 4/4: script de tema não encontrado; etapa ignorada."
        fi
    else
        log info "Etapa 4/4: instalação de tema não solicitada."
    fi

    log info "Setup concluído com sucesso."
}

main "$@"