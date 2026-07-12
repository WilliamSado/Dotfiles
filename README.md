# Dotfiles

[中文说明](README.zh-CN.md)

Personal Arch Linux desktop dotfiles for a Hyprland session built around Quickshell, Alacritty, Hyprlock, Hyprpaper, PipeWire, NetworkManager, Fcitx5, and related Wayland utilities.

This repository is intended for fresh Arch installs, but the setup script is conservative: it migrates legacy user paths, links user configuration files, and prints package/service commands instead of silently changing system packages.

## Layout

- `hypr/`: Hyprland, Hyprlock, and Hyprpaper configuration.
- `quickshell/`: Quickshell bar, control center, settings UI, translations, and helper scripts.
- `alacritty/`: Alacritty terminal configuration.
- `setup.sh`: Bootstrap helper for Arch packages, service hints, legacy path migration, config links, dependency checks, and uninstalling links.

## Install

Clone the repository and enter it:

```sh
git clone <repo-url> ~/dotfiles-new
cd ~/dotfiles-new
```

Print the suggested Arch package commands:

```sh
./setup.sh packages
```

Install the packages you want, then enable the recommended services:

```sh
./setup.sh services
```

Check runtime dependencies:

```sh
./setup.sh check
```

Migrate legacy user-specific home paths to the current user's home. `install` runs this automatically, but it can be run explicitly:

```sh
./setup.sh migrate
```

Link the configs into `~/.config`:

```sh
./setup.sh install
```

Existing `~/.config/alacritty`, `~/.config/hypr`, or `~/.config/quickshell` paths are moved to `~/.config/dotfiles-backup/<timestamp>/` before links are created.

## Setup Script Commands

```sh
./setup.sh install    # create user dirs and link configs
./setup.sh migrate    # replace legacy user home paths with the current user's home
./setup.sh status     # show current link status
./setup.sh check      # check required and optional commands
./setup.sh packages   # print Arch package install commands
./setup.sh services   # print recommended system/user services
./setup.sh uninstall  # remove links created by this repository
```

`XDG_CONFIG_HOME` and `BACKUP_ROOT` can be overridden:

```sh
XDG_CONFIG_HOME="$HOME/.config" BACKUP_ROOT="$HOME/.config/dotfiles-backup" ./setup.sh install
```

## Notes

- Quickshell is provided as `qs`; depending on your repositories, it may come from an enabled repo package or from `quickshell-git` in the AUR.
- Optional features use tools such as `swww`, `blight`, `matugen`, `ddcutil`, `cliphist`, and `hyprpicker`. Missing optional commands do not block the core setup.
- Hyprland autostarts `hyprlock`, `hyprpaper`, `qs`, `fcitx5`, and the KDE Polkit agent from this configuration.

## Uninstall

To remove links created by this repo:

```sh
./setup.sh uninstall
```

Backups created during install are kept under `~/.config/dotfiles-backup/`.
