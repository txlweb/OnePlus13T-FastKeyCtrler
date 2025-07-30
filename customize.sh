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
total=2  # 总选项数量

# 获取当前选项
get_model_name() {
  case "$1" in
    0) echo "OP13T" ;;
    1) echo "OP13" ;;
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
