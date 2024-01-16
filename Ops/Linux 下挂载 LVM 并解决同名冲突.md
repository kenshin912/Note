# Linux 下挂载 LVM 并解决同名冲突

## 查看 VG

```bash
$ sudo vgs -v

Finding all volume groups
Finding volume group "VolGroup00"
Finding volume group "VolGroup00"
VG Attr Ext #PV #LV #SN VSize VFree VG UUID
VolGroup00 wz--n- 32.00M 1 2 0 136.62G 0 dcHa6G-abU2-Xfq8-EPBm-jBLj-sf18-O5uH0U
VolGroup00 wz--n- 32.00M 1 2 0 136.62G 0 OF8g7h-PQJB-9D9z-yPxn-1kfY-Advq-YbNHJ9
```

## 修改 UUID

```bash
$ sudo vgrename OF8g7h-PQJB-9D9z-yPxn-1kfY-Advq-YbNHJ9 VolGroup01

Volume group "VolGroup00" still has active LVs
```

修改成功后再次查看 LV

```bash
$ sudo lvscan
inactive '/dev/VolGroup01/LogVol00' [130.84 GB] inherit
inactive '/dev/VolGroup01/LogVol01' [5.78 GB] inherit
ACTIVE '/dev/VolGroup00/LogVol00' [130.84 GB] inherit
ACTIVE '/dev/VolGroup00/LogVol01' [5.78 GB] inherit
```

## 激活改名后的 VG

可以看到最新修改的 VolGroup01 是 inactive 状态. 那么我们加载 VolGroup01

```bash
$ sudo vgchange -ay /dev/VolGroup01

2 logical volume(s) in volume group "VolGroup01" now active
```

## Mount

最后 mount 即可.

```bash
$ sudo mount /dev/VolGroup01/LogVol00 /mnt/
```
