#!/usr/bin/env bash
# 卸载 gifshot（不动系统依赖，也不删你已经录好的 GIF）
set -euo pipefail
PREFIX="${1:-${HOME}/.local/bin}"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if command -v gsettings >/dev/null && [[ -x "${PREFIX}/gifshot" ]]; then
  say "移除全局快捷键"
  "${PREFIX}/gifshot" hotkeys remove || true
fi

say "删除程序和桌面入口"
rm -f "${PREFIX}/gifshot"
rm -f "${HOME}/.local/share/applications/gifshot.desktop"

say "删除配置和状态（录好的 GIF 保留在输出目录）"
rm -rf "${HOME}/.config/gifshot" "${HOME}/.local/state/gifshot"

say "卸载完成。系统依赖（ffmpeg / xdotool / xclip 等）没有动。"
