#!/usr/bin/env bash
#
# iDev 收件箱一键安装（macOS）。应用未做 Apple 公证，本脚本下载最新版后
# 自动去隔离 + ad-hoc 重签，绕过 Gatekeeper，免去「右键打开 / 系统设置放行」。
#
#   curl -fsSL https://raw.githubusercontent.com/iDev-agent/idev-inbox-dist/main/install.sh | bash
#
set -euo pipefail

REPO="iDev-agent/idev-inbox-dist"
DEST="/Applications"

case "$(uname -m)" in
  arm64) ASSET="iDev.Inbox_aarch64.app.tar.gz" ;;
  *) echo "✗ 目前仅提供 macOS Apple Silicon 版本（当前架构: $(uname -m)）" >&2; exit 1 ;;
esac

# .app.tar.gz 文件名跨版本固定，直接走 latest 直链——不调 API、不受未认证速率限制
URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "→ 下载最新版 ${ASSET}…"
curl -fsSL "${URL}" -o "${TMP}/app.tar.gz"
tar -xzf "${TMP}/app.tar.gz" -C "${TMP}"

APP_PATH=$(find "${TMP}" -maxdepth 2 -name "*.app" | head -1)
[ -n "${APP_PATH}" ] || { echo "✗ 解压后未找到 .app" >&2; exit 1; }
APP_NAME=$(basename "${APP_PATH}")

echo "→ 安装到 ${DEST}/${APP_NAME}…"
pkill -f "${APP_NAME}/Contents/MacOS" 2>/dev/null || true
rm -rf "${DEST:?}/${APP_NAME}"
mv "${APP_PATH}" "${DEST}/"

# 去隔离属性 + ad-hoc 重签，让未公证应用可直接打开
xattr -cr "${DEST}/${APP_NAME}" 2>/dev/null || true
codesign --force --deep --sign - "${DEST}/${APP_NAME}" 2>/dev/null || true

echo "→ 启动…"
open "${DEST}/${APP_NAME}"
echo "✓ 安装完成：${DEST}/${APP_NAME}"
echo "  之后应用会通过内置 updater 自动升级；如需手动重装，重跑本命令即可。"
