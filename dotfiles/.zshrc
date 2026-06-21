# History
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zhistory
setopt INC_APPEND_HISTORY HIST_IGNORE_DUPS EXTENDED_HISTORY

# Locale (ko_KR 로케일이 없는 환경은 C.UTF-8로 폴백 — Termux bionic 등)
if locale -a 2>/dev/null | grep -qiE 'ko_KR\.(utf-?8)'; then
  export LANG='ko_KR.UTF-8'
  export LC_CTYPE='ko_KR.UTF-8'
else
  export LANG='C.UTF-8'
  export LC_CTYPE='C.UTF-8'
fi
export LC_MESSAGES='C'
umask 0022

# Terminal
export TERM=xterm-256color
unsetopt PROMPT_SP

# XDG runtime dir (Termux 등 /tmp 쓰기 불가 환경은 $TMPDIR 사용)
if [[ -z "$XDG_RUNTIME_DIR" ]]; then
  export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/$USER-runtime"
  [[ -d "$XDG_RUNTIME_DIR" ]] || mkdir -m 0700 -p "$XDG_RUNTIME_DIR" 2>/dev/null
fi

# Colors / dircolors
autoload colors && colors
[[ -f ~/.dircolors ]] && eval $(dircolors ~/.dircolors)

# Terminal title
function title() { echo -ne '\e]0;'$1'\a' }
export MOSH_TITLE_NOPREFIX=1

# Tmux environment refresh
if [[ -n "$TMUX" ]]; then
  function refresh { eval "$(tmux show-environment -s | grep -v '^PATH=')" }
else
  function refresh { }
fi

# Command timing + xterm title
zmodload zsh/datetime 2>/dev/null
_fmt_dur() {
  local s=$1
  (( s < 60 )) && print -r -- "${s}s" || print -r -- "$(( s / 60 ))m $(( s % 60 ))s"
}
preexec() {
  refresh
  title $@
  OMP_CMD_START_TS=${EPOCHSECONDS:-$(date +%s)}
  OMP_CMD_START_HMS=$(date +%H:%M:%S)
}
precmd() {
  if [[ -n "$OMP_CMD_START_TS" ]]; then
    local end_ts=${EPOCHSECONDS:-$(date +%s)}
    local dur=$(( end_ts - OMP_CMD_START_TS ))
    (( dur > 0 )) && print -r -- "# ${OMP_CMD_START_HMS} → $(date +%H:%M:%S) · $(_fmt_dur $dur)"
    unset OMP_CMD_START_TS OMP_CMD_START_HMS
  fi
  print -v ctx -Pn "%~ - %n@%m"
  title $ctx
}

# Key bindings
bindkey -e
bindkey "^I"   expand-or-complete-prefix
bindkey "^X^I" expand-or-complete
bindkey '^[[Z' reverse-menu-complete

typeset -A key
key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
[[ -n "${key[Home]}"   ]] && bindkey "${key[Home]}"   beginning-of-line
[[ -n "${key[End]}"    ]] && bindkey "${key[End]}"     end-of-line
[[ -n "${key[Insert]}" ]] && bindkey "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}" ]] && bindkey "${key[Delete]}"  delete-char

# Completion
fpath=(~/.zsh/completion $fpath)
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list \
  'm:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=**' 'l:|=* r:|=*'
zstyle ':completion:*' menu select=1
autoload -Uz compinit
compinit -C
# 완성 목록 갱신이 필요할 때: rm ~/.zcompdump && exec zsh

# Aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ls='ls --color=auto -F'
alias gs='git status -sb'
alias gd='git diff'
alias gdc='git diff --cached'
alias gc='git commit'
alias gp='git pull'
alias ts='tig status'
alias git-root='cd "$(git rev-parse --show-toplevel)"'

export EDITOR=vim
export LESS="-R -x4"
export IGNOREEOF=1

# Tmux helper
function spawn_tmux() {
  tmux ls > /dev/null 2>&1 && tmux a -d || tmux
}
alias tm=spawn_tmux

# PATH
export PATH="$HOME/.local/bin:$PATH"

# oh-my-posh prompt
_DOTFILES_DIR=$(dirname $(realpath "${(%):-%x}"))
if command -v oh-my-posh &>/dev/null; then
  eval "$(oh-my-posh init zsh --config $_DOTFILES_DIR/negligible.omp.json)"
else
  PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '
fi

# fzf shell integration
if command -v fzf &>/dev/null; then
  # 기본 탐색 소스: fd 가 있으면 .gitignore 존중 + 잡파일 제외, 없으면 find 폴백
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  else
    export FZF_DEFAULT_COMMAND='find . \( -name .git -o -name node_modules -o -name .cache \) -prune -o -type f -print 2>/dev/null'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_DEFAULT_OPTS='--height 40% --reverse'
  eval "$(fzf --zsh)"
fi
