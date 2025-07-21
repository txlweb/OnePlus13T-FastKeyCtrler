#!/bin/bash
MODDIR=${0%/*}
sed -i '/^description=/d' "$MODDIR/module.prop"
echo "description=[x] 服务已关闭！" >> $MODDIR/module.prop

echo "尝试重启按键监听服务..."

pkill -f "$MODDIR/service.sh"
echo "正在尝试结束服务..."

sleep 1 

echo "正在尝试重启服务..."

sh $MODDIR/service.sh &

echo "重启完成，查看模块描述来判断是否启动成功。"

