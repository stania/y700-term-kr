# 설치 가이드

## install.sh 사용법

```bash
git clone https://github.com/stania/y700-term-kr ~/y700-term-kr
cd ~/y700-term-kr
./install.sh
```

**동작 요약**

| 환경 | 적용 내용 |
|------|-----------|
| Termux 네이티브 | `.zshrc` `.tmux.conf` `.Xresources` symlink, `start-x11.sh` symlink, `.config/wezterm` `.config/i3` `.config/rofi` `.config/fcitx5` `.config/fontconfig` symlink, oh-my-posh(pkg), fzf(pkg), fd(pkg), tpm, zsh 기본 셸 설정 |
| proot Ubuntu | `.zshrc` `.tmux.conf` symlink, oh-my-posh(aarch64 바이너리 → `~/.local/bin`), fzf(apt), fd(apt), tpm, zsh 기본 셸 권장 |

멱등(idempotent) — 여러 번 실행해도 동일한 결과. 기존 실파일은 `.bak.YYYYMMDDHHMMSS`로 백업합니다.

---

## 사전 준비

1. [Termux](https://play.google.com/store/apps/details?id=com.termux) 설치 (Play Store)
2. [Termux:X11](https://play.google.com/store/apps/details?id=com.termux.x11) 설치 (Play Store)

## 1단계: Termux 기본 패키지

```bash
pkg update && pkg upgrade
pkg install x11-repo
pkg install \
  termux-x11-nightly \
  i3 i3status \
  wezterm \
  rofi dunst \
  ranger feh mupdf-tools \
  fcitx5 \
  mesa mesa-vulkan-icd-freedreno \
  fontconfig \
  xrdb xrandr xclip \
  dmenu \
  git openssh
```

turnip ICD가 정상 로드됐는지 확인:

```bash
vulkaninfo --summary 2>/dev/null | grep -E 'GPU|deviceType'
# 결과: Turnip Adreno (TM) 730 / PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU
```

## 2단계: 폰트 설치

```bash
pkg install noto-fonts-cjk
```

**PlemolKRConsole Nerd Font Mono** 는 수동 설치가 필요합니다.

- 저장소: [soomtong/PlemolKR](https://github.com/soomtong/PlemolKR/releases) — PlemolJP 기반 한국어 특화 포크
- 다운로드: `PlemolKRConsole.zip` (Nerd Font 패치 포함)

```bash
# PlemolKRConsole NF 설치 (proot Ubuntu 기준)
mkdir -p ~/.local/share/fonts/PlemolKR
cd /tmp
curl -fLO https://github.com/soomtong/PlemolKR/releases/latest/download/PlemolKRConsole.zip
unzip PlemolKRConsole.zip -d ~/.local/share/fonts/PlemolKR/
fc-cache -fv
```

> `PlemolKR35Console.zip`은 한글 3:영문 5 비율 변형입니다. 반각 기준 폰트폴백 구성에는 기본 `PlemolKRConsole.zip`을 사용합니다.

## 3단계: 설정 파일 배포

```bash
git clone https://github.com/stania/y700-term-kr ~/y700-term-kr
cd ~/y700-term-kr
./install.sh
```

`install.sh`가 설치하는 외부 도구:

| 도구 | 링크 | 용도 |
|------|------|------|
| oh-my-posh | [JanDeDobbeleer/oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh) | 셸 프롬프트 |
| fzf | [junegunn/fzf](https://github.com/junegunn/fzf) | 퍼지 파인더 |
| fd | [sharkdp/fd](https://github.com/sharkdp/fd) | fzf 탐색 소스 |
| tpm | [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) | tmux 플러그인 매니저 |

## 4단계: proot Ubuntu

```bash
pkg install proot-distro
proot-distro install ubuntu
proot-distro login ubuntu

# Ubuntu 안에서:
apt update && apt install zsh mosh git curl
git clone https://github.com/stania/y700-term-kr ~/y700-term-kr
cd ~/y700-term-kr && ./install.sh
```

proot/glibc 환경에서는 `install.sh`가 oh-my-posh aarch64 릴리스를 `~/.local/bin`에 내려받습니다.

## 5단계: X11 시작

```bash
~/start-x11.sh
```

Termux:X11 앱이 자동으로 포그라운드로 전환되고 i3가 실행됩니다.

## 6단계: Claude Code (proot 전용)

Claude Code는 glibc 환경이 필요하므로 **proot Ubuntu 안에서만** 설치·실행합니다.
Termux 네이티브(Android Bionic)에서는 네이티브 바이너리 모듈이 동작하지 않습니다.

공식 설치 가이드: [docs.anthropic.com — Claude Code Setup](https://docs.anthropic.com/en/docs/claude-code/setup)

```bash
# proot-distro login ubuntu 안에서
curl -fsSL https://claude.ai/install.sh | bash
```

### 인증

설치 후 `claude`를 실행하면 브라우저 인증 안내가 나옵니다.

```bash
claude --version
```

### Termux 네이티브 sshd 설정 (Termux 제어용)

proot 안의 Claude Code에서 `pkg`·`termux-api` 같은 Termux 명령을 실행하려면
Termux 네이티브에 sshd를 띄우고 SSH로 우회 진입합니다.

**① Termux 네이티브에서 (proot 밖):**

```bash
pkg install openssh

# 공개키 인증 활성화 — proot 에서 생성한 공개키를 등록
cat /proc/1/root/data/data/com.termux/files/home/.ssh/id_ed25519_termux.pub \
  >> ~/.ssh/authorized_keys   # 경로는 환경에 따라 조정

sshd   # 8022 포트로 시작; 재부팅 후엔 수동으로 다시 실행
```

**② proot 안에서:**

```bash
# 전용 SSH 키 생성 (한 번만)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_termux -N "" -C "proot@termux"

# SSH config 등록
cat >> ~/.ssh/config << 'EOF'
Host termux-native
  HostName 127.0.0.1
  Port 8022
  IdentityFile ~/.ssh/id_ed25519_termux
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF
chmod 600 ~/.ssh/config

# 연결 테스트
ssh termux-native 'echo OK'

# 편의 alias (~/.zshrc 에 추가)
alias tssh='ssh termux-native'
```

이후 Claude Code가 `ssh termux-native pkg install ...` 형태로 Termux를 조작할 수 있습니다.

## 트러블슈팅

### WezTerm 폰트 아틀라스 깨짐
turnip ICD가 제대로 로드됐는지 확인:
```bash
VK_LOADER_DEBUG=all wezterm start 2>&1 | grep -i 'freedreno\|turnip'
```

### 한국어 입력 안 됨
fcitx5가 실행 중인지 확인하고, 환경변수 설정 확인:
```bash
echo $GTK_IM_MODULE   # fcitx
echo $QT_IM_MODULE    # fcitx
echo $XMODIFIERS      # @im=fcitx
```

### 프롬프트 안 바뀜 / `has unexpected e_type: 2` 오류
oh-my-posh·fzf가 설치됐고 **PIE(DYN)** 인지 확인합니다. Termux 네이티브 linker는
non-PIE(EXEC) 바이너리를 거부합니다.
```bash
command -v oh-my-posh fzf
readelf -h "$(command -v oh-my-posh)" | grep Type   # Type: DYN 이어야 함
```
`Type: EXEC`(non-PIE)면 Termux에서는 `pkg install oh-my-posh fzf`로 네이티브 PIE 버전을
설치하세요. (PATH에 옛 EXEC 바이너리 경로가 앞서 있지 않은지도 확인)

### HiDPI - WezTerm 글자가 작음
`config.dpi`는 X11에서 무시됩니다 (xcb가 물리 화면 크기를 0mm로 읽음).
`font_size`를 직접 키우는 것으로 보정합니다:
```lua
config.font_size = 24.0  -- 14pt@192dpi 등가
```
