#!/bin/bash

MODDIR="/data/adb/modules_update/OP13tFastKeyCtrler"
APK_PATH="$MODPATH/manager.apk"
pname=$(getprop ro.product.model)
echo "[!!] 目前本模块仅支持一加13/13T全版本，适配其他有侧键的手机请联系作者。"
echo "[i] 您的手机型号：$pname"
echo "[i] 临时模块目录：$MODDIR"

mat=false
case "$pname" in
    PJZ110|CPH2649|CPH2653|CPH2655|PKX110|CPH2723)
        mat=true
        ;;
    *)
        mat=false
        ;;
esac


if [ "$mat" = true ]; then
    ui_print "[√] 机型匹配！"
else
    ui_print "[x] 设备型号不匹配！"
    ui_print "仅限 [一加13/13T 系列] 刷入！"
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
echo " 4. 长按1s       ：    录音"
echo ""
echo "如需自定义操作， 请自行修改脚本，即将安装管理器..."
echo "[+] 安装 manager.apk "
pm install -r "$MODDIR/manager.apk"
echo "[+] 侧键控制器 安装完成 (com.idlike.kctrl.app) "
echo ""

echo "安装完成，如果您需要恢复管理器，请重装模块。"
echo "[!] 您需要手动给予管理器SU权限，这样它才能与模块通信！"
echo "按操作修改，保存即生效。"
echo ""
echo "如果功能失效，请运行action或重启手机。"
echo ""

echo "[√] 安装完成"
echo ""
echo "[!] 按键功能需要重启才能生效"