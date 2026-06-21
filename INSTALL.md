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
| Termux 네이티브 | 필요한 모든 패키지 `pkg install`, dotfile symlink, tpm, zsh + chsh |
| proot Ubuntu | dotfile symlink, oh-my-posh(aarch64 바이너리), fzf/fd/zsh(apt), tpm, chsh |

멱등(idempotent) — 여러 번 실행해도 동일한 결과. 기존 실파일은 `.bak.YYYYMMDDHHMMSS`로 백업합니다.

Termux에서는 `pkg install git` 한 번만 수동으로 실행한 뒤 `./install.sh`가 나머지를 전부 처리합니다.

---

## 사전 준비

1. [Termux](https://play.google.com/store/apps/details?id=com.termux) 설치 (Play Store)
2. [Termux:X11](https://github.com/termux/termux-x11/releases/tag/nightly) 설치 (GitHub nightly APK — Play Store 미지원)

### Termux 가상 키보드 설정

Termux 설정 → **Extra keys rows** 또는 `~/.termux/termux.properties`에 아래 내용을 붙여넣고 `termux-reload-settings` 실행:

```
extra-keys = [['ESC', 'TAB', 'CTRL', 'ALT', 'COLON', 'UP', 'BKSP'], \
              ['CTRL', 'SHIFT', 'ALT', 'LEFT', 'DOWN', 'RIGHT', 'ENTER']]
```

`install.sh` 적용 시 자동으로 배포됩니다.

## 1단계: 설정 파일 배포 (Termux)

```bash
pkg install git
git clone https://github.com/stania/y700-term-kr ~/y700-term-kr
~/y700-term-kr/install.sh
```

`install.sh`가 수행하는 작업:
- `pkg upgrade` 후 X11 환경에 필요한 모든 패키지 설치
- dotfile symlink, sshd 서비스 자동 활성화 (`sv-enable sshd`)
- zsh 설치 및 기본 셸 변경

주요 설치 패키지: termux-x11-nightly, i3, wezterm, rofi, dunst, fcitx5, mesa,
mesa-vulkan-icd-freedreno, fontconfig, xrdb, xrandr, xclip, dmenu, openssh,
noto-fonts-cjk, jq, termux-api, termux-services, zsh, oh-my-posh, fzf, fd, vulkan-tools

설치 후 turnip ICD가 정상 로드됐는지 확인:

```bash
vulkaninfo --summary 2>/dev/null | grep -E 'GPU|deviceType'
# 결과: Turnip Adreno (TM) 730 / PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU
```

## 2단계: 폰트 설치 (PlemolKRConsole)

`noto-fonts-cjk`는 `install.sh`가 자동 설치합니다. **PlemolKRConsole Nerd Font Mono**만 수동으로 설치합니다.

- 저장소: [soomtong/PlemolKR](https://github.com/soomtong/PlemolKR/releases) — PlemolJP 기반 한국어 특화 포크

```bash
mkdir -p ~/.local/share/fonts/PlemolKR
curl -fLO https://github.com/soomtong/PlemolKR/releases/latest/download/PlemolKRConsole.zip
unzip PlemolKRConsole.zip -d ~/.local/share/fonts/PlemolKR/
fc-cache -fv
```

> `PlemolKR35Console.zip`은 한글 3:영문 5 비율 변형입니다.

## 3단계: proot Ubuntu

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

## 4단계: X11 시작

```bash
~/start-x11.sh
```

Termux:X11 앱이 자동으로 포그라운드로 전환되고 i3가 실행됩니다.

## 5단계: Claude Code (proot 전용)

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
