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

MYTAG="system_server"
DEVICE="/dev/input/event0"
KEY="BTN_TRIGGER_HAPPY32"


LOGFILE="$MODDIR/log.txt"


CLICK_COUNT_FILE="/tmp/click_count_flag"

CONF_CLICK_TIME="$MODDIR/clconf.txt"

if [ -f "$CONF_CLICK_TIME" ]; then
    CLICK_TIME_SHORT=$(sed -n 1p "$CONF_CLICK_TIME")
    CLICK_TIME_LONG=$(sed -n 2p "$CONF_CLICK_TIME")
else
    CLICK_TIME_SHORT=500
    CLICK_TIME_LONG=1000
fi

: "${CLICK_TIME_LONG:=1000}"
: "${CLICK_TIME_SHORT:=500}"

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
timestamp() {
    date "+%Y-%m-%d %H:%M:%S.%3N"
}
setproctitle

(

  PID=$(cat "$LOCK_FILE")
  sed -i '/^description=/d' "$MODDIR/module.prop"
  echo "description=[?] [ $PID ] 服务已启动，按下按键来测试是否生效。" >> $MODDIR/module.prop
  echo 0 > "$CLICK_COUNT_FILE"

  echo "kctrl_service" > /sys/power/wake_lock

  while true; do
      getevent -lt "$DEVICE" | while read -r line; do
          set -- $line
          sed -i '/^description=/d' "$MODDIR/module.prop"
          echo "description=[√] [ $PID ] 按键功能已经生效" >> $MODDIR/module.prop
          echo "$line"
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
                  press_start=$now_total
                  pressing=1
                  echo "$(timestamp) 🔽 按下" >> "$LOGFILE"

              elif [ "$event_action" = "UP" ]; then
                  pressing=0
                  duration=$((now_total - press_start))
                  echo "$(timestamp) 🔼 松开, 持续 ${duration}ms" >> "$LOGFILE"

                  if [ $duration -gt "$CLICK_TIME_LONG" ]; then
                      do_long_press_1000
                  elif [ $duration -gt "$CLICK_TIME_SHORT" ]; then
                      do_long_press_500
                      click_count=0
                  else
                      diff=$((now_total - last_time))
                      if [ $diff -lt 500 ]; then
                          click_count=$((click_count + 1))
                      else
                          click_count=1
                      fi
                      echo "t: $diff"
                      last_time=$now_total
                      echo "点击次数: $click_count"

                      if [ "$click_count" -eq 1 ]; then
                          (
                              i=0
                              while [ $i -lt $single_click_delay ]; do
                                  sleep 0.1
                                  i=$((i + 1))
                                  flag=$(cat "$CLICK_COUNT_FILE")
                                  if [ "$flag" -eq 1 ]; then
                                      echo 0 > "$CLICK_COUNT_FILE"
                                      exit 0
                                  fi
                              done
                              if [ "$click_count" -eq 1 ]; then
                                  do_single_click
                                  click_count=0
                              fi
                          ) &
                      elif [ "$click_count" -eq 2 ]; then
                          echo 1 > "$CLICK_COUNT_FILE"
                          do_double_click
                          click_count=0
                      fi
                  fi
              fi
          fi
      done
      echo "正在尝试重启服务..."
  done
  sed -i '/^description=/d' "$MODDIR/module.prop"
  echo "description=[x] [ $PID ] 服务被杀死，请尝试手动重启..." >> $MODDIR/module.prop
) &
  echo $! > "$LOCK_FILE"
