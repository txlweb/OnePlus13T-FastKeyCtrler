#!/bin/bash

MODDIR=${0%/*}
pname=$(getprop ro.product.model)
echo "您的手机型号：$pname"
if [ "$pname" = "PKX110" ]; then
    ui_print "[√] 机型匹配！"
else    
    ui_print "[x] 设备型号不匹配！"
    ui_print "仅限 [一加13T（PKX110）] 刷入！"
    abort "- Fail"
    exit 2
fi

echo ""
echo "!! 建议把设置里的快捷键设置为无操作 "
echo ""
echo " 本模块默认操作："
echo " 1. 单击          ：    播放/暂停"
echo " 2. 双击          ：    截屏"
echo " 3. 长按0.5s   ：    静音/解除静音"
echo " 4. 长按1s       ：    录音（需要先解锁屏幕）"
echo ""
echo "如需自定义操作， 请自行修改脚本。"
echo ""
echo "如果功能失效，请运行action或重启手机。"
echo ""

echo "[√] 安装完成"
echo ""
echo "[!] 按键功能需要重启才能生效"

sed -i '/^description=/d' "$MODDIR/module.prop"
echo "description=[!] 按键功能需要重启才能生效" >> $MODDIR/module.prop
