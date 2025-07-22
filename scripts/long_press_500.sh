#!/bin/bash
# 长按500ms动作 - 切换免打扰模式
current=$(settings get global zen_mode)
if [ "$current" = "0" ]; then
    cmd notification set_dnd on
    echo "🔇 免打扰：ON"
else
    cmd notification set_dnd off
    echo "🔊 免打扰：OFF"
fi
