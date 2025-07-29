#!/system/bin/sh

OUTPUT_FILE="output.txt"
TMP_DIR="/data/local/tmp/input_watch"
SCRIPT_DIR="scripts"
mkdir -p "$TMP_DIR"
mkdir -p "$SCRIPT_DIR"
touch "$OUTPUT_FILE"

DEVICES=$(ls /dev/input/event*)

# 启动监听进程
for dev in $DEVICES; do
    [ -e "$dev" ] || continue
    (
        getevent -lt "$dev" | while read -r line; do
            set -- $line
            [ "$#" -lt 5 ] && continue
            event_time=$2
            event_type=$3
            event_code=$4
            event_value=$5

            echo "$(basename "$dev") 时间: $event_time 类型: $event_type 代码: $event_code 值: $event_value" >> "$OUTPUT_FILE"

            # 检测按键按下：type 0001 + value 00000001
                SCRIPT="$SCRIPT_DIR/monitor_once_$event_code.sh"
                LOG_FILE="$TMP_DIR/key_${event_code}.once.log"

                # 如果该脚本尚未生成，生成并启动它
                if [ ! -f "$SCRIPT" ]; then
                    echo "#!/system/bin/sh" > "$SCRIPT"
                    echo "echo \"开始监听键 $event_code 在 $dev\" " >> "$SCRIPT"
                    echo "getevent -lt \"$dev\" | while read -r line; do" >> "$SCRIPT"
                    echo "    set -- \$line" >> "$SCRIPT"
                    echo "    [ \"\$#\" -lt 5 ] && continue" >> "$SCRIPT"
                    echo "    etype=\$3; ecode=\$4; evalue=\$5" >> "$SCRIPT"
                    echo "    if  [ \"\$ecode\" = \"$event_code\" ]; then" >> "$SCRIPT"
                    echo "        echo \"检测到键 $event_code 被再次按下，脚本退出\" " >> "$SCRIPT"
                    echo "        exit 0" >> "$SCRIPT"
                    echo "    fi" >> "$SCRIPT"
                    echo "done" >> "$SCRIPT"
                    chmod +x "$SCRIPT"
                    echo "已创建独立监听脚本 monitor_once_$event_code.sh" >> "$OUTPUT_FILE"
                fi
        done
    ) &
    echo $! >> "$TMP_DIR/pids"
done

# 主进程阻塞等待回车
echo "正在监听全部输入设备事件...（按回车键退出）"
echo "信息将会被收集进 output.txt，请在操作完成后发送给作者。"
echo "请您自己确定一下是哪个按键需要适配，请运行scripts/*.sh来确定，如果按下需要的键后该sh退出，证明这个键是你想要的。"
echo "请把这个sh也一并发送给作者。"
echo "请在github上提交issue。"
read -r

# 用户按了回车，清理子进程
echo "用户按下回车，正在退出..." >> "$OUTPUT_FILE"
for pid in $(cat "$TMP_DIR/pids" 2>/dev/null); do
    kill "$pid" 2>/dev/null
done
rm -rf "$TMP_DIR"
