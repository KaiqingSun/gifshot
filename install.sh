#!/usr/bin/env bash
# gifshot 一键安装脚本
#
#   ./install.sh                 安装依赖 + 程序 + 桌面入口
#   ./install.sh --hotkeys       顺便注册 GNOME 全局快捷键
#   ./install.sh --no-deps       跳过系统依赖安装（已经装过了）
#   ./install.sh --prefix DIR    改安装目录（默认 ~/.local/bin）
#
set -euo pipefail

PREFIX="${HOME}/.local/bin"
APPDIR="${HOME}/.local/share/applications"
WITH_DEPS=1
WITH_HOTKEYS=0
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-deps)  WITH_DEPS=0; shift ;;
    --hotkeys)  WITH_HOTKEYS=1; shift ;;
    --prefix)   PREFIX="$2"; shift 2 ;;
    -h|--help)  sed -n '2,${/^#/!q; s/^# \?//; p}' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m警告:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m错误:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- 环境检查
[[ "$(uname -s)" == "Linux" ]] || die "gifshot 只支持 Linux。macOS/Windows 见 README 的「平台支持」一节。"

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
  warn "检测到 Wayland 会话。gifshot 依赖 X11（x11grab / xdotool），在 Wayland 下无法工作。"
  warn "登录界面选择「Ubuntu on Xorg」后重试，或按 Ctrl-C 中止。"
  sleep 5
elif [[ -z "${DISPLAY:-}" ]]; then
  warn "DISPLAY 未设置。如果你在 SSH 会话里，安装没问题，但运行需要在图形会话中。"
fi

# ---------------------------------------------------------------- 系统依赖
APT_PKGS=(ffmpeg xdotool xclip x11-utils python3-gi python3-gi-cairo gir1.2-gtk-3.0 libnotify-bin)
DNF_PKGS=(ffmpeg xdotool xclip xorg-x11-utils python3-gobject gtk3 libnotify)
PAC_PKGS=(ffmpeg xdotool xclip xorg-xwininfo xorg-xprop python-gobject gtk3 libnotify)

install_deps() {
  if command -v apt-get >/dev/null; then
    say "用 apt 安装依赖: ${APT_PKGS[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${APT_PKGS[@]}"
  elif command -v dnf >/dev/null; then
    say "用 dnf 安装依赖: ${DNF_PKGS[*]}"
    sudo dnf install -y "${DNF_PKGS[@]}"
  elif command -v pacman >/dev/null; then
    say "用 pacman 安装依赖: ${PAC_PKGS[*]}"
    sudo pacman -S --needed --noconfirm "${PAC_PKGS[@]}"
  else
    warn "认不出包管理器，请手动安装: ffmpeg xdotool xclip xwininfo xprop PyGObject(GTK3+cairo) libnotify"
    return
  fi
}

if [[ $WITH_DEPS -eq 1 ]]; then
  install_deps
else
  say "跳过系统依赖安装（--no-deps）"
fi

# ---------------------------------------------------------------- 安装本体
say "安装 gifshot 到 ${PREFIX}"
mkdir -p "$PREFIX"
install -m 0755 "${SRC}/gifshot" "${PREFIX}/gifshot"

say "写入桌面入口"
mkdir -p "$APPDIR"
sed "s|@EXEC@|${PREFIX}/gifshot|g" "${SRC}/gifshot.desktop.in" > "${APPDIR}/gifshot.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$APPDIR" 2>/dev/null || true

# ---------------------------------------------------------------- PATH
if ! printf '%s' ":${PATH}:" | grep -q ":${PREFIX}:"; then
  warn "${PREFIX} 不在 PATH 里。加这行到 ~/.bashrc 或 ~/.zshrc:"
  printf '\n    export PATH="%s:$PATH"\n\n' "$PREFIX"
fi

# ---------------------------------------------------------------- 快捷键
if [[ $WITH_HOTKEYS -eq 1 ]]; then
  if command -v gsettings >/dev/null; then
    say "注册 GNOME 全局快捷键"
    "${PREFIX}/gifshot" hotkeys install
  else
    warn "没有 gsettings，跳过快捷键注册（非 GNOME 桌面需自行绑定，见 README）"
  fi
else
  say "跳过快捷键注册。之后可运行: gifshot hotkeys install"
fi

# ---------------------------------------------------------------- 体检
echo
say "依赖体检"
"${PREFIX}/gifshot" doctor || true

echo
say "装好了。运行 \`gifshot\` 打开界面，或在应用列表里搜 GifShot。"
