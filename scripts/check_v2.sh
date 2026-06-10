#!/bin/bash

LOGDIR=~/ops/logs
REPORTDIR=~/ops/report
HTMLFILE="$REPORTDIR/report_$(date +%F).html"
LOGFILE="$LOGDIR/check_$(date +%F).log"

mkdir -p "$LOGDIR" "$REPORTDIR"

# ------------------------
# 执行模块巡检
# 内存巡检
if [[ "$MEM_STATUS" != "正常" ]]; then
    MEM_CLASS="warning"
    ~/ops/alert.sh "内存告警" "内存使用率超过阈值"
else
    MEM_CLASS="ok"
fi

# CPU巡检
if [[ "$CPU_STATUS" != "正常" ]]; then
    CPU_CLASS="warning"
    ~/ops/alert.sh "CPU告警" "CPU使用率超过阈值"
else
    CPU_CLASS="ok"
fi

# 磁盘巡检
if [[ "$DISK_STATUS" != "正常" ]]; then
    DISK_CLASS="warning"
    ~/ops/alert.sh "磁盘告警" "磁盘使用率超过阈值"
else
    DISK_CLASS="ok"
fi

NGINX_STATUS="正常"
systemctl is-active nginx >/dev/null 2>&1 || NGINX_STATUS="异常"
NGINX_CLASS=$([[ "$NGINX_STATUS" == "正常" ]] && echo ok || echo warning)

# ------------------------
# 输出日志
{
echo "CPU: $CPU_STATUS"
echo "内存: $MEM_STATUS"
echo "磁盘: $DISK_STATUS"
echo "Nginx: $NGINX_STATUS"
} > "$LOGFILE"

# ------------------------
# HTML 报表生成
cat > "$HTMLFILE" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>服务器巡检报告</title>
<style>
body { font-family: Arial, sans-serif; background-color:#f5f5f5; padding:20px; }
h1 { background:#2c3e50;color:white; padding:10px; }
table { border-collapse: collapse; width:300px; }
th, td { border: 1px solid #000; padding:10px; text-align:center; }
.status-ok { color:green; font-weight:bold; }
.status-warning { color:red; font-weight:bold; }
</style>
</head>
<body>
<h1>服务器巡检报告</h1>
<table>
<tr><td colspan="2">&nbsp;</td></tr> <!-- 空行分隔 -->
<h2>今日告警统计</h2>
<table>
<tr><th>告警类型</th><th>次数</th></tr>
<tr><td>CPU告警</td><td>$(grep "CPU告警" ~/ops/logs/alert_$(date +%F).log | wc -l)</td></tr>
<tr><td>内存告警</td><td>$(grep "内存告警" ~/ops/logs/alert_$(date +%F).log | wc -l)</td></tr>
<tr><td>磁盘告警</td><td>$(grep "磁盘告警" ~/ops/logs/alert_$(date +%F).log | wc -l)</td></tr>
</table>
</table>
</body>
</html>
EOF

echo "巡检完成"
echo "日志文件: $LOGFILE"
echo "HTML报表: $HTMLFILE"

# 清理30天以前的日志和报表
find ~/ops/logs/ -name "alert_*.log" -mtime +30 -delete
find ~/ops/report/ -name "report_*.html" -mtime +30 -delete
