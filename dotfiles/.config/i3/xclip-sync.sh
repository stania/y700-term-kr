#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
LAST=""
while true; do
  # PRIMARY (마우스 선택) 우선, 없으면 CLIPBOARD (Ctrl+Shift+C)
  CURRENT=$(xclip -selection primary -o 2>/dev/null)
  if [ -z "$CURRENT" ]; then
    CURRENT=$(xclip -selection clipboard -o 2>/dev/null)
  fi
  if [ "$CURRENT" != "$LAST" ] && [ -n "$CURRENT" ]; then
    echo "$CURRENT" | termux-clipboard-set 2>/dev/null
    LAST="$CURRENT"
  fi
  sleep 1
done
