#!/bin/bash

KeepDate=10  # 日志和备份文件保留多少天
LogDir="/home/ec2-user/logs"
BackupDir="/home/ec2-user/backups/"

find $LogDir -mtime +$KeepDate -type d |xargs rm -rf
sleep 3
find $BackupDir -mtime +$KeepDate -type d |xargs rm -rf
