#!/bin/bash

LOG_FILE=~/ops/logs/alert_$(date +%F).log

CPU_COUNT=$(grep "CPU告警" $LOG_FILE | wc -l)
MEM_COUNT=$(grep "内存告警" $LOG_FILE | wc -l)
DISK_COUNT=$(grep "磁盘告警" $LOG_FILE | wc -l)

echo "===================="
echo "今日告警统计"
echo "===================="

echo "CPU告警次数: $CPU_COUNT"
echo "内存告警次数: $MEM_COUNT"
echo "磁盘告警次数: $DISK_COUNT"
