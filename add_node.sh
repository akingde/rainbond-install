#!/bin/bash

EXPAND_PATH="/srv/salt/minions"

while getopts "r:i:u:p:" arg 
    do
        case $arg in
             r)
                export NODE_TYPE="$OPTARG" #参数存在$OPTARG中
                ;;
             i)
                export NODE_IP="$OPTARG"
                ;;
             p)
                export LOGIN_PASSWORD="$OPTARG"
                ;;
             ?) 
                echo "unknow argument"
                exit 1
                ;;
        esac
    done

function config_salt_master(){
#=================  初始化节点名称  =======================
    if [ "$NODE_TYPE" == "manage" ] || [ "$NODE_TYPE" == "compute" ];then
        node_list=$(salt-key -L | grep $NODE_TYPE | awk -F "$NODE_TYPE" '{print$2}')
        max_num=$(echo $node_list | awk '{print$1}')
        if [ -z "$node_list" ];then
            node_name="$NODE_TYPE"01
        else
            # 获取最大数
            for i in $node_list
            do
                if [[ $max_num -lt $i ]];then
                    max_num=$i
                fi
            done
                node_num=$((max_num++))
            if [ ${node_num} -le 10 ];then
                node_name="$NODE_TYPE"0"$max_num"
            else
                node_name="$NODE_TYPE""$max_num"
            fi
        fi
#====================  配置roster  =====================
        has_roster=$(grep "$node_name" /etc/salt/roster)
        if [ "$has_roster" == "" ];then
cat >> /etc/salt/roster <<EOF
${node_name}:
  host: ${NODE_IP}
  user: root
  passwd: ${LOGIN_PASSWORD}
EOF
        fi
    else
        echo "You can only specitfy the 'manage' or 'compute' to expand"
        exit 1
    fi
}

function run(){
    # 参数必须全部指定
    if [ -z $NODE_TYPE ] || [ -z $NODE_IP ] || [ -z $LOGIN_PASSWORD ];then
        echo "Through the following parameters can expand a compute or manage node. "
        echo "-r [Role],       Specify a node type(manage/compute)"
        echo "-i [IP],         The ip address what you Specified node."
        echo "-p [Password]    The login password what you Specified node"
        exit 1
    else
        config_salt_master
    fi
}

function check_node(){
    [ -d $EXPAND_PATH/scripts/ ] || mkdir -p $EXPAND_PATH/scripts/
    [ -f $EXPAND_PATH/check.sls ] \
    || cp -rf ./install/salt/minions/check.sls $EXPAND_PATH
    cp ./scripts/before_install.sh $EXPAND_PATH/scripts/
    sed -i "s/^NODE_HOSTNAME=*$/NODE_HOSTNAME=$Node_name/g" $EXPAND_PATH/scripts/before_install.sh
    echo "Checking $Node_name base..."
    salt-ssh -i "$Node_name" state.sls minions.check || exit 1
}

function install_minion(){
    echo "Installing minion..."
    salt-ssh -i "$Node_name" state.sls minions.install || exit 1
}

function install_node(){
    compute_tasks="init storage grbase.dns docker.install misc network etcd node kubernetes.node"
    manage_tasks="init storage docker.install misc etcd network grbase"

    if [ "$NODE_TYPE" == "compute" ];then
        for compute_task in $compute_tasks
        do
            echo "Doing $compute_task task in $NODE_TYPE..."
            salt -E "$NODE_TYPE" state.sls $compute_task || exit 1
        done
    elif [ "$NODE_TYPE" == "manage" ];then
        for manage_task in $manage_tasks
        do
            echo "Doing $manage_task task in $NODE_TYPE..."
            [ "$manage_task" == "etcd" ] && deal_etcd
            salt -E "$NODE_TYPE" state.sls $manage_task || exit 1
        done
    fi 
}

function deal_etcd(){
    has_compute="salt-key -L | grep compute"
    etcdctl member add $Node_name http://$Node_ip:2380
    if [ "$has_compute" != "" ];then
        # 处理计算节点有关etcd-endpoint
        salt -E "compute" state.sls etcd
        salt -E "compute" state.sls network
    fi
}

# 根据参数配置roster、检查目标机器的环境
run

Node_ip=$(grep "inet-ip" /srv/pillar/system_info.sls  | awk '{print$2}')
Node_name=$(cat /etc/salt/roster | tail -n 4 | head -1 | awk -F ':' '{print$1}')

# 检查minion、同时设置目标机器hostname
check_node
# 安装salt-minion、配置minion.conf
install_minion
# 安装计算节点
install_node && echo "Expand complete"