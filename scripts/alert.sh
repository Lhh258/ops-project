#!/bin/bash

TITLE=$1
CONTENT=$2

# 按天生成日志文件
ALERT_LOG=~/ops/logs/alert_$(date +%F).log

echo "===================="
echo "告警模块"
echo "===================="

echo "告警标题: $TITLE"
echo "告警内容: $CONTENT"

# 写入当天日志
echo "$(date '+%F %T') | $TITLE | $CONTENT" >> $ALERT_LOG
