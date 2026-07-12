# Dotfiles

[English](README.md)

这是一个面向 Arch Linux 桌面环境的个人 dotfiles 仓库，主要包含 Hyprland、Quickshell、Alacritty、Hyprlock、Hyprpaper、PipeWire、NetworkManager、Fcitx5 和相关 Wayland 工具的配置。

仓库适合 Arch 初装用户使用，但 `setup.sh` 的行为是保守的：它会迁移旧用户路径、链接用户配置，并打印软件包和服务命令，不会静默替你改系统包管理状态。

## 目录结构

- `hypr/`：Hyprland、Hyprlock、Hyprpaper 配置。
- `quickshell/`：Quickshell 状态栏、控制中心、设置界面、翻译和辅助脚本。
- `alacritty/`：Alacritty 终端配置。
- `setup.sh`：Arch 初装辅助脚本，负责包提示、服务提示、旧路径迁移、配置链接、依赖检查和卸载链接。

## 安装

克隆仓库并进入目录：

```sh
git clone <repo-url> ~/dotfiles-new
cd ~/dotfiles-new
```

打印建议的 Arch 软件包安装命令：

```sh
./setup.sh packages
```

按需安装软件包后，查看建议启用的服务：

```sh
./setup.sh services
```

检查运行依赖：

```sh
./setup.sh check
```

把旧的用户 home 路径迁移为当前用户的 home。`install` 会自动执行这一步，也可以手动运行：

```sh
./setup.sh migrate
```

把配置链接到 `~/.config`：

```sh
./setup.sh install
```

如果已经存在 `~/.config/alacritty`、`~/.config/hypr` 或 `~/.config/quickshell`，脚本会先把它们移动到 `~/.config/dotfiles-backup/<timestamp>/`，再创建软链接。

## 脚本命令

```sh
./setup.sh install    # 创建用户目录并链接配置
./setup.sh migrate    # 把旧的用户 home 路径替换为当前用户 home
./setup.sh status     # 查看当前链接状态
./setup.sh check      # 检查必需和可选命令
./setup.sh packages   # 打印 Arch 软件包安装命令
./setup.sh services   # 打印推荐的 system/user 服务
./setup.sh uninstall  # 移除由本仓库创建的链接
```

可以覆盖 `XDG_CONFIG_HOME` 和 `BACKUP_ROOT`：

```sh
XDG_CONFIG_HOME="$HOME/.config" BACKUP_ROOT="$HOME/.config/dotfiles-backup" ./setup.sh install
```

## 注意事项

- Quickshell 的命令是 `qs`；根据你的软件源情况，它可能来自已启用的软件源包，也可能需要从 AUR 安装 `quickshell-git`。
- 可选功能会用到 `swww`、`blight`、`matugen`、`ddcutil`、`cliphist`、`hyprpicker` 等工具。缺少可选命令不会阻止核心配置安装。
- 当前 Hyprland 配置会自动启动 `hyprlock`、`hyprpaper`、`qs`、`fcitx5` 和 KDE Polkit agent。

## 卸载

移除由本仓库创建的软链接：

```sh
./setup.sh uninstall
```

安装过程中创建的备份会保留在 `~/.config/dotfiles-backup/`。
