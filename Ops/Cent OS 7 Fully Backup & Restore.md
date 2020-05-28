# Cent OS 7 Fully Backup & Restore

## Backup Source Server

```bash
su root
cd /
tar cvpzf backup.tgz / --exclude=/proc --exclude=/lost+found --exclude=/backup.tgz  --exclude=/mnt --exclude=/sys --exclude=/media --exclude=/tmp
```

## Backup "fstab" & "grub.cfg" on Destnation Server

```bash
cp /etc/fstab /
cp /boot/grub2/grub.cfg /
```

## Transfer "backup.tar" to Destnation Server

## Restore files on Destnation Server

```bash
su root
cd /
tar xvpfz backup.tgz -C /
cp /fstab /etc/
cp /grub.cfg /boot/grub2/
restorecon -Rv /
shutdown -r
```
