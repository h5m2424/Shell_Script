#!/bin/bash

# YML备份存放层级：“备份目录” / “备份日期” / “环境” / “命名空间” / “资源类型”
# 日志路径：/home/ec2-user/logs_k8s_yaml_back/
# 执行脚本参数一共需要传入3个，依次为：备份路径 命名空间 环境（dev/test/uat/prd），缺一不可，不能换顺序
# 例：bash /home/ec2-user/K8S_Backup/1.get-k8syaml.sh /home/ec2-user/K8S_Backup/yaml_bak default prd

source /etc/profile 
set -e
 
useage(){
    echo "参数个数不正确！请依次传入如下参数:"
    echo "  备份路径 命名空间 环境（dev/test/uat/prd）"
}
 
if [ $# -ne 3 ];then
    useage
    exit
fi

Date=$(date +%Y-%m-%d)
Date_Log=$(date +%Y-%m-%d_%H:%M:%S) 
DUMPDIR=$1
NAMESPACE=$2
K8S_Env=$3config
LogDir=/home/ec2-user/logs_k8s_yaml_back/$Date/k8s_yml_backup_$Date_Log.log

list_names(){  # 获取该命名空间下，该资源类型的所有服务名称
    /usr/bin/kubectl --kubeconfig /home/ec2-user/.kube/$K8S_Env -n "${1}" get "${2}" -o custom-columns='NAME:metadata.name' --no-headers
}
 
dump_workload(){  # 备份函数
    local NAMESPACE=$1
    local WORKLOAD_NAME=$2
    local i
    mkdir -p "${DUMPDIR}/${Date}/${3}/${NAMESPACE}/${WORKLOAD_NAME}"
    mapfile -t WORKLOADS < <(list_names "${NAMESPACE}" "${WORKLOAD_NAME}")  # 获取所有服务名称
    for ((i=1;i<=${#WORKLOADS[@]};i++ )); do
        WORKLOAD="${WORKLOADS[$i-1]}"
        echo "Dumping ${NAMESPACE} ${WORKLOAD_NAME} ${WORKLOAD} $i" >> $LogDir 2>&1
        /usr/bin/kubectl --kubeconfig /home/ec2-user/.kube/$K8S_Env -n "${NAMESPACE}" get "${WORKLOAD_NAME}" "${WORKLOAD}" -o yaml > "${DUMPDIR}/${Date}/${3}/${NAMESPACE}/${WORKLOAD_NAME}/${WORKLOAD}.yaml"  # 备份YML
    done
}

mapfile -t WORKLOAD_NAMES < <(/usr/bin/kubectl --kubeconfig /home/ec2-user/.kube/$K8S_Env api-resources -oname --namespaced=true | grep -vE "(componentstatuses|authentication.k8s.io|bindings|secrets|authorization.k8s.io|pods)")  # 获取该命名空间下的所有服务类型

mkdir -p "${DUMPDIR}/${Date}/${3}/${NAMESPACE}"
mkdir -p /home/ec2-user/logs_k8s_yaml_back/$Date
Date_flag=$(date +%Y-%m-%d_%H:%M:%S) 
echo "| Start Dumping YML files at namespace $NAMESPACE on ENV $3 | Start time:$Date_flag" >>$LogDir 

for ((i=1;i<=${#WORKLOAD_NAMES[@]};i++ )); do
    WORKLOAD_NAME="${WORKLOAD_NAMES[$i-1]}"
    echo "Found $WORKLOAD_NAME $i" >> $LogDir 2>&1
    dump_workload "${NAMESPACE}" "${WORKLOAD_NAME}" "${3}"
done

Date_flag=$(date +%Y-%m-%d_%H:%M:%S) 
echo "| Finish Dumping YML files at namespace $NAMESPACE on ENV $3 | End time:$Date_flag" >>$LogDir   
echo "Done" >> $LogDir
echo -e "" >>$LogDir
