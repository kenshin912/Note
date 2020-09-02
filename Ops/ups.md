# UPS

不要将网关接入 UPS !  
不要将网关接入 UPS !  
不要将网关接入 UPS !  

通过检测网关是否可以 ping 通来判断电力是否正常.  
每次 ping 3 个数据包到网关 , ping 5 次 , 间隔 10 秒 , 失败后 $? 为 1 , 进行累加.  
如果最终 $result > 4 , 即 5 次 ping 的结果都不通 , 那么认为电力 Failed , 600 秒后执行关机.  
留 600 秒是为了防止内网故障导致误关机 , 留出进服务器 kill 掉脚本进程的时间.  

```bash
#!/bin/bash

Gateway=192.168.2.187
Count=3
delay_time=10
result=0

for (( i=0;i<5;i++ ));do
    ping -c ${Count} ${Gateway} > /dev/null
    result=$(expr ${result} + $?)
    sleep ${delay_time}
done

now=`date '+%Y-%m-%d %H:%M:%S'`

if [ ${result} -gt 4 ];then
    echo "${now}, maybe electricity down , poweroff in 10 min..." >> /var/log/ups.log
    sleep 600 # Wait 10min , if network damaged but electricity still fine , we could have enough time to stop this script.
    /sbin/poweroff
else
    echo "${now}, everything OK" >> /var/log/ups.log
fi

exit
```

```bash
*/30 * * * * /root/ups.sh > /dev/null 2&>1
```
