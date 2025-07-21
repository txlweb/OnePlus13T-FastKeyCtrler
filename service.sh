#!/bin/bash

MODDIR=${0%/*}
LOCK_FILE="$MODDIR/mpid.txt"
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

MYTAG="system_server"  # 可伪装进程名
DEVICE="/dev/input/event0"
KEY="BTN_TRIGGER_HAPPY32"

CLICK_COUNT_FILE="/tmp/click_count_flag"

last_time=0
click_count=0
press_start=0
pressing=0

single_click_delay=3  # 单击延时确认，单位0.1秒
single_click_pid=0

echo "开始监听 $KEY..."

# 用于执行单击动作的函数
do_single_click() {
    echo "单击，播放/暂停"
    input keyevent 85
}

setproctitle() {
    [ -x "$(command -v printf)" ] && printf "\033]0;%s\007" "$MYTAG"
}

setproctitle

# 启动守护进程
(
  PID=$(cat "$LOCK_FILE")
  sed -i '/^description=/d' "$MODDIR/module.prop"
  echo "description=[?] [ $PID ] 服务已启动，按下按键来测试是否生效。" >> $MODDIR/module.prop
  echo 0 > "$CLICK_COUNT_FILE"
  while true; do
      getevent -lt "$DEVICE" | while read -r line; do
          # 解析字段
          set -- $line
          sed -i '/^description=/d' "$MODDIR/module.prop"
          echo "description=[√] [ $PID ] 按键功能已经生效" >> $MODDIR/module.prop

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
                  echo "🔽 按下"

              elif [ "$event_action" = "UP" ]; then
                  pressing=0
                  duration=$((now_total - press_start))
                  echo "🔼 松开, 持续 ${duration}ms"
                  if [ $duration -gt 1000 ]; then
                      am start -n com.coloros.soundrecorder/com.soundrecorder.browsefile.BrowseFile
                      sleep 0.3
                      input tap 606 2360
                  elif [ $duration -gt 500 ]; then
                      echo "⏱ 长按，切换免打扰模式"
                      current=$(settings get global zen_mode)
                      if [ "$current" = "0" ]; then
                          cmd notification set_dnd on
                          echo "🔇 免打扰：ON"
                      else
                          cmd notification set_dnd off
                          echo "🔊 免打扰：OFF"
                      fi
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
                          # 延时执行单击，等待是否会有第二次点击
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
                          # 双击立即响应，取消单击延时
                          echo 1 > "$CLICK_COUNT_FILE"
                          input keyevent 120
                          click_count=0
                          echo "双击，截屏"

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