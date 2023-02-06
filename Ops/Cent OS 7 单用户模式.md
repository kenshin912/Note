## Cent OS 7 单用户模式

开机后 , 在 "CentOS Linux (内核版本号) 7 (Core)" 与 " CentOS Linux (0-rescue-xxxxxx) 7 (Core) " 页面 , 选择第一个 , 按下 "E" 键进入 GRUB 页面.

找到 "linux16" 开头的那一行 , 定位到 "ro" 修改为 "rw" 并在 "rw" 后添加 "init=/sysroot/bin/sh"

按下 "Ctrl" + "X" 

输入以下命令:

```bash
# chroot /sysroot/
# passwd root
# touch /.autorelabel
```

重启