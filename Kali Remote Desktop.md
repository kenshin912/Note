**On Kali**

> Install xrdp

```
$ sudo apt-get install xrdp -y
```

> Install vnc4server

```
$ sudo apt-get install vnc4server -y
```

> Edit xrdp config file

```
$ sudo vim /etc/xrdp/xrdp.ini
```
> ==max_bpp = 32==

To
> ==max_bpp = 16==

If u are using x-window , logoff and try again the follow code.

```
$ sudo service xrdp start
$ sudo service xrdp-sesman start
$ sudo vncserver
```

**On Windows OS**

Open mstsc & input kali server IP

Choose Xvnc & input username , password .