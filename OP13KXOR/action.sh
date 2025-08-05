#!/bin/bash
MODDIR="/data/"
OUTFILE="$MODDIR/model.txt"
index=0
total=3  # 总选项数量
get_mode_level() {
  case "$1" in
    响铃) echo 0 ;;
    震动) echo 1 ;;
    勿扰) echo 2 ;;
    *) echo 99 ;;
  esac
}
get_model_name() {
  case "$1" in
    0) echo "响铃" ;;
    1) echo "震动" ;;
    2) echo "勿扰" ;;
    *) echo "未知" ;;
  esac
}
until_key() {
  PIPE="$MODDIR/$$.pipe"
  mkfifo "$PIPE" 2>/dev/null
  getevent -l > "$PIPE" &
  GETEVENT_PID=$!

  while read -r line; do
    case "$line" in
      *KEY_VOLUMEUP*DOWN*)
        kill $GETEVENT_PID 2>/dev/null
        rm -f "$PIPE"
        echo "up"
        return
        ;;
      *KEY_VOLUMEDOWN*DOWN*)
        kill $GETEVENT_PID 2>/dev/null
        rm -f "$PIPE"
        echo "down"
        return
        ;;
    esac
  done < "$PIPE"

  kill $GETEVENT_PID 2>/dev/null
  rm -f "$PIPE"
}

am start-foreground-service -n com.idlike.kctrl.app/.NoteModeGetter
sleep 0.1
index=$(get_mode_level "$(cat /sdcard/Android/data/com.idlike.kctrl.app/files/mode.txt)")


while true; do
  current_model=$(get_model_name "$index")
  echo "请按键选择（当前：$current_model）..."
  case "$(until_key)" in
    "up")
      index=$(( (index + 1) % total ))
      echo "→ 切换为：$(get_model_name "$index")"
      ;;
    "down")
      selected=$(get_model_name "$index")
      echo "✅ 已选择：$selected"
      echo "$selected" > "$OUTFILE"
      echo "✔️ 已写入到：$OUTFILE"
      break
      ;;
  esac
done
