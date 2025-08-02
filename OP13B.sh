#!/bin/bash

MODDIR=${0%/*}
LOCK_FILE="$MODDIR/mpid.txt"
SCRIPTS_DIR="$MODDIR/scripts"

sed -i '/^description=/d' "$MODDIR/module.prop"
echo "description=[?] 尝试启动.." >> $MODDIR/module.prop

if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if [ -d "/proc/$PID" ]; then
        exit 0
    else
        rm -f "$LOCK_FILE"
    fi
fi

sleep 0.1

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



MYTAG="system_server"
DEVICE="$HALL_EVENT"
KEY="KEY_F3"

CLICK_COUNT_FILE="/tmp/click_count_flag"

CONF_CLICK_TIME="$MODDIR/clconf.txt"

if [ -f "$CONF_CLICK_TIME" ]; then
    CLICK_TIME=$(sed -n 3p "$CONF_CLICK_TIME")
else
    CLICK_TIME=2000
fi

: "${CLICK_TIME:=2000}"

last_time=0
click_count=0
press_start=0
pressing=0

single_click_delay=3  # 0.1秒 * 3 = 0.3秒延时确认单击

echo "开始监听 $KEY..."

do_single_click() {
    sh "$SCRIPTS_DIR/single_click.sh"
}

do_double_click() {
    sh "$SCRIPTS_DIR/double_click.sh"
}

do_long_press_500() {
    sh "$SCRIPTS_DIR/long_press_500.sh"
}

do_long_press_1000() {
    sh "$SCRIPTS_DIR/long_press_1000.sh"
}

setproctitle() {
    [ -x "$(command -v printf)" ] && printf "\033]0;%s\007" "$MYTAG"
}

setproctitle

(

  PID=$(cat "$LOCK_FILE")
  sed -i '/^description=/d' "$MODDIR/module.prop"
  echo "description=[?] [ $PID ] 服务已启动，按下按键来测试是否生效。" >> $MODDIR/module.prop
  echo 0 > "$CLICK_COUNT_FILE"

  echo "kctrl_service" > /sys/power/wake_lock
prev_mode=""
last_mode=""
curr_mode=""
prev_time=0
last_time=0
curr_time=0

get_mode_level() {
  case "$1" in
    响铃) echo 0 ;;
    震动) echo 1 ;;
    勿扰) echo 2 ;;
    *) echo 99 ;;
  esac
}

while true; do
    getevent -lt "$DEVICE" | while read -r line; do
        set -- $line
        sed -i '/^description=/d' "$MODDIR/module.prop"
        echo "description=[√] [ $PID ] 按键功能已经生效" >> "$MODDIR/module.prop"

        event_time=$2
        event_type=$3
        event_key=$4
        event_action=$5

        if [ "$event_key" = "$KEY" ]; then
            time_now=$(echo "$event_time" | tr -d '[')
            now_sec=$(echo "$time_now" | cut -d. -f1)
            now_msec=$(echo "$time_now" | cut -d. -f2 | cut -c1-3)
            now_total=$((now_sec * 1000 + now_msec))

            if [ "$event_action" = "DOWN" ]; then
                pressing=1
                echo "🔽 按下"

            elif [ "$event_action" = "UP" ]; then
                echo "🔼 松开"

                am start-foreground-service -n com.idlike.kctrl.app/.NoteModeGetter
                sleep 0.3
                mode=$(cat /sdcard/Android/data/com.idlike.kctrl.app/files/mode.txt)
                echo "当前模式：$mode"

                # 更新模式状态记录
                prev_mode="$last_mode"
                last_mode="$curr_mode"
                curr_mode="$mode"

                prev_time="$last_time"
                last_time="$curr_time"
                curr_time="$now_total"

                # 检查三段切换方向（在1s内往返）
                if [ "$prev_mode" = "$curr_mode" ] && [ "$last_mode" != "$curr_mode" ]; then
                    if [ $((curr_time - prev_time)) -le $CLICK_TIME ]; then
                        level_last=$(get_mode_level "$last_mode")
                        level_curr=$(get_mode_level "$curr_mode")

                        if [ "$level_last" -gt "$level_curr" ]; then
                            do_single_click
                        else
                            do_double_click
                        fi
                    fi
                fi
            fi
        fi
    done
    echo "正在尝试重启服务..."
done

  sed -i '/^description=/d' "$MODDIR/module.prop"
  echo "description=[x] [ $PID ] 服务被杀死，请尝试手动重启..." >> $MODDIR/module.prop
  )&

  echo $! > "$LOCK_FILE"
