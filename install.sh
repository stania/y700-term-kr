#!/bin/sh
# install.sh — y700-term-kr dotfiles 배포 (멱등: 여러 번 실행해도 동일한 결과)
# 대상: Termux 네이티브(aarch64 bionic) / proot Ubuntu(aarch64 glibc)
#
# 최소 부트스트랩:
#   pkg install git && git clone https://github.com/stania/y700-term-kr ~/y700-term-kr
#   ~/y700-term-kr/install.sh   ← 필요한 모든 것을 설치 후 ~/start-x11.sh 실행
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }

# --- 환경 감지 ---
if [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
  IS_TERMUX=1
else
  IS_TERMUX=0
fi

# --- dotfile symlink (기존 실제 파일은 백업 후 교체, 우리 symlink는 갱신) ---
link() {
  src="$1"; dst="$2"
  if [ -L "$dst" ]; then
    ln -sf "$src" "$dst"
  elif [ -e "$dst" ]; then
    backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    warn "기존 $dst → $backup 로 백업"
    mv "$dst" "$backup"
    ln -s "$src" "$dst"
  else
    ln -s "$src" "$dst"
  fi
}

# =============================================================================
# Termux 네이티브
# =============================================================================
if [ "$IS_TERMUX" -eq 1 ]; then
  log "Termux 패키지 설치 (이미 설치된 항목은 건너뜀)"
  pkg install -y x11-repo
  pkg install -y \
    termux-x11-nightly \
    i3 \
    wezterm \
    rofi dunst \
    ranger feh mupdf-tools \
    fcitx5 \
    mesa mesa-vulkan-icd-freedreno \
    fontconfig \
    xrdb xrandr xclip \
    dmenu \
    openssh \
    noto-fonts-cjk \
    jq \
    termux-api \
    zsh \
    oh-my-posh \
    fzf \
    fd

  log "dotfile symlink (Termux)"
  link "$REPO_DIR/start-x11.sh"          "$HOME/start-x11.sh"
  link "$REPO_DIR/dotfiles/.Xresources"  "$HOME/.Xresources"

  mkdir -p "$HOME/.config/wezterm"
  link "$REPO_DIR/dotfiles/.config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

  mkdir -p "$HOME/.config/i3"
  link "$REPO_DIR/dotfiles/.config/i3/config"          "$HOME/.config/i3/config"
  link "$REPO_DIR/dotfiles/.config/i3/status.sh"       "$HOME/.config/i3/status.sh"
  link "$REPO_DIR/dotfiles/.config/i3/xclip-sync.sh"   "$HOME/.config/i3/xclip-sync.sh"

  mkdir -p "$HOME/.config/rofi"
  link "$REPO_DIR/dotfiles/.config/rofi/config.rasi"   "$HOME/.config/rofi/config.rasi"
  link "$REPO_DIR/dotfiles/.config/rofi/ssh-hosts.sh"  "$HOME/.config/rofi/ssh-hosts.sh"

  mkdir -p "$HOME/.config/fontconfig/conf.d"
  link "$REPO_DIR/dotfiles/.config/fontconfig/conf.d/60-fallback-symbols.conf" \
       "$HOME/.config/fontconfig/conf.d/60-fallback-symbols.conf"

  mkdir -p "$HOME/.config/fcitx5"
  link "$REPO_DIR/dotfiles/.config/fcitx5/profile" "$HOME/.config/fcitx5/profile"
fi

# =============================================================================
# 공통 dotfile symlink
# =============================================================================
log "dotfile symlink (공통)"
link "$REPO_DIR/dotfiles/.zshrc"     "$HOME/.zshrc"
link "$REPO_DIR/dotfiles/.tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.local/bin"
ln -sf "$REPO_DIR/bin/tmux-clipboard" "$HOME/.local/bin/tmux-clipboard"
ln -sf "$REPO_DIR/bin/xdg-open"       "$HOME/.local/bin/xdg-open"

# =============================================================================
# proot / 그 외 환경 전용 도구
# =============================================================================
if [ "$IS_TERMUX" -eq 0 ]; then
  # oh-my-posh (PIE aarch64 바이너리)
  if command -v oh-my-posh >/dev/null 2>&1; then
    log "oh-my-posh 이미 설치됨"
  else
    log "oh-my-posh 설치 (aarch64 릴리스 → ~/.local/bin)"
    curl -fL -o "$HOME/.local/bin/oh-my-posh" \
      https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64
    chmod +x "$HOME/.local/bin/oh-my-posh"
  fi

  # fzf
  if command -v fzf >/dev/null 2>&1; then
    log "fzf 이미 설치됨"
  else
    log "fzf 설치 (apt)"
    apt-get install -y fzf || warn "fzf를 수동으로 설치하세요"
  fi

  # fd
  if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
    log "fd 이미 설치됨"
  else
    log "fd 설치 (apt)"
    apt-get install -y fd-find || warn "fd 설치 실패 — fzf는 find 폴백 사용"
  fi

  # zsh
  if command -v zsh >/dev/null 2>&1; then
    log "zsh 이미 설치됨"
  else
    log "zsh 설치 (apt)"
    apt-get install -y zsh
  fi
fi

# =============================================================================
# tpm (tmux plugin manager) — 공통
# =============================================================================
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR/.git" ]; then
  log "tpm 이미 설치됨"
else
  log "tpm 설치"
  rm -rf "$TPM_DIR"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# =============================================================================
# 기본 셸을 zsh 로 (멱등)
# =============================================================================
case "${SHELL:-}" in
  *zsh) log "기본 셸 이미 zsh" ;;
  *)
    ZSH_PATH="$(command -v zsh 2>/dev/null || true)"
    if [ -z "$ZSH_PATH" ]; then
      warn "zsh를 찾을 수 없음 — chsh 건너뜀"
    elif [ "$IS_TERMUX" -eq 1 ]; then
      log "기본 셸을 zsh 로 변경 (chsh)"
      chsh -s zsh || warn "chsh 실패 — 수동으로 'chsh -s zsh'"
    else
      log "기본 셸을 zsh 로 변경 (chsh)"
      chsh -s "$ZSH_PATH" || warn "chsh 실패 — 수동으로 'chsh -s $ZSH_PATH'"
    fi
    ;;
esac

log "완료. X11 시작: ~/start-x11.sh  |  셸 재시작: exec zsh"
