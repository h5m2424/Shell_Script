#!/bin/bash

file_path="./clean_test.log"  # 需要修改时间的文件路径
desired_date="202307031955"  # 需要修改的时间

# 创建备份副本
cp -p "$file_path" "$file_path.bak"

# 修改备份副本的ctime为所需的日期
touch -t "$desired_date" "$file_path.bak"

# 替换原始文件
mv "$file_path.bak" "$file_path"
