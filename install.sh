#!/bin/sh
# install.sh — y700-term-kr dotfiles 배포 (멱등: 여러 번 실행해도 동일한 결과)
# 대상: Termux 네이티브(aarch64 bionic) / proot Ubuntu(aarch64 glibc)
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

log "dotfile symlink"
link "$REPO_DIR/dotfiles/.zshrc"     "$HOME/.zshrc"
link "$REPO_DIR/dotfiles/.tmux.conf" "$HOME/.tmux.conf"

# --- bin helpers ---
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO_DIR/bin/tmux-clipboard" "$HOME/.local/bin/tmux-clipboard"
ln -sf "$REPO_DIR/bin/xdg-open"      "$HOME/.local/bin/xdg-open"

# --- oh-my-posh (반드시 PIE: Termux 네이티브 linker는 non-PIE(EXEC) 거부) ---
if command -v oh-my-posh >/dev/null 2>&1; then
  log "oh-my-posh 이미 설치됨 ($(command -v oh-my-posh))"
elif [ "$IS_TERMUX" -eq 1 ]; then
  log "oh-my-posh 설치 (pkg, 네이티브 PIE)"
  pkg install -y oh-my-posh
else
  log "oh-my-posh 설치 (aarch64 릴리스 → ~/.local/bin)"
  curl -fL -o "$HOME/.local/bin/oh-my-posh" \
    https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64
  chmod +x "$HOME/.local/bin/oh-my-posh"
fi

# --- fzf ---
if command -v fzf >/dev/null 2>&1; then
  log "fzf 이미 설치됨"
elif [ "$IS_TERMUX" -eq 1 ]; then
  log "fzf 설치 (pkg)"
  pkg install -y fzf
else
  log "fzf 설치 (apt)"
  apt-get install -y fzf || warn "fzf를 수동으로 설치하세요"
fi

# --- fd (fzf 기본 탐색 소스; .gitignore 존중 + 잡파일 제외) ---
if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
  log "fd 이미 설치됨"
elif [ "$IS_TERMUX" -eq 1 ]; then
  log "fd 설치 (pkg)"
  pkg install -y fd || warn "fd 설치 실패 — fzf는 find 폴백 사용"
else
  log "fd 설치 (apt)"
  apt-get install -y fd-find || warn "fd 설치 실패 — fzf는 find 폴백 사용"
fi

# --- tpm (tmux plugin manager) ---
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR/.git" ]; then
  log "tpm 이미 설치됨"
else
  log "tpm 설치"
  rm -rf "$TPM_DIR"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# --- 기본 셸을 zsh 로 (멱등) ---
if command -v zsh >/dev/null 2>&1; then
  case "${SHELL:-}" in
    *zsh) log "기본 셸 이미 zsh" ;;
    *)
      if [ "$IS_TERMUX" -eq 1 ]; then
        log "기본 셸을 zsh 로 변경 (chsh)"
        chsh -s zsh || warn "chsh 실패 — 수동으로 'chsh -s zsh'"
      else
        warn "기본 셸이 zsh 가 아닙니다. 'chsh -s $(command -v zsh)' 권장"
      fi
      ;;
  esac
else
  warn "zsh 가 없습니다 (Termux: 'pkg install zsh')"
fi

log "완료. 셸을 재시작하거나: exec zsh"
