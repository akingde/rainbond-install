#!/bin/bash

while getopts "r:i:u:p:" arg 
    do
        case $arg in
             r)
                export NODE_TYPE="$OPTARG" #参数存在$OPTARG中
                ;;
             i)
                export NODE_IP="$OPTARG"
                ;;
             u)
                export LOGIN_USER="$OPTARG"
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
#=================  获取目标节点信息  =======================
    if [ "$NODE_TYPE" == "manage" ];then
        salt-key | grep manage
        echo  /etc/salt/roster
    elif [ "$NODE_TYPE" == "compute" ];then
        compute_list=$(salt-key -L | grep compute | awk -F 'compute' '{print$2}')
        max_num=$(echo $compute_list | awk '{print$1}')
        if [ -z "$compute_list" ];then
            compute_name="compute01"
        else
            # 获取最大数
            for i in $compute_list
            do
                if [[ $max_num -lt $i ]];then
                    max_num=$i
                fi
            done
                node_num=$((max_num++))
            if [ ${node_num} -le 10 ];then
                compute_name="compute0$max_num"
            else
                compute_name="compute$max_num"
            fi
        fi
#====================  配置compute_info.sls  =======================
        has_info=$(grep "$compute_name" ../install/pillar/compute_info.sls)
        if [ "$has_info" == "" ];then
cat >> ../install/pillar/compute_info.sls <<EOF       
${compute_name}:
  ip: ${NODE_IP}
EOF
        fi

#====================  配置roster  =====================
        has_roster=$(grep "$compute_name" /etc/salt/roster)
        if [ "$has_roster" == "" ];then
cat >> /etc/salt/roster <<EOF
${compute_name}:
  host: ${NODE_IP}
  user: ${LOGIN_USER}
  passwd: ${LOGIN_PASSWORD}
EOF
        fi
    else
        echo "You can only specitfy the 'manage' or 'compute' to expand"
    fi
}

function run(){
    # 参数必须全部指定
    if [ -z $NODE_TYPE ] || [ -z $NODE_IP ] || [ -z $LOGIN_USER ] || [ -z $LOGIN_PASSWORD ];then
        echo "Through the following parameters can expand a compute or manage node. "
        echo "-r [Role],       Specify a node type(manage/compute)"
        echo "-i [IP],         The ip address what you Specified node."
        echo "-u [User],       The login user what you Specified node"
        echo "-p [Password]    The login password what you Specified node"
    else
        config_salt_master
    fi
}

function check_compute(){
    cp ./before_install.sh /srv/salt/expand/scripts/
    sed -i "s/^COMPUTE_HOSTNAME=*$/COMPUTE_HOSTNAME=$Node_name/g" /srv/salt/expand/scripts/before_install.sh
    salt-ssh -i "$Node_name" state.sls expand.check || exit 1
}

function install_minion(){
    
    sed -i "s/^master:*$/master: $Master_ip/g" /srv/salt/expand/conf/minion.conf
    sed -i "s/^id:*$/id: $Node_name/g" /srv/salt/expand/conf/minion.conf
    salt-ssh -i "$Node_name" state.sls expand.install_minion || exit 1
}

function init_sys(){
    compute_uuid=$(salt "$Node_name" grains.get uuid | grep '-' | awk '{print $1}')
    echo "  uuid: $compute_uuid" >> ../install/pillar/compute_info.sls
}


function install_compute(){
    # 初始化用户、目录、免密...
    salt -E "compute" state.sls init
    # install nfs 挂载
    salt -E "compute" state.sls storage
    # 配置dns为manage01
    salt -E "compute" state.sls grbase.dns
    # 配置源、装gr-docker、dps、dc-compose
    salt -E "compute" state.sls docker.install
    # 安装calico
    salt -E "compute" state.sls network
    # 安装ercd-proxy
    salt -E "compute" state.sls etcd.proxy
    # 安装 node
    # 安装 kubelet
}

# 根据参数配置roster、检查目标机器的环境、写入compute.sls
run

Master_ip=$(grep "inet-ip" ../install/pillar/system_info.sls  | awk '{print$2}')
Node_name=$(cat /etc/salt/roster | tail -n 4 | head -1 | awk -F ':' '{print$1}')

# 检查minion
check_compute
# 安装salt-minion
install_minion
# 生成uuid
init_sys
# 安装计算节点
install_compute
