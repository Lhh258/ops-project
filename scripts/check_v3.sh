#!/bin/bash

# ------------------------
# 基础路径
LOGDIR="$HOME/ops/logs"
REPORTDIR="$HOME/ops/report"
SCRIPTDIR="$HOME/ops/scripts"

LOGFILE="$LOGDIR/check_$(date +%F).log"
HTMLFILE="$REPORTDIR/report_$(date +%F).html"

mkdir -p "$LOGDIR" "$REPORTDIR"

# ------------------------
# 读取配置
source /home/lhh/ops-project/scripts/config.cfg

# ------------------------
# CPU巡检
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
CPU_STATUS="正常"
if [ "$CPU_USAGE" -ge "$CPU_THRESHOLD" ]; then
    CPU_STATUS="异常"
    "$SCRIPTDIR/alert.sh" "CPU告警" "CPU使用率 $CPU_USAGE% 超过阈值 $CPU_THRESHOLD%"
fi

# 内存巡检
MEM_USAGE=$(free -m | awk 'NR==2 {printf "%.0f", $3/$2*100}')
MEM_STATUS="正常"
if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
    MEM_STATUS="异常"
    "$SCRIPTDIR/alert.sh" "内存告警" "内存使用率 $MEM_USAGE% 超过阈值 $MEM_THRESHOLD%"
fi

# 磁盘巡检
DISK_USAGE=$(df -h / | awk 'NR==2 {print int($5)}')
DISK_STATUS="正常"
if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    DISK_STATUS="异常"
    "$SCRIPTDIR/alert.sh" "磁盘告警" "磁盘使用率 $DISK_USAGE% 超过阈值 $DISK_THRESHOLD%"
fi

# Nginx巡检
NGINX_STATUS="正常"
systemctl is-active nginx >/dev/null 2>&1 || {
    NGINX_STATUS="异常"
    "$SCRIPTDIR/alert.sh" "Nginx告警" "Nginx服务未运行，尝试重启"
    sudo systemctl restart nginx
    systemctl is-active nginx >/dev/null 2>&1 && "$SCRIPTDIR/alert.sh" "Nginx告警" "Nginx已重启成功"
}
CPU_CLASS=$([[ "$CPU_STATUS" == "正常" ]] && echo ok || echo warning)
MEM_CLASS=$([[ "$MEM_STATUS" == "正常" ]] && echo ok || echo warning)
DISK_CLASS=$([[ "$DISK_STATUS" == "正常" ]] && echo ok || echo warning)
NGINX_CLASS=$([[ "$NGINX_STATUS" == "正常" ]] && echo ok || echo warning)

# ------------------------
# 输出日志
{
    echo "巡检日期: $(date)"
    echo "CPU: $CPU_STATUS ($CPU_USAGE%)"
    echo "内存: $MEM_STATUS ($MEM_USAGE%)"
    echo "磁盘: $DISK_STATUS ($DISK_USAGE%)"
    echo "Nginx: $NGINX_STATUS"
} > "$LOGFILE"

# ------------------------
# 生成 HTML 报表
cat > "$HTMLFILE" <<EOF
<html>
<head>
<title>巡检报告 $(date +%F)</title>

<style>
body {
    font-family: Arial;
    margin: 20px;
}

.ok {
    color: green;
    font-weight: bold;
}

.warning {
    color: red;
    font-weight: bold;
}
</style>

</head>
<body>
<h2>巡检报告 $(date +%F)</h2>
<ul>
<li class="$CPU_CLASS">CPU: $CPU_STATUS ($CPU_USAGE%)</li>
<li class="$MEM_CLASS">内存: $MEM_STATUS ($MEM_USAGE%)</li>
<li class="$DISK_CLASS">磁盘: $DISK_STATUS ($DISK_USAGE%)</li>
<li class="$NGINX_CLASS">Nginx: $NGINX_STATUS</li>
</ul>
</body>
</html>
EOF

# 自动更新 index.html
cp "$HTMLFILE" "$REPORTDIR/index.html"

# 清理30天以前日志和报表
find "$LOGDIR" -name "alert_*.log" -mtime +30 -delete
find "$REPORTDIR" -name "report_*.html" -mtime +30 -delete

# ------------------------
echo "巡检完成"
echo "日志文件: $LOGFILE"
echo "HTML报表: $HTMLFILE"
