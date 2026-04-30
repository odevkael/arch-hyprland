#!/usr/bin/env bash
# =============================================================================
#  install.sh — Instalador dos dotfiles
#  Uso: ./install.sh [--help] [--deps-only] [--files-only] [--dry-run]
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_DIR="$REPO_ROOT/dots"
BACKUP_DIR="$HOME/.config/dots-backup/$(date +%Y%m%d_%H%M%S)"

# ── Cores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RST='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RST}  $*"; }
ok()      { echo -e "${GREEN}[OK]${RST}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RST}  $*"; }
error()   { echo -e "${RED}[ERROR]${RST} $*" >&2; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${RST}"; }

# ── Flags ────────────────────────────────────────────────────────────────────
DEPS_ONLY=false
FILES_ONLY=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo -e "${BOLD}Uso:${RST} ./install.sh [opções]"
            echo ""
            echo "Opções:"
            echo "  --deps-only    Instala apenas as dependências"
            echo "  --files-only   Copia apenas os arquivos de config"
            echo "  --dry-run      Mostra o que seria feito sem executar"
            echo "  --help         Mostra esta ajuda"
            exit 0
            ;;
        --deps-only)  DEPS_ONLY=true ;;
        --files-only) FILES_ONLY=true ;;
        --dry-run)    DRY_RUN=true; warn "Modo dry-run ativo — nenhuma alteração será feita." ;;
    esac
done

# ── Verificações iniciais ─────────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
    error "Não execute como root. O script pedirá sudo quando necessário."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    error "Este script é para Arch Linux (pacman não encontrado)."
    exit 1
fi

# ── Dependências ──────────────────────────────────────────────────────────────
# Formato: "pacote:descrição"
PACMAN_DEPS=(
    # Build tools (necessário para AUR)
    "base-devel:Ferramentas de build"
    "fakeroot:Necessário para makepkg/AUR"
    "git:Controle de versão"
    # Apps
    "hyprland:Compositor Wayland"
    "waybar:Barra de status"
    "hyprlock:Lockscreen"
    "hypridle:Idle manager"
    "hyprpicker:Color picker"
    "kitty:Terminal"
    "cava:Visualizador de áudio"
    "fastfetch:System info"
    "nautilus:Gerenciador de arquivos"
    "pamixer:Controle de volume"
    "brightnessctl:Controle de brilho"
    "playerctl:Controle de mídia"
    "grim:Screenshot"
    "slurp:Seleção de área (screenshot)"
    "libnotify:Notificações (notify-send)"
    "networkmanager:Gerenciador de rede"
    "network-manager-applet:Applet de rede"
    "blueman:Gerenciador Bluetooth"
    "pipewire:Servidor de áudio"
    "pipewire-pulse:Compatibilidade PulseAudio"
    "wireplumber:Session manager de áudio"
    "xdg-user-dirs:Diretórios padrão do usuário"
    "polkit-gnome:Agente de autenticação"
    "zsh:Shell"
    "ttf-jetbrains-mono-nerd:Fonte JetBrainsMono Nerd"
)

# Pacotes que só existem no AUR
AUR_DEPS=(
    "swww:Wallpaper daemon"
    "rofi-wayland:Launcher / menu"
    "swaync:Notification center"
    "wlogout:Logout menu"
    "matugen-bin:Gerador de cores Material You"
    "hyprpolkitagent:Agente polkit para Hyprland"
    "oh-my-zsh-git:Framework Zsh"
    "zsh-autosuggestions:Plugin Zsh autosuggestions"
    "zsh-syntax-highlighting:Plugin Zsh syntax highlighting"
)

# ── Funções ───────────────────────────────────────────────────────────────────
detect_aur_helper() {
    for helper in yay paru; do
        if command -v "$helper" &>/dev/null; then
            echo "$helper"
            return
        fi
    done
    echo ""
}

install_aur_helper() {
    warn "Nenhum AUR helper encontrado. Instalando yay..."
    if $DRY_RUN; then
        info "[dry-run] git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si"
        return
    fi
    local tmp
    tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    ok "yay instalado."
}

check_missing_pacman() {
    local missing=()
    for entry in "${PACMAN_DEPS[@]}"; do
        local pkg="${entry%%:*}"
        if ! pacman -Qq "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    echo "${missing[@]:-}"
}

check_missing_aur() {
    local aur_helper="$1"
    local missing=()
    for entry in "${AUR_DEPS[@]}"; do
        local pkg="${entry%%:*}"
        if ! pacman -Qq "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    echo "${missing[@]:-}"
}

step_install_deps() {
    section "1. Instalando dependências"

    # Garantir base-devel e fakeroot antes de tudo (necessário para AUR)
    info "Verificando base-devel e fakeroot..."
    if $DRY_RUN; then
        info "[dry-run] sudo pacman -S --needed --noconfirm base-devel fakeroot git"
    else
        sudo pacman -S --needed --noconfirm base-devel fakeroot git
    fi

    # Pacman
    local missing_pacman
    read -ra missing_pacman <<< "$(check_missing_pacman)"

    if [[ ${#missing_pacman[@]} -gt 0 && -n "${missing_pacman[0]}" ]]; then
        info "Pacotes pacman a instalar: ${missing_pacman[*]}"
        if $DRY_RUN; then
            info "[dry-run] sudo pacman -S --needed --noconfirm ${missing_pacman[*]}"
        else
            sudo pacman -S --needed --noconfirm "${missing_pacman[@]}"
        fi
    else
        ok "Todos os pacotes pacman já estão instalados."
    fi

    # AUR
    local aur_helper
    aur_helper=$(detect_aur_helper)

    if [[ -z "$aur_helper" ]]; then
        install_aur_helper
        aur_helper=$(detect_aur_helper)
    fi

    local missing_aur
    read -ra missing_aur <<< "$(check_missing_aur "$aur_helper")"

    if [[ ${#missing_aur[@]} -gt 0 && -n "${missing_aur[0]}" ]]; then
        info "Pacotes AUR a instalar via $aur_helper: ${missing_aur[*]}"
        if $DRY_RUN; then
            info "[dry-run] $aur_helper -S --needed --noconfirm ${missing_aur[*]}"
        else
            "$aur_helper" -S --needed --noconfirm "${missing_aur[@]}"
        fi
    else
        ok "Todos os pacotes AUR já estão instalados."
    fi

    ok "Dependências concluídas."
}

backup_existing() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        local rel="${target#$HOME/}"
        local dest="$BACKUP_DIR/$rel"
        if $DRY_RUN; then
            info "[dry-run] backup: $target → $dest"
        else
            mkdir -p "$(dirname "$dest")"
            mv "$target" "$dest"
        fi
    fi
}

copy_config() {
    local src="$1"   # caminho dentro de dots/
    local dst="$2"   # destino em $HOME

    backup_existing "$dst"

    if $DRY_RUN; then
        info "[dry-run] cp -r $src → $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
    fi
}

step_copy_files() {
    section "2. Copiando arquivos de configuração"

    if [[ ! -d "$DOTS_DIR" ]]; then
        error "Diretório dots/ não encontrado em $DOTS_DIR"
        exit 1
    fi

    if ! $DRY_RUN; then
        mkdir -p "$BACKUP_DIR"
        info "Backups serão salvos em: $BACKUP_DIR"
    fi

    # Copia cada subdiretório de dots/.config/
    for config_dir in "$DOTS_DIR/.config"/*/; do
        local name
        name=$(basename "$config_dir")
        copy_config "$config_dir" "$HOME/.config/$name"
        ok "  .config/$name"
    done

    # .zshrc
    if [[ -f "$DOTS_DIR/.zshrc" ]]; then
        copy_config "$DOTS_DIR/.zshrc" "$HOME/.zshrc"
        ok "  .zshrc"
    fi

    # Wallpapers
    if [[ -d "$DOTS_DIR/wallpapers" ]]; then
        mkdir -p "$HOME/Pictures"
        copy_config "$DOTS_DIR/wallpapers" "$HOME/Pictures/wallpapers"
        ok "  wallpapers → ~/Pictures/wallpapers"
    fi

    ok "Arquivos copiados."
}

step_post_install() {
    section "3. Configurações pós-instalação"

    # Diretórios do usuário
    if ! $DRY_RUN; then
        xdg-user-dirs-update
    fi
    ok "xdg-user-dirs atualizado."

    # Zsh como shell padrão
    if [[ "$SHELL" != "$(command -v zsh)" ]]; then
        info "Alterando shell padrão para zsh..."
        if $DRY_RUN; then
            info "[dry-run] chsh -s $(command -v zsh)"
        else
            chsh -s "$(command -v zsh)"
        fi
        ok "Shell alterado para zsh (efetivo no próximo login)."
    else
        ok "Zsh já é o shell padrão."
    fi

    # Habilitar serviços
    local services=("NetworkManager" "bluetooth")
    for svc in "${services[@]}"; do
        if systemctl list-unit-files "$svc.service" &>/dev/null; then
            if $DRY_RUN; then
                info "[dry-run] sudo systemctl enable --now $svc"
            else
                sudo systemctl enable --now "$svc" 2>/dev/null || true
            fi
            ok "Serviço $svc habilitado."
        fi
    done

    # Permissões nos scripts
    if ! $DRY_RUN; then
        find "$HOME/.config/hypr/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    fi
    ok "Permissões dos scripts configuradas."

    # Symlink do wallpaper inicial (primeiro da pasta)
    if ! $DRY_RUN; then
        local first_wall
        first_wall=$(find "$HOME/Pictures/wallpapers" -maxdepth 1 \
            \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) \
            | sort | head -n1)
        if [[ -n "$first_wall" ]]; then
            ln -sf "$first_wall" "$HOME/.config/hypr/current_wallpaper"
            ok "Wallpaper inicial definido: $(basename "$first_wall")"
        fi
    fi
}

print_summary() {
    section "Instalação concluída"
    echo -e "${GREEN}${BOLD}"
    echo "  ✓ Dependências instaladas"
    echo "  ✓ Configs copiados para ~/.config/"
    echo "  ✓ Wallpapers em ~/Pictures/wallpapers/"
    if [[ -d "$BACKUP_DIR" ]] && ! $DRY_RUN; then
        echo "  ✓ Backups salvos em $BACKUP_DIR"
    fi
    echo -e "${RST}"
    echo -e "${CYAN}Próximos passos:${RST}"
    echo "  1. Faça logout e entre no Hyprland"
    echo "  2. Use ${BOLD}Super+W${RST} para escolher um wallpaper e gerar o tema de cores"
    echo "  3. Edite ${BOLD}~/.config/hypr/custom/${RST} para suas customizações pessoais"
    echo "  4. Edite ${BOLD}~/.config/hypr/hyprland.conf${RST} para ajustar o monitor"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ██████╗  ██████╗ ████████╗███████╗"
echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝"
echo "  ██║  ██║██║   ██║   ██║   ███████╗"
echo "  ██║  ██║██║   ██║   ██║   ╚════██║"
echo "  ██████╔╝╚██████╔╝   ██║   ███████║"
echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝"
echo -e "  Hyprland Dotfiles Installer${RST}"
echo ""

if $DEPS_ONLY; then
    step_install_deps
elif $FILES_ONLY; then
    step_copy_files
    step_post_install
    print_summary
else
    step_install_deps
    step_copy_files
    step_post_install
    print_summary
fi
