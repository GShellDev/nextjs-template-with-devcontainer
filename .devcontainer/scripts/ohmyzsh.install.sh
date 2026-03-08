#!/usr/bin/env bash
set -Eeuo pipefail

LOG_LEVEL="normal"   # silent | normal | verbose
TARGET_USER="${SUDO_USER:-${USER:-}}"
OHMYZSH_REPO_URL="https://github.com/ohmyzsh/ohmyzsh.git"
OHMYZSH_DIR=""
ALL_USERS=false

SHARED_BASE_DIR="/usr/local/share/zsh"
SHARED_OHMYZSH_DIR="$SHARED_BASE_DIR/oh-my-zsh"
SHARED_ZSHRC_FILE="$SHARED_BASE_DIR/zshrc.shared"

DEFAULT_THEME="robbyrussell"
DEFAULT_PLUGINS="git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE_DEFAULT="$SCRIPT_DIR/../templates/zshrc.shared.tpl"
TEMPLATE_FILE=""

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

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Comando obrigatório não encontrado: $1"
}

run_as_root_if_needed() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

user_home() {
    local user="$1"
    getent passwd "$user" | cut -d: -f6
}

ensure_user_exists() {
    id "$1" >/dev/null 2>&1 || die "Usuário não encontrado: $1"
}

list_target_users() {
    if ! $ALL_USERS; then
        printf '%s\n' "$TARGET_USER"
        return 0
    fi

    getent passwd | while IFS=: read -r user _ uid _ _ home _; do
        [[ -n "$user" ]] || continue

        if [[ "$user" == "root" ]]; then
            printf '%s\n' "$user"
            continue
        fi

        [[ "$uid" -ge 1000 ]] || continue
        [[ -d "$home" ]] || continue

        printf '%s\n' "$user"
    done
}

target_install_dir() {
    if $ALL_USERS; then
        printf '%s\n' "${OHMYZSH_DIR:-$SHARED_OHMYZSH_DIR}"
    else
        local home
        home="$(user_home "$TARGET_USER")"
        [[ -n "$home" ]] || die "Não foi possível determinar o HOME de '$TARGET_USER'."
        printf '%s\n' "${OHMYZSH_DIR:-$home/.oh-my-zsh}"
    fi
}

clone_or_update_oh_my_zsh() {
    local target="$1"

    if [[ -d "$target/.git" ]]; then
        log info "Oh My Zsh já existe em $target; atualizando..."
        run_as_root_if_needed git -C "$target" pull --ff-only
        return 0
    fi

    if [[ -e "$target" && ! -d "$target/.git" ]]; then
        die "O destino '$target' já existe, mas não é um repositório do Oh My Zsh."
    fi

    log info "Clonando Oh My Zsh em $target"
    run_as_root_if_needed mkdir -p "$(dirname "$target")"
    run_as_root_if_needed git clone --depth=1 "$OHMYZSH_REPO_URL" "$target"
}

install_shared_zshrc_template() {
    local install_dir="$1"
    local template_file="$2"
    local target_file="$3"
    local tmp_file

    [[ -f "$template_file" ]] || die "Template não encontrado: $template_file"

    tmp_file="$(mktemp)"

    sed \
        -e "s|__ZSH_DIR__|$install_dir|g" \
        -e "s|__ZSH_THEME__|$DEFAULT_THEME|g" \
        -e "s|__ZSH_PLUGINS__|$DEFAULT_PLUGINS|g" \
        "$template_file" > "$tmp_file"

    run_as_root_if_needed mkdir -p "$(dirname "$target_file")"
    run_as_root_if_needed install -m 0644 "$tmp_file" "$target_file"
    rm -f "$tmp_file"

    log info "Arquivo compartilhado instalado em $target_file"
}

write_single_user_zshrc() {
    local user="$1"
    local zshrc="$2"
    local install_dir="$3"

    log info "Criando $zshrc para $user"
    run_as_root_if_needed tee "$zshrc" >/dev/null <<EOF
# Configuração local do Oh My Zsh
# Gerenciado por install-oh-my-zsh.sh

export ZSH="$install_dir"

ZSH_THEME="$DEFAULT_THEME"
plugins=($DEFAULT_PLUGINS)

source "\$ZSH/oh-my-zsh.sh"

[[ -f "\$HOME/.zshrc.local" ]] && source "\$HOME/.zshrc.local"
EOF

    run_as_root_if_needed chown "$user:$user" "$zshrc"
}

upsert_user_zshrc_shared_source() {
    local user="$1"
    local zshrc="$2"
    local shared_file="$3"

    local begin_marker="# >>> shared zsh bootstrap >>>"
    local end_marker="# <<< shared zsh bootstrap <<<"
    local new_block
    local tmp_file

    new_block="$(cat <<EOF
$begin_marker
source "$shared_file"
$end_marker
EOF
)"

    if [[ ! -f "$zshrc" ]]; then
        log info "Criando $zshrc para $user"
        run_as_root_if_needed tee "$zshrc" >/dev/null <<< "$new_block"
        run_as_root_if_needed chown "$user:$user" "$zshrc"
        return 0
    fi

    tmp_file="$(mktemp)"

    if grep -qF "$begin_marker" "$zshrc"; then
        awk -v begin="$begin_marker" -v end="$end_marker" -v block="$new_block" '
            BEGIN {
                split(block, lines, "\n")
            }
            $0 == begin {
                for (i = 1; i <= length(lines); i++) print lines[i]
                in_block = 1
                next
            }
            $0 == end {
                in_block = 0
                next
            }
            !in_block { print }
        ' "$zshrc" > "$tmp_file"
        run_as_root_if_needed install -m 0644 "$tmp_file" "$zshrc"
    else
        cp "$zshrc" "$tmp_file"
        printf '\n%s\n' "$new_block" >> "$tmp_file"
        run_as_root_if_needed install -m 0644 "$tmp_file" "$zshrc"
    fi

    rm -f "$tmp_file"
    run_as_root_if_needed chown "$user:$user" "$zshrc"
    log info ".zshrc ajustado para usar config compartilhada: $user"
}

ensure_zshrc_for_user() {
    local user="$1"
    local install_dir="$2"
    local home zshrc

    home="$(user_home "$user")"
    [[ -n "$home" ]] || {
        log error "Não foi possível determinar o HOME de '$user'; ignorando."
        return 1
    }

    zshrc="$home/.zshrc"

    if $ALL_USERS; then
        upsert_user_zshrc_shared_source "$user" "$zshrc" "$SHARED_ZSHRC_FILE"
    else
        if [[ ! -f "$zshrc" ]]; then
            write_single_user_zshrc "$user" "$zshrc" "$install_dir"
            return 0
        fi

        if grep -q '^export ZSH=' "$zshrc"; then
            run_as_root_if_needed sed -i "s|^export ZSH=.*|export ZSH=\"$install_dir\"|" "$zshrc"
        else
            printf '\nexport ZSH="%s"\n' "$install_dir" | run_as_root_if_needed tee -a "$zshrc" >/dev/null
        fi

        if grep -q '^ZSH_THEME=' "$zshrc"; then
            run_as_root_if_needed sed -i "s|^ZSH_THEME=.*|ZSH_THEME=\"$DEFAULT_THEME\"|" "$zshrc"
        else
            printf 'ZSH_THEME="%s"\n' "$DEFAULT_THEME" | run_as_root_if_needed tee -a "$zshrc" >/dev/null
        fi

        if grep -q '^plugins=' "$zshrc"; then
            run_as_root_if_needed sed -i "s|^plugins=.*|plugins=($DEFAULT_PLUGINS)|" "$zshrc"
        else
            printf 'plugins=(%s)\n' "$DEFAULT_PLUGINS" | run_as_root_if_needed tee -a "$zshrc" >/dev/null
        fi

        if ! grep -q '^source "\$ZSH/oh-my-zsh.sh"' "$zshrc" && ! grep -q '^source \$ZSH/oh-my-zsh.sh' "$zshrc"; then
            printf 'source "$ZSH/oh-my-zsh.sh"\n' | run_as_root_if_needed tee -a "$zshrc" >/dev/null
        fi

        if ! grep -q '^\[\[ -f "\$HOME/.zshrc.local" \]\] && source "\$HOME/.zshrc.local"' "$zshrc"; then
            printf '[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"\n' | run_as_root_if_needed tee -a "$zshrc" >/dev/null
        fi

        run_as_root_if_needed chown "$user:$user" "$zshrc"
        log info ".zshrc ajustado para o usuário: $user"
    fi
}

fix_ownership_single_user() {
    local target="$1"
    local home
    home="$(user_home "$TARGET_USER")"
    [[ -n "$home" ]] || return 0

    if ! $ALL_USERS && [[ "$target" == "$home/.oh-my-zsh" ]]; then
        run_as_root_if_needed chown -R "$TARGET_USER:$TARGET_USER" "$target"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                [[ $# -ge 2 ]] || die "Faltou valor para --user"
                TARGET_USER="$2"
                shift 2
                ;;
            --dir)
                [[ $# -ge 2 ]] || die "Faltou valor para --dir"
                OHMYZSH_DIR="$2"
                shift 2
                ;;
            --all-users)
                ALL_USERS=true
                shift
                ;;
            --theme)
                [[ $# -ge 2 ]] || die "Faltou valor para --theme"
                DEFAULT_THEME="$2"
                shift 2
                ;;
            --plugins)
                [[ $# -ge 2 ]] || die "Faltou valor para --plugins"
                DEFAULT_PLUGINS="$2"
                shift 2
                ;;
            --template)
                [[ $# -ge 2 ]] || die "Faltou valor para --template"
                TEMPLATE_FILE="$2"
                shift 2
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

Opções:
  --user <nome>       Usuário alvo
  --dir <path>        Diretório de instalação do Oh My Zsh
  --all-users         Instala em pasta compartilhada e configura todos os usuários
  --theme <nome>      Tema padrão (padrão: robbyrussell)
  --plugins "<...>"   Plugins padrão (padrão: git)
  --template <path>   Template do zshrc compartilhado
  --silent
  --verbose

Comportamento:
  Sem --all-users:
    - instala para um único usuário
    - padrão: ~/.oh-my-zsh
    - cria/ajusta ~/.zshrc com config local

  Com --all-users:
    - instala em pasta compartilhada
    - padrão: /usr/local/share/zsh/oh-my-zsh
    - copia um template para /usr/local/share/zsh/zshrc.shared
    - ajusta ~/.zshrc dos usuários para dar source nesse arquivo
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

    require_cmd git
    require_cmd getent
    command -v zsh >/dev/null 2>&1 || die "zsh não está instalado. Instale o zsh antes de instalar o Oh My Zsh."

    if [[ -z "$TEMPLATE_FILE" ]]; then
        TEMPLATE_FILE="$TEMPLATE_FILE_DEFAULT"
    fi

    if ! $ALL_USERS; then
        [[ -n "$TARGET_USER" ]] || die "Não foi possível determinar o usuário alvo. Use --user."
        ensure_user_exists "$TARGET_USER"
    fi

    local install_dir
    install_dir="$(target_install_dir)"

    clone_or_update_oh_my_zsh "$install_dir"
    fix_ownership_single_user "$install_dir"

    if $ALL_USERS; then
        install_shared_zshrc_template "$install_dir" "$TEMPLATE_FILE" "$SHARED_ZSHRC_FILE"
    fi

    local user
    while IFS= read -r user; do
        [[ -n "$user" ]] || continue
        ensure_zshrc_for_user "$user" "$install_dir"
    done < <(list_target_users)

    log info "Oh My Zsh instalado/configurado com sucesso em: $install_dir"
}

main "$@"