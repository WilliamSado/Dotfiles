#!/usr/bin/env bash
set -Eeuo pipefail

# Bootstrap this Hyprland desktop on an already installed Arch Linux system.
# Run as a regular user with sudo access, not as root.

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly BACKUP_DIR="$CONFIG_HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

WITH_AUR=1
WITH_BLUETOOTH=1

usage() {
    cat <<'EOF'
Usage: ./setup.sh [options]

Options:
  --no-aur         Do not install google-chrome from the AUR
  --no-bluetooth   Do not enable the Bluetooth service
  -h, --help       Show this help

This script expects a bootable Arch Linux installation, a working network
connection, and a regular user with sudo access.
EOF
}

log() {
    printf '\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

while (($#)); do
    case "$1" in
        --no-aur) WITH_AUR=0 ;;
        --no-bluetooth) WITH_BLUETOOTH=0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1 (use --help)" ;;
    esac
    shift
done

[[ -r /etc/arch-release ]] || die "This script only supports Arch Linux."
((EUID != 0)) || die "Run this script as a regular user, not root."
command -v sudo >/dev/null || die "sudo is required."
command -v pacman >/dev/null || die "pacman was not found."

official_packages=(
    alacritty
    base-devel
    bluez
    bluez-utils
    brightnessctl
    curl
    dolphin
    fcitx5
    fcitx5-chinese-addons
    fcitx5-configtool
    fcitx5-gtk
    fcitx5-qt
    git
    grim
    hyprland
    hyprlock
    hyprpaper
    jq
    networkmanager
    noto-fonts
    noto-fonts-cjk
    pipewire
    pipewire-alsa
    pipewire-pulse
    polkit-kde-agent
    quickshell
    slurp
    tofi
    ttf-jetbrains-mono-nerd
    wireplumber
    wl-clipboard
    xdg-desktop-portal-hyprland
)

log "Refreshing package databases and installing desktop dependencies"
sudo pacman -Syu --needed "${official_packages[@]}"

install_aur_package() {
    local package=$1 build_root

    if pacman -Q "$package" &>/dev/null; then
        log "$package is already installed"
        return
    fi

    build_root="$(mktemp -d)"
    trap 'rm -rf -- "$build_root"' RETURN
    log "Cloning AUR package $package (review its PKGBUILD before confirming)"
    git clone "https://aur.archlinux.org/${package}.git" "$build_root/$package"
    (
        cd "$build_root/$package"
        less PKGBUILD
        makepkg -si
    )
    rm -rf -- "$build_root"
    trap - RETURN
}

if ((WITH_AUR)); then
    command -v less >/dev/null || sudo pacman -S --needed less
    install_aur_package google-chrome
else
    warn "Skipped google-chrome; change \$Browser in hypr/conf.d/hyprland.d/variables.conf if needed."
fi

link_config() {
    local name=$1 source="$SCRIPT_DIR/$1" target="$CONFIG_HOME/$1"

    [[ -e "$source" ]] || die "Missing dotfiles directory: $source"
    if [[ -L "$target" && "$(readlink -f -- "$target")" == "$(readlink -f -- "$source")" ]]; then
        log "$target is already linked"
        return
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p -- "$BACKUP_DIR"
        mv -- "$target" "$BACKUP_DIR/$name"
        warn "Moved existing $target to $BACKUP_DIR/$name"
    fi

    ln -s -- "$source" "$target"
    log "Linked $target -> $source"
}

mkdir -p -- "$CONFIG_HOME"
for config in alacritty hypr quickshell tofi; do
    link_config "$config"
done

log "Enabling system services"
sudo systemctl enable NetworkManager.service
if ((WITH_BLUETOOTH)); then
    sudo systemctl enable bluetooth.service
fi

if ! locale -a 2>/dev/null | grep -qi '^zh_CN\.utf8$'; then
    warn "zh_CN.UTF-8 is not generated, but the Hyprland config requests it."
    warn "Uncomment zh_CN.UTF-8 in /etc/locale.gen and run: sudo locale-gen"
fi

wallpaper_file="$SCRIPT_DIR/hypr/conf.d/hyprpaper.d/wallpapers.conf"
if grep -q '/home/sado/' "$wallpaper_file"; then
    warn "Update the machine-specific wallpaper path in $wallpaper_file"
fi

cat <<EOF

Setup complete.

Before starting Hyprland:
  1. Adjust monitor settings in:
     $SCRIPT_DIR/hypr/conf.d/hyprland.d/monitors.conf
  2. Adjust the wallpaper path in:
     $wallpaper_file
  3. Configure Pinyin with: fcitx5-configtool
  4. Start Hyprland from a TTY with: Hyprland

Re-running this script is safe; existing config directories are backed up.
EOF
