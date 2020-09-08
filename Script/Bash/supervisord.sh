#!/bin/bash

ContainerID=`/usr/bin/docker ps | grep php:latest | awk -F " " '{print $1}'`
ContainerIDArray=(${ContainerID})

#echo ${ContainerIDArray[0]}
#echo ${#ContainerIDArray[*]}

CONTROL=(start restart status)

# show supervisord status & exit script
if [ "${1}" == "status" ];then
    for Container in ${ContainerIDArray[@]}
    do
        /usr/bin/docker exec ${Container} supervisorctl ${1}
    done
    exit 0
fi

# Arguments can't be null
if [[ -z "${1}" ]] || [[ -z "${2}" ]];then
    echo "Need more arguments!"
    exit 1
fi

# Check first parameter is in the "CONTROL" array or not.
if [[ ! "${CONTROL[@]}" =~ "${1}" ]];then
    echo "Incorrect Parameter!!"
    exit 1
fi

function shutdown_socket() {
    # get socket-server's pid then kill it . start socket-server manually later.
    socket_pid=`/usr/bin/docker exec ${1} ps aux | grep socket-server | awk -F " " '{print $1}'`
    /usr/bin/docker exec ${1} kill -9 ${socket_pid}
}

for Container in ${ContainerIDArray[@]}
do
    # if start all , that means we had started php container recently. so we can start up supervisord with config file
    if [[ "${1}" == "start" ]] && [[ "${2}" == "all" ]];then
        /usr/bin/docker exec ${Container} supervisord -c /etc/supervisord.conf
    elif [[ "${1}" == "restart" ]] && [[ "${2}" == "socket" ]];then
        shutdown_socket ${Container}
        /usr/bin/docker exec ${Container} supervisorctl start socket-server-swoole:socket-server-swoole_00
    elif [[ "${1}" == "restart" ]] && [[ "${2}" == "all" ]];then
        shutdown_socket ${Container}
        /usr/bin/docker exec ${Container} supervisorctl ${1} ${2}
    else
        /usr/bin/docker exec ${Container} supervisorctl ${1} ${2}
    fi
done
exit
