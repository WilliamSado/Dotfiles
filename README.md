# Arch Linux Hyprland Dotfiles

一套面向 Arch Linux 的 Hyprland 桌面配置，包含 Quickshell 状态栏与快捷设置、Hyprlock、Hyprpaper、Alacritty 和 Tofi。

## 主要组件

- **Hyprland**：Wayland 窗口管理器
- **Quickshell**：状态栏、系统托盘和快捷设置
- **Hyprlock / Hyprpaper**：锁屏与壁纸
- **Alacritty**：终端
- **Tofi**：应用启动器
- **PipeWire / WirePlumber**：音频
- **NetworkManager / BlueZ**：网络与蓝牙
- **Fcitx5**：中文输入法

## 安装

该脚本用于已经完成基础安装、可以正常联网的 Arch Linux。请使用具有 `sudo` 权限的普通用户运行，不要使用 root。

```bash
git clone <仓库地址> ~/dotfiles-new
cd ~/dotfiles-new
./setup.sh
```

脚本会：

1. 更新系统并安装桌面依赖；
2. 默认从 AUR 构建并安装 `google-chrome`，构建前展示 `PKGBUILD`；
3. 将配置目录链接到 `~/.config`；
4. 把已有的同名配置备份至 `~/.config/dotfiles-backup-日期-时间`；
5. 启用 NetworkManager 和蓝牙服务。

可用选项：

```text
--no-aur         跳过 google-chrome
--no-bluetooth   不启用蓝牙服务
-h, --help       显示帮助
```

例如：

```bash
./setup.sh --no-aur --no-bluetooth
```

脚本支持重复运行，已经安装的软件包和已经建立的正确链接会被跳过。

## 首次启动前

### 显示器

根据实际分辨率、刷新率和缩放修改：

```text
hypr/conf.d/hyprland.d/monitors.conf
```

不确定参数时，可以先使用通用配置：

```ini
monitor = , preferred, auto, 1.0
```

### 壁纸

修改以下文件中的 `path`，当前路径是机器相关的绝对路径：

```text
hypr/conf.d/hyprpaper.d/wallpapers.conf
```

### 浏览器、文件管理器和代理

相关变量位于：

```text
hypr/conf.d/hyprland.d/variables.conf
```

如果安装时使用了 `--no-aur`，需要将 `$Browser` 改为已经安装的浏览器。代理端口也应按实际环境调整；不使用代理时，可以直接修改应用启动快捷键。

### 中文输入法

如果系统尚未生成中文 locale，请取消 `/etc/locale.gen` 中 `zh_CN.UTF-8 UTF-8` 的注释，然后执行：

```bash
sudo locale-gen
fcitx5-configtool
```

在 Fcitx5 配置中添加拼音输入法。

完成上述配置后，可从 TTY 启动：

```bash
Hyprland
```

## 常用快捷键

`Super` 为默认主修饰键。

| 快捷键 | 操作 |
| --- | --- |
| `Super + T` | 打开 Alacritty |
| `Super + E` | 打开 Dolphin |
| `Super + B` | 打开浏览器 |
| `Super + R` | 打开应用启动器 |
| `Super + C` | 关闭当前窗口 |
| `Super + V` | 切换浮动状态 |
| `Super + F` | 全屏 |
| `Super + M` | 退出 Hyprland |
| `Super + 1..0` | 切换工作区 1–10 |
| `Super + Shift + 1..0` | 将窗口移动至工作区 1–10 |
| `Super + 方向键` | 移动焦点 |
| `Super + 鼠标左键拖动` | 移动窗口 |
| `Super + 鼠标右键拖动` | 调整窗口大小 |
| `Super + Shift + S` | 区域截图到剪贴板 |
| `Super + Shift + W` | 当前窗口截图到剪贴板 |
| `Print` | 全屏截图到剪贴板 |

音量键、麦克风静音键和屏幕亮度键也已配置。

## 目录结构

```text
.
├── alacritty/    # 终端配置
├── hypr/         # Hyprland、Hyprlock、Hyprpaper
├── quickshell/   # 状态栏和快捷设置
├── tofi/         # 应用启动器
└── setup.sh      # Arch Linux 初始化脚本
```

配置通过软链接部署，因此在仓库中修改文件后会立即反映到 `~/.config`。

## 手动部署

如果不希望运行安装脚本，可以自行安装依赖并创建链接：

```bash
mkdir -p ~/.config
ln -s "$PWD/alacritty" ~/.config/alacritty
ln -s "$PWD/hypr" ~/.config/hypr
ln -s "$PWD/quickshell" ~/.config/quickshell
ln -s "$PWD/tofi" ~/.config/tofi
```

执行前请先处理 `~/.config` 中已有的同名目录，避免 `ln` 在目录内部创建链接。
