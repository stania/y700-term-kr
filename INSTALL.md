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

`install.sh`는 `.zshrc`, `.tmux.conf`를 symlink하고, oh-my-posh / fzf / tpm을 설치합니다.

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

`install.sh`가 `.zshrc`, `.tmux.conf` symlink, oh-my-posh(aarch64), fzf, tpm을 자동 설치합니다.

## 6단계: X11 시작

```bash
~/start-x11.sh
```

Termux:X11 앱이 자동으로 포그라운드로 전환되고 i3가 실행됩니다.

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

### proot에서 프롬프트 안 바뀜
`dotfiles/common/bin/oh-my-posh`가 aarch64 바이너리인지 확인:
```bash
file ~/dotfiles/common/bin/oh-my-posh
# ELF 64-bit LSB executable, ARM aarch64 이어야 함
```

### HiDPI - WezTerm 글자가 작음
`config.dpi`는 X11에서 무시됩니다 (xcb가 물리 화면 크기를 0mm로 읽음).
`font_size`를 직접 키우는 것으로 보정합니다:
```lua
config.font_size = 24.0  -- 14pt@192dpi 등가
```
