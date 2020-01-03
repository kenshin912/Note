# Kali Remote Desktop

## On Kali

> Install xrdp

```bash
sudo apt-get install xrdp -y
```

> Install vnc4server

```bash
sudo apt-get install vnc4server -y
```

> Edit xrdp config file

```bash
sudo vim /etc/xrdp/xrdp.ini
```

> ==max_bpp = 32==

To
> ==max_bpp = 16==

If u are using x-window , logoff and try again the following code.

```bash
sudo service xrdp start
sudo service xrdp-sesman start
sudo vncserver
```

## On Windows OS

Open mstsc & input kali server IP

Choose Xvnc & input username , password .