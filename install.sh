#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Dotfile symlinks
ln -sf "$REPO_DIR/dotfiles/.zshrc"    "$HOME/.zshrc"
ln -sf "$REPO_DIR/dotfiles/.tmux.conf" "$HOME/.tmux.conf"

# tmux-clipboard
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO_DIR/bin/tmux-clipboard" "$HOME/.local/bin/tmux-clipboard"

# oh-my-posh (aarch64) — 이미 있으면 스킵
if ! command -v oh-my-posh &>/dev/null && [[ ! -f "$HOME/.local/bin/oh-my-posh" ]]; then
  echo "Downloading oh-my-posh (aarch64)..."
  curl -L -o "$HOME/.local/bin/oh-my-posh" \
    https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64
  chmod +x "$HOME/.local/bin/oh-my-posh"
fi

# fzf — pkg 또는 apt
if ! command -v fzf &>/dev/null; then
  echo "Installing fzf..."
  pkg install -y fzf 2>/dev/null || apt-get install -y fzf 2>/dev/null || \
    echo "WARNING: fzf를 수동으로 설치하세요"
fi

# tpm (tmux plugin manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo "Installing tpm..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo "완료. 셸을 재시작하거나: source ~/.zshrc"
