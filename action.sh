#!/bin/bash
MODDIR=${0%/*}
LOCK_FILE="$MODDIR/mpid.txt"

sed -i '/^description=/d' "$MODDIR/module.prop"
echo "description=[x] 服务已关闭！" >> $MODDIR/module.prop

echo "- 尝试重启按键监听服务"

echo "- 正在尝试结束服务..."

if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE")
    if [ -d "/proc/$OLD_PID" ]; then
        echo "- 正在结束 [ $OLD_PID ]"
        kill "$OLD_PID"
        sleep 0.2
        [ -d "/proc/$OLD_PID" ] && kill -9 "$OLD_PID"
    fi
    rm -f "$LOCK_FILE"
fi

sleep 0.2

echo "- 正在尝试重启服务..."

sh $MODDIR/service.sh &

sleep 0.5


NEW_PID=$(cat "$LOCK_FILE" 2>/dev/null)
echo $NEW_PID
if [ -n "$NEW_PID" ] && [ -d "/proc/$NEW_PID" ]; then
    echo "[√] 服务重启成功 [ $NEW_PID ]"
else
    echo "[x] 服务重启失败!"
fi


