#!/data/data/com.termux/files/usr/bin/bash

# X 서버가 실제로 떠 있는지는 프로세스로 판단한다.
# (소켓 파일 $TMPDIR/.X11-unix/X0 은 서버가 죽어도 남는 stale 가능성이 있어
#  소켓 존재만으로 판단하면 X 서버 없이 i3를 띄워 부팅이 실패한다.)
if ! pgrep -x termux-x11 >/dev/null 2>&1; then
  rm -f "$TMPDIR/.X11-unix/X0" 2>/dev/null   # 죽은 서버가 남긴 stale 소켓 정리
  termux-x11 :0 &
  # 소켓이 준비될 때까지 대기 (최대 ~10초)
  for _ in $(seq 1 50); do
    [ -S "$TMPDIR/.X11-unix/X0" ] && break
    sleep 0.2
  done
fi

# Termux:X11 앱 포그라운드로
am start -n com.termux.x11/.MainActivity 2>/dev/null

export DISPLAY=:0

xrdb -merge ~/.Xresources 2>/dev/null
xrandr --dpi 192 2>/dev/null
setxkbmap -option ctrl:nocaps 2>/dev/null

# D-Bus 시작
eval $(dbus-launch --sh-syntax) 2>/dev/null
export DBUS_SESSION_BUS_ADDRESS

# fcitx5 한국어 입력기
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
fcitx5 -d 2>/dev/null
sleep 1

exec i3
