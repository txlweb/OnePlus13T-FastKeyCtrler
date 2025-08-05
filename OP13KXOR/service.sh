#!/bin/bash

MODDIR=${0%/*}


TARGET_NAME="oplus,hall_tri_state_key"
CURRENT_EVENT=""
HALL_EVENT=""

INPUT_TMP="/data/local/tmp/input_list.txt"
getevent -il > "$INPUT_TMP" 2>/dev/null

while IFS= read -r line; do
    case "$line" in
        add\ device*)
            CURRENT_EVENT=$(echo "$line" | sed -n 's/^add device .*: \(\/dev\/input\/event[0-9]*\)/\1/p')
            ;;
        '  name:'*)
            DEV_NAME=$(echo "$line" | sed -n 's/^  name: *"\(.*\)"/\1/p')
            if [ "$DEV_NAME" = "$TARGET_NAME" ]; then
                HALL_EVENT="$CURRENT_EVENT"
                break
            fi
            ;;
    esac
done < "$INPUT_TMP"

rm -f "$INPUT_TMP"

# ✅ 输出变量
echo "HALL_EVENT=$HALL_EVENT"

DEVICE="$HALL_EVENT"
KEY="KEY_F3"

echo "开始监听 $KEY..."


get_mode_level() {
  case "$1" in
    响铃) echo 0 ;;
    震动) echo 1 ;;
    勿扰) echo 2 ;;
    *) echo 99 ;;
  esac
}
get_ringer_code() {
  case "$1" in
    响铃) echo NORMAL ;;
    震动) echo VIBRATE ;;
    勿扰) echo SILENT ;;
    *) echo NORMAL ;;
  esac
}
am start-foreground-service -n com.idlike.kctrl.app/.NoteModeGetter
sleep 0.1
last_mode=$(cat /sdcard/Android/data/com.idlike.kctrl.app/files/mode.txt)

while true; do
    getevent -lt "$DEVICE" | while read -r line; do
        set -- $line
        event_key=$4
        event_action=$5

        if [ "$event_key" = "$KEY" ]; then
            if [ "$event_action" = "UP" ]; then
                echo "🔼 松开"
                last_mode=$(cat /data/adb/modules/OP13tKeyXOR/model.txt)
                am start-foreground-service -n com.idlike.kctrl.app/.NoteModeGetter
                sleep 0.1
                mode=$(cat /sdcard/Android/data/com.idlike.kctrl.app/files/mode.txt)
                echo "当前模式：$mode"

                if [ "$mode" != "$last_mode" ]; then
                    restore_mode=$(get_ringer_code "$last_mode")
                    echo "恢复模式为：$restore_mode"
                    cmd audio set-ringer-mode "$restore_mode"
                fi
            fi
        fi
    done
    echo "正在尝试重启服务..."
done
