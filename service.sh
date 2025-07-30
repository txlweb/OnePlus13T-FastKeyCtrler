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

read -r PHONE < "$MODDIR/phone.txt"
PHONE=$(echo "$PHONE" | tr -d '\r\n')

SCRIPT_PATH="$MODDIR/${PHONE}.sh"

# 如果对应的脚本存在，则执行；否则执行默认脚本
if [ -f "$SCRIPT_PATH" ]; then
    sh "$SCRIPT_PATH"
else
    echo "找不到 ${PHONE}.sh，执行默认脚本"
    sh "$MODDIR/OP13T.sh"
fi
