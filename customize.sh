#!/bin/bash

MODDIR="/data/adb/modules_update/OP13tFastKeyCtrler"
APK_PATH="$MODDIR/manager.apk"
PKG_NAME="com.idlike.kctrl.app"
pname=$(getprop ro.product.model)
OUTFILE="$MODDIR/phone.txt"

echo "[!!] 目前本模块仅支持一加13/13T全版本，适配其他有侧键的手机请联系作者。"
echo "[i] 您的手机型号：$pname"
echo "[i] 临时模块目录：$MODDIR"

# 以文本列表实现选项
index=0
total=3  # 总选项数量

# 获取当前选项
get_model_name() {
  case "$1" in
    0) echo "OP13T" ;;
    1) echo "OP13A" ;;
    2) echo "OP13B" ;;
    # 你可以继续加其他项
    *) echo "未知" ;;
  esac
}

# 等待按键函数
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

# 显示提示
echo "=============================="

echo "各机型绑定的按键："
echo " OP13T : 左侧侧键"
echo " OP13A  : 电源键  "
echo " OP13B  : 三段式滑动 （上下上对应单击，下上下对应双击，其他无功能）  "

echo ""
echo "=============================="
echo "设备型号选择器"
echo "音量上键 → 切换型号"
echo "音量下键 → 确定并写入"
echo "=============================="
echo ""

# 主循环
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



echo ""
echo "!! 建议把设置里的快捷键设置为无操作 "
echo ""

echo ""
echo "如需自定义操作， 请自行修改脚本，即将安装管理器..."
PACKAGE="com.idlike.kctrl.app"

echo "[+] 检查是否已安装 $PACKAGE"

if pm list packages | grep -q "$PACKAGE"; then
    echo "[+] 检测到已安装，准备卸载 $PACKAGE"
    pm uninstall "$PACKAGE"
    sleep 1
else
    echo "[+] 未检测到已安装的 $PACKAGE"
fi

echo "[+] 正在安装 manager.apk..."
pm install -r "$APK_PATH"

if [ $? -eq 0 ]; then
    echo "[+] 侧键控制器 安装完成 ($PACKAGE)"
else
    echo "[!] 安装失败，请检查 APK 是否存在或签名问题"
fi

echo ""

echo "安装完成，如果您需要恢复管理器，请重装模块。"
echo "[!] 您需要手动给予管理器SU权限，这样它才能与模块通信！"
echo "按操作修改，保存即生效。"
echo ""
echo "如果功能失效，请运行action或重启手机。"
echo ""

SRC_DIR="/data/adb/modules/OP13tFastKeyCtrler"
DST_DIR="/data/adb/modules_update/OP13tFastKeyCtrler"

# 创建目标目录（如果不存在）
mkdir -p "$DST_DIR"

# 判断并复制 clconf.txt
if [ -f "$SRC_DIR/clconf.txt" ]; then
    cp -f "$SRC_DIR/clconf.txt" "$DST_DIR/clconf.txt"
    echo "[+] 已继承配置文件 (1)"
fi

# 判断并复制 scripts 目录
if [ -d "$SRC_DIR/scripts" ]; then
    cp -a "$SRC_DIR/scripts" "$DST_DIR/scripts"
    echo "[+] 已继承配置文件 (2)"

fi

# 输出提示信息
echo "[√] 安装完成"

echo ""
echo "[!] 按键功能需要重启才能生效"
echo ""

echo "QQ 交流群：764576035"
