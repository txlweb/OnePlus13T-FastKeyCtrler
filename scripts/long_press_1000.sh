#!/bin/bash
# 长按1000ms动作 - 打开录音文件浏览（你原脚本）
am start -n com.coloros.soundrecorder/com.soundrecorder.browsefile.BrowseFile
sleep 0.3
input tap 606 2360
