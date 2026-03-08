#!/usr/bin/env bash
set -Eeuo pipefail

THEME_NAME="kali-linux"
THEME_FILE="${THEME_NAME}.zsh-theme"
THEME_URL="https://gist.githubusercontent.com/Frotas/964a68b39310c4205596aef40b2cdc8f/raw/kali-linux.zsh-theme"

LOG_LEVEL="normal"   # silent | normal | verbose
ALL_USERS=false
CHANGE_SHELL=false
TARGET_USER=""
TARGET_OHMYZSH=""
SYSTEM_SHARED_DIRS=(
  "/usr/share/oh-my-zsh"
  "/usr/local/share/oh-my-zsh"
  "/opt/oh-my-zsh"
)

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

user_shell() {
    local user="$1"
    getent passwd "$user" | cut -d: -f7
}

zsh_path() {
    command -v zsh
}

download_theme_to() {
    local destination="$1"
    local tmp_file
    tmp_file="$(mktemp)"

    log info "Baixando tema..."

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$THEME_URL" -o "$tmp_file"
    else
        wget -qO "$tmp_file" "$THEME_URL"
    fi

    if [[ -f "$destination" ]]; then
        local new_hash old_hash

        new_hash=$(sha256sum "$tmp_file" | awk '{print $1}')
        old_hash=$(sha256sum "$destination" | awk '{print $1}')

        if [[ "$new_hash" == "$old_hash" ]]; then
            log info "Tema já está atualizado."
            rm -f "$tmp_file"
            return
        else
            log info "Atualizando tema..."
        fi
    else
        log info "Instalando tema..."
    fi

    run_as_root_if_needed mkdir -p "$(dirname "$destination")"
    run_as_root_if_needed install -m 0644 "$tmp_file" "$destination"

    rm -f "$tmp_file"
}

discover_ohmyzsh_for_user() {
    local user="$1"
    local home
    home="$(user_home "$user")"
    [[ -n "$home" ]] || return 1

    local candidates=(
        "$home/.oh-my-zsh"
        "${ZSH:-}"
    )

    local path
    for path in "${candidates[@]}"; do
        [[ -n "$path" && -d "$path/custom/themes" ]] && {
            printf '%s\n' "$path"
            return 0
        }
    done

    return 1
}

discover_shared_ohmyzsh() {
    local path
    for path in "${SYSTEM_SHARED_DIRS[@]}"; do
        [[ -d "$path/custom/themes" ]] && printf '%s\n' "$path"
    done
}

discover_all_user_ohmyzsh() {
    local entry user path
    getent passwd | while IFS=: read -r user _ uid _ _ _ shell; do
        [[ "$uid" -ge 1000 || "$user" == "root" ]] || continue
        path="$(discover_ohmyzsh_for_user "$user" 2>/dev/null || true)"
        [[ -n "$path" ]] && printf '%s:%s\n' "$user" "$path"
    done
}

set_theme_for_user() {
    local user="$1"
    local home zshrc
    home="$(user_home "$user")"
    [[ -n "$home" ]] || die "Não foi possível determinar HOME do usuário '$user'."

    zshrc="$home/.zshrc"

    if [[ ! -f "$zshrc" ]]; then
        log info "Criando $zshrc para $user"
        run_as_root_if_needed touch "$zshrc"
        run_as_root_if_needed chown "$user:$user" "$zshrc"
    fi

    if grep -q '^ZSH_THEME=' "$zshrc"; then
        run_as_root_if_needed sed -i "s|^ZSH_THEME=.*|ZSH_THEME=\"${THEME_NAME}\"|" "$zshrc"
    else
        printf '\nZSH_THEME="%s"\n' "$THEME_NAME" | run_as_root_if_needed tee -a "$zshrc" >/dev/null
    fi

    log info "Tema configurado em $zshrc para o usuário $user"
}

set_default_shell_for_user() {
    local user="$1"
    local current_shell desired_shell
    desired_shell="$(zsh_path)"
    current_shell="$(user_shell "$user")"

    [[ -n "$desired_shell" ]] || die "zsh não está instalado."

    if [[ "$current_shell" != "$desired_shell" ]]; then
        log info "Alterando shell padrão de $user para $desired_shell"
        run_as_root_if_needed chsh -s "$desired_shell" "$user"
    else
        log info "Shell padrão de $user já é zsh"
    fi
}

install_for_single_user() {
    local user="$1"
    local ohmyzsh_root target

    if [[ -n "$TARGET_OHMYZSH" ]]; then
        ohmyzsh_root="$TARGET_OHMYZSH"
    else
        ohmyzsh_root="$(discover_ohmyzsh_for_user "$user" || true)"
    fi

    [[ -n "$ohmyzsh_root" ]] || die "Oh My Zsh não encontrado para o usuário '$user'. Use --target-ohmyzsh para informar o caminho."

    target="$ohmyzsh_root/custom/themes/$THEME_FILE"
    download_theme_to "$target"
    log info "Tema instalado em $target"

    set_theme_for_user "$user"

    if $CHANGE_SHELL; then
        set_default_shell_for_user "$user"
    fi
}

install_for_all_users() {
    local shared_found=false
    local shared_path

    while IFS= read -r shared_path; do
        [[ -n "$shared_path" ]] || continue
        shared_found=true
        download_theme_to "$shared_path/custom/themes/$THEME_FILE"
        log info "Tema instalado em diretório compartilhado: $shared_path/custom/themes/$THEME_FILE"
    done < <(discover_shared_ohmyzsh)

    if ! $shared_found; then
        log info "Nenhum diretório compartilhado de Oh My Zsh encontrado."
    fi

    local line user ohmyzsh_root
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        user="${line%%:*}"
        ohmyzsh_root="${line#*:}"

        download_theme_to "$ohmyzsh_root/custom/themes/$THEME_FILE"
        log info "Tema instalado para $user em $ohmyzsh_root/custom/themes/$THEME_FILE"

        set_theme_for_user "$user"

        if $CHANGE_SHELL; then
            set_default_shell_for_user "$user"
        fi
    done < <(discover_all_user_ohmyzsh)
}

usage() {
    cat <<EOF
Uso:
  $0 [opções]

Opções:
  --silent                 Saída mínima
  --verbose                Saída detalhada
  --all-users              Instala para todos os usuários encontrados
  --user <nome>            Usuário alvo (padrão: usuário atual)
  --change-shell           Altera shell padrão para zsh
  --target-ohmyzsh <path>  Caminho explícito do diretório raiz do Oh My Zsh
                           Ex.: /home/zeus/.oh-my-zsh
  --help                   Mostra esta ajuda

Exemplos:
  $0
  $0 --user zeus
  $0 --user zeus --change-shell
  $0 --all-users --change-shell
  $0 --user zeus --target-ohmyzsh /home/zeus/.oh-my-zsh
EOF
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
            --all-users)
                ALL_USERS=true
                shift
                ;;
            --user)
                [[ $# -ge 2 ]] || die "Faltou valor para --user"
                TARGET_USER="$2"
                shift 2
                ;;
            --change-shell)
                CHANGE_SHELL=true
                shift
                ;;
            --target-ohmyzsh)
                [[ $# -ge 2 ]] || die "Faltou valor para --target-ohmyzsh"
                TARGET_OHMYZSH="$2"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                die "Argumento inválido: $1"
                ;;
        esac
    done
}

main() {
    require_cmd getent
    require_cmd sed

    parse_args "$@"

    if [[ -z "$TARGET_USER" ]]; then
        TARGET_USER="$(id -un)"
    fi

    if $ALL_USERS && [[ -n "$TARGET_OHMYZSH" ]]; then
        die "--target-ohmyzsh não faz sentido junto com --all-users"
    fi

    if $ALL_USERS; then
        install_for_all_users
    else
        install_for_single_user "$TARGET_USER"
    fi

    log info "Concluído."
}

main "$@"