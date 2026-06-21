#!/data/data/com.termux/files/usr/bin/bash
while true; do
  BAT=$(termux-battery-status 2>/dev/null)
  PCT=$(echo "$BAT" | jq -r .percentage 2>/dev/null)
  PLUGGED=$(echo "$BAT" | jq -r .plugged 2>/dev/null)
  if [ "$PLUGGED" != "UNPLUGGED" ]; then ICON="[AC]"
  elif [ "${PCT:-100}" -le 20 ]; then ICON="[!!]"
  else ICON="[BAT]"; fi
  IM=$(fcitx5-remote -n 2>/dev/null)
  case "$IM" in
    hangul)      IM_STATUS="[KO]" ;;
    keyboard-us) IM_STATUS="[EN]" ;;
    "")          IM_STATUS="[--]" ;;
    *)           IM_STATUS="[${IM}]" ;;
  esac

  TIME=$(date +"%Y-%m-%d %H:%M")
  echo "$IM_STATUS  |  $ICON ${PCT}%  |  $TIME"
  sleep 5
done
