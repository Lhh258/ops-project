#!/bin/bash

# -------------------------------
# 配置目录
LOGDIR="/home/lhh/ops/logs"
REPORTDIR="/var/www/testsite/report"

mkdir -p "$LOGDIR"
mkdir -p "$REPORTDIR"

# 日志文件
LOGFILE="$LOGDIR/check_$(date +%F).log"
HTMLFILE="$REPORTDIR/report_$(date +%F).html"

# ===============================
# 日志输出
{
echo "=============================="
echo "服务器巡检报告"
echo "时间: $(date)"
echo "主机: $(hostname)"
echo "=============================="

# CPU
echo
echo "【CPU负载】"
uptime

# 内存
echo
echo "【内存使用】"
free -h
MEM_USED=$(free -m | awk '/Mem:/ {print int($3/$2*100)}')
if [[ -n "$MEM_USED" ]]; then
  (( MEM_USED >= 80 )) && echo "警告: 内存使用率过高 ($MEM_USED%)" || echo "内存正常: ${MEM_USED}%"
fi

# 磁盘
echo
echo "【磁盘使用】"
df -h
DISK_USED=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')
if [[ -n "$DISK_USED" ]]; then
  (( DISK_USED >= 80 )) && echo "警告: 磁盘使用率过高 ($DISK_USED%)" || echo "磁盘正常: ${DISK_USED}%"
fi

# Nginx状态
echo
echo "【Nginx状态】"
systemctl is-active nginx >/dev/null 2>&1 && echo "Nginx运行正常" || echo "Nginx未运行"

# Nginx访问统计
echo
echo "【Nginx访问统计】"
ACCESS_LOG="/var/log/nginx/access.log"

if [[ -f "$ACCESS_LOG" ]]; then
  TOTAL=$(wc -l < "$ACCESS_LOG")
  echo "访问总数: $TOTAL"

  echo "状态码统计:"
  awk '{print $9}' "$ACCESS_LOG" | sort | uniq -c | sort -nr

  echo "访问IP TOP10:"
  awk '{print $1}' "$ACCESS_LOG" | sort | uniq -c | sort -nr | head -10

  echo "访问URL TOP10:"
  awk '{print $7}' "$ACCESS_LOG" | sort | uniq -c | sort -nr | head -10
fi

} > "$LOGFILE"

# ===============================
# 生成 HTML 报表

cat > "$HTMLFILE" <<EOF
<html>
<head>
<meta charset="UTF-8">
<title>服务器巡检报告</title>
</head>
<body>
<h1>服务器巡检报告</h1>
<p>生成时间：$(date)</p>

<pre>
$(cat "$LOGFILE")
</pre>

</body>
</html>
EOF
