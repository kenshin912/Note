### Ubuntu 20.04 LTS 根目录扩容指南

#### 扩容前

<img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811111409848.png" alt="image-20220811111409848" style="zoom:80%;" />



修改 Vmware ESXi 中该磁盘的大小为 100GiB , 重启该服务器.



#### 扩容

*   查看当前 LVM 卷情况

    >   sudo vgdisplay

​		**Free PE / Size   0/0**

​		目前 Free PE Size 显示无可用磁盘空间



*   对新扩容的 50GiB 空间进行分区操作.

    首先确认系统盘 , 一般是 `/dev/sda`

    执行命令 : `sudo fdisk /dev/sda`

    显示 GPT 容量差异 , 执行写入命令: `write`

    <img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811112146650.png" alt="image-20220811112146650" style="zoom:80%;" />

​		

​		重新执行格式化命令: `sudo fdisk /dev/sda`

​		新建分区: `n` , 3 次回车.

​		查看新分区: `p`

​		保存并退出: `w`

​		<img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811112440357.png" alt="image-20220811112440357" style="zoom:70%;" />

​		

​		查看分区情况: `sudo fdisk -l`

​		<img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811112830364.png" alt="image-20220811112830364" style="zoom:70%;" />

​		

​		新分区格式化: `sudo mkfs.ext4 /dev/sda4` , 注意 , 以实际生成的分区来更改命令.

​		<img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811113036877.png" alt="image-20220811113036877" style="zoom:80%;" />



​		生成 LVM : `sudo pvcreate /dev/sda4`

​		将新的 LVM 卷添加到卷组: `sudo vgextend ubuntu-vg /dev/sda4`		

​		<img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811113210864.png" alt="image-20220811113210864" style="zoom:80%;" />



​		再次查看 LVM 卷组: `sudo vgdisplay`

​		<img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811113429134.png" alt="image-20220811113429134" style="zoom:80%;" />



​		对磁盘进行扩容: `sudo lvresize -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv`

​		刷新分区: `sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv`

​		<img src="/Users/yuanyuan/Library/Application Support/typora-user-images/image-20220811113822784.png" alt="image-20220811113822784" style="zoom:60%;" />		