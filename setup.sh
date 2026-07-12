#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
BACKUP_ROOT="${BACKUP_ROOT:-"$HOME/.config/dotfiles-backup"}"

CONFIGS=(
  "alacritty"
  "hypr"
  "quickshell"
)

PACMAN_PACKAGES=(
  "alacritty"
  "bluez"
  "bluez-utils"
  "brightnessctl"
  "cliphist"
  "fcitx5"
  "fcitx5-configtool"
  "grim"
  "hyprland"
  "hyprlock"
  "hyprpaper"
  "hyprpicker"
  "imagemagick"
  "jq"
  "networkmanager"
  "pacman-contrib"
  "pipewire"
  "pipewire-pulse"
  "polkit-kde-agent"
  "power-profiles-daemon"
  "qt6-declarative"
  "qt6-svg"
  "qt6-wayland"
  "slurp"
  "swww"
  "ttf-hack-nerd"
  "wf-recorder"
  "wireplumber"
  "wl-clipboard"
  "xdg-desktop-portal-hyprland"
  "zsh"
)

AUR_PACKAGES=(
  "quickshell-git"
  "blight"
  "matugen"
)

REQUIRED_COMMANDS=(
  "alacritty"
  "fcitx5"
  "grim"
  "hyprctl"
  "hyprland"
  "hyprlock"
  "hyprpaper"
  "jq"
  "nmcli"
  "pactl"
  "qs"
  "slurp"
  "wf-recorder"
  "wl-copy"
  "wpctl"
)

OPTIONAL_COMMANDS=(
  "blight"
  "bluetoothctl"
  "brightnessctl"
  "cliphist"
  "convert"
  "ddcutil"
  "hyprpicker"
  "magick"
  "matugen"
  "paccache"
  "powerprofilesctl"
  "swww"
)

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

usage() {
  cat <<EOF
Usage: ./setup.sh [command]

Commands:
  install    Create user dirs and link dotfiles into ${CONFIG_HOME} (default)
  migrate    Replace legacy /home/sado paths with /home/<current-user>
  status     Show current link status
  check      Check Arch/runtime dependencies
  packages   Print Arch package install commands
  services   Print recommended user/system services
  uninstall  Remove links created by this repo
  help       Show this message

Environment:
  XDG_CONFIG_HOME  Target config directory (default: \$HOME/.config)
  BACKUP_ROOT      Backup directory (default: \$HOME/.config/dotfiles-backup)
EOF
}

current_user_name() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "$SUDO_USER"
  elif [[ -n "${USER:-}" ]]; then
    printf '%s\n' "$USER"
  elif [[ -n "${LOGNAME:-}" ]]; then
    printf '%s\n' "$LOGNAME"
  else
    id -un
  fi
}

current_user_home() {
  local user="$1"
  local passwd_home=""

  if command -v getent >/dev/null 2>&1; then
    passwd_home="$(getent passwd "$user" | cut -d: -f6 || true)"
  fi

  if [[ -n "$passwd_home" && "$passwd_home" != "/" ]]; then
    printf '%s\n' "$passwd_home"
  else
    printf '/home/%s\n' "$user"
  fi
}

replace_in_file() {
  local file="$1"
  local from="$2"
  local to="$3"

  [[ -f "$file" ]] || return 0
  grep -qF "$from" "$file" || return 0

  local escaped_from escaped_to
  escaped_from="${from//\//\\/}"
  escaped_to="${to//\\/\\\\}"
  escaped_to="${escaped_to//&/\\&}"
  escaped_to="${escaped_to//\//\\/}"

  sed -i "s/${escaped_from}/${escaped_to}/g" "$file"
  printf '%s\n' "$file"
}

migrate_legacy_home_paths() {
  local user target_home changed_file changed=0
  user="$(current_user_name)"
  target_home="$(current_user_home "$user")"

  log "migrating legacy /home/sado paths to $target_home"

  while IFS= read -r changed_file; do
    changed=1
    log "updated $changed_file"
  done < <(
    find \
      "${REPO_DIR}/hypr" \
      "${REPO_DIR}/quickshell" \
      "${REPO_DIR}/alacritty" \
      -type f \
      -exec sh -c '
        for file do
          case "$file" in
            *.qml|*.conf|*.toml|*.json|*.sh) printf "%s\n" "$file" ;;
          esac
        done
      ' sh {} + | while IFS= read -r file; do
        replace_in_file "$file" "/home/sado" "$target_home"
      done
  )

  if (( ! changed )); then
    log "no legacy /home/sado paths found"
  fi
}

join_words() {
  local word sep=""
  for word in "$@"; do
    printf '%s%s' "$sep" "$word"
    sep=" "
  done
  printf '\n'
}

package_for_command() {
  case "$1" in
    alacritty) printf 'alacritty' ;;
    blight) printf 'blight (AUR)' ;;
    bluetoothctl) printf 'bluez-utils' ;;
    brightnessctl) printf 'brightnessctl' ;;
    cliphist) printf 'cliphist' ;;
    convert|magick) printf 'imagemagick' ;;
    ddcutil) printf 'ddcutil' ;;
    fcitx5) printf 'fcitx5' ;;
    grim) printf 'grim' ;;
    hyprctl|hyprland) printf 'hyprland' ;;
    hyprlock) printf 'hyprlock' ;;
    hyprpaper) printf 'hyprpaper' ;;
    hyprpicker) printf 'hyprpicker' ;;
    jq) printf 'jq' ;;
    matugen) printf 'matugen (AUR)' ;;
    nmcli) printf 'networkmanager' ;;
    paccache) printf 'pacman-contrib' ;;
    pactl) printf 'pipewire-pulse' ;;
    powerprofilesctl) printf 'power-profiles-daemon' ;;
    qs) printf 'quickshell / quickshell-git' ;;
    slurp) printf 'slurp' ;;
    swww) printf 'swww' ;;
    wf-recorder) printf 'wf-recorder' ;;
    wl-copy) printf 'wl-clipboard' ;;
    wpctl) printf 'wireplumber' ;;
    *) printf '-' ;;
  esac
}

timestamp() {
  date '+%Y%m%d-%H%M%S'
}

link_config() {
  local name="$1"
  local source="${REPO_DIR}/${name}"
  local target="${CONFIG_HOME}/${name}"

  [[ -d "$source" ]] || die "missing source directory: $source"
  mkdir -p "$CONFIG_HOME"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      log "$name already linked"
      return
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup_dir="${BACKUP_ROOT}/$(timestamp)"
    mkdir -p "$backup_dir"
    log "backing up existing $target to $backup_dir/$name"
    mv "$target" "$backup_dir/$name"
  fi

  ln -s "$source" "$target"
  log "linked $target -> $source"
}

install_configs() {
  log "installing configs from $REPO_DIR"
  migrate_legacy_home_paths

  mkdir -p \
    "$HOME/Pictures/Screenshots" \
    "$HOME/Pictures/wallpapers" \
    "$HOME/Videos/Recordings"
  log "ensured screenshots, wallpapers, and recordings directories exist"

  for name in "${CONFIGS[@]}"; do
    link_config "$name"
  done

  chmod +x "${REPO_DIR}/quickshell/scripts/"*.sh
  log "made quickshell helper scripts executable"

  warn "wallpaper files are not bundled; adjust wallpaper paths after install if the referenced files do not exist."
  log "done"
}

status_configs() {
  local name target current

  for name in "${CONFIGS[@]}"; do
    target="${CONFIG_HOME}/${name}"
    if [[ -L "$target" ]]; then
      current="$(readlink "$target")"
      if [[ "$current" == "${REPO_DIR}/${name}" ]]; then
        printf '%-12s linked -> %s\n' "$name" "$current"
      else
        printf '%-12s symlink -> %s\n' "$name" "$current"
      fi
    elif [[ -e "$target" ]]; then
      printf '%-12s exists but is not a symlink\n' "$name"
    else
      printf '%-12s missing\n' "$name"
    fi
  done
}

print_package_commands() {
  cat <<EOF
# Arch repo packages:
sudo pacman -S --needed $(join_words "${PACMAN_PACKAGES[@]}")

# AUR or manual packages, depending on your setup:
# yay -S --needed $(join_words "${AUR_PACKAGES[@]}")
# quickshell may also be available from your enabled repos as "quickshell".

# Useful services after package install:
sudo systemctl enable --now NetworkManager bluetooth
systemctl --user enable --now pipewire pipewire-pulse wireplumber xdg-desktop-portal xdg-desktop-portal-hyprland
EOF
}

print_services() {
  cat <<EOF
Recommended services for this config:
  sudo systemctl enable --now NetworkManager
  sudo systemctl enable --now bluetooth
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  systemctl --user enable --now xdg-desktop-portal xdg-desktop-portal-hyprland

Hyprland autostarts hyprlock, hyprpaper, qs, fcitx5, and polkit-kde-agent from this repo.
EOF
}

check_command_group() {
  local title="$1"
  shift

  local missing=0 dep pkg

  log "$title"

  for dep in "$@"; do
    pkg="$(package_for_command "$dep")"
    if command -v "$dep" >/dev/null 2>&1; then
      printf '%-18s ok      %s\n' "$dep" "$pkg"
    else
      printf '%-18s missing %s\n' "$dep" "$pkg"
      missing=1
    fi
  done

  return "$missing"
}

check_arch_host() {
  if [[ -r /etc/arch-release ]]; then
    printf '%-18s ok      /etc/arch-release\n' "arch"
  else
    printf '%-18s warning this script targets Arch Linux\n' "arch"
  fi

  if command -v pacman >/dev/null 2>&1; then
    printf '%-18s ok      pacman available\n' "pacman"
  else
    printf '%-18s missing pacman unavailable\n' "pacman"
  fi
}

check_deps() {
  local missing=0

  check_arch_host
  check_command_group "required runtime commands" "${REQUIRED_COMMANDS[@]}" || missing=1
  check_command_group "optional feature commands" "${OPTIONAL_COMMANDS[@]}" || true

  if (( missing )); then
    warn "run './setup.sh packages' for suggested Arch install commands."
    return 1
  fi
}

uninstall_configs() {
  local name target current

  for name in "${CONFIGS[@]}"; do
    target="${CONFIG_HOME}/${name}"
    if [[ -L "$target" ]]; then
      current="$(readlink "$target")"
      if [[ "$current" == "${REPO_DIR}/${name}" ]]; then
        rm "$target"
        log "removed $target"
      else
        warn "skipping $target; it points to $current"
      fi
    else
      warn "skipping $target; it is not a link created by this repo"
    fi
  done
}

main() {
  local command="${1:-install}"

  case "$command" in
    install)
      install_configs
      ;;
    migrate)
      migrate_legacy_home_paths
      ;;
    status)
      status_configs
      ;;
    check)
      check_deps
      ;;
    packages)
      print_package_commands
      ;;
    services)
      print_services
      ;;
    uninstall)
      uninstall_configs
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      usage
      die "unknown command: $command"
      ;;
  esac
}

main "$@"
