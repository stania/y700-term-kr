# 설치 가이드

## 사전 준비

1. [Termux](https://github.com/termux/termux-app) 설치 (Play Store 버전 사용 — F-Droid 업데이트가 느림)
2. [Termux:X11](https://github.com/termux/termux-x11) 설치

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

## 2단계: 폰트 설치

```bash
pkg install noto-fonts-cjk
# PlemolKRConsole Nerd Font Mono 는 수동 설치
mkdir -p ~/.local/share/fonts
# https://github.com/yuru7/PlemolJP 에서 NF 버전 다운로드
cp PlemolKRConsole*.ttf ~/.local/share/fonts/
fc-cache -fv
```

## 3단계: GPU 가속 (turnip)

Termux에 `mesa-vulkan-icd-freedreno`가 설치되면 자동으로 ICD 파일이 생성됩니다.

```bash
# 설치 확인
vulkaninfo --summary 2>/dev/null | grep -E 'GPU|deviceType'
# 결과: Turnip Adreno (TM) 730 / PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU
```

WezTerm 실행 시 환경변수로 turnip ICD를 지정합니다:

```bash
VK_ICD_FILENAMES=/data/data/com.termux/files/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json \
  wezterm start --always-new-process
```

## 4단계: 설정 파일 배포

```bash
git clone https://github.com/stania/y700-term-kr ~/y700-term-kr
cd ~/y700-term-kr
./install.sh
```

`install.sh`는 멱등(idempotent)합니다 — 여러 번 실행해도 동일한 환경을 만듭니다.
`.zshrc`·`.tmux.conf` symlink(기존 실파일은 `.bak`으로 백업), oh-my-posh / fzf / fd / tpm 설치,
기본 셸 zsh 전환(Termux)을 수행합니다. Termux에서는 PIE 문제를 피하려 `pkg`로 설치합니다.

## 5단계: proot Ubuntu

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

## 6단계: X11 시작

```bash
~/start-x11.sh
```

Termux:X11 앱이 자동으로 포그라운드로 전환되고 i3가 실행됩니다.

## 7단계: Claude Code (proot 전용)

Claude Code는 glibc 환경이 필요하므로 **proot Ubuntu 안에서만** 설치·실행합니다.
Termux 네이티브(Android Bionic)에서는 Node.js 네이티브 모듈 빌드가 실패합니다.

```bash
# proot-distro login ubuntu 안에서
apt install -y nodejs npm
npm install -g @anthropic-ai/claude-code
```

### API 키 인증

[console.anthropic.com](https://console.anthropic.com)에서 API 키를 발급합니다.

```bash
# proot 안에서
mkdir -p ~/.config/anthropic
echo "sk-ant-api03-..." > ~/.config/anthropic/api_key
chmod 600 ~/.config/anthropic/api_key

# 세션마다 자동 로드 (아래를 ~/.zshrc 에 추가)
export ANTHROPIC_API_KEY="$(cat ~/.config/anthropic/api_key)"

# 동작 확인
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
