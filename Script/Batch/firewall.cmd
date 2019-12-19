@echo off
REM Author:Yuan
REM Control remote ip setting in rule of Remote Desktop on Windows Firewall.
REM Need Administrator privileges.

fltmc >nul 2>&1 && (
  call :setting
) || (
  call :access_denied
)

:access_denied
mshta vbscript:msgbox("Administrator privileges require!",16,"Access Denied")(window.close)
exit

:setting
echo 1.RemoteIP=Any    2.RemoteIP=LocalSubnet
set /p var=INPUT:
if "%var%"=="1" (
  netsh advfirewall firewall set rule name="Remote Desktop - User Mode (TCP-In)" new dir=in protocol=tcp remoteip=any action=allow
)

if "%var%"=="2" (
  netsh advfirewall firewall set rule name="Remote Desktop - User Mode (TCP-In)" new dir=in protocol=tcp remoteip=localsubnet action=allow
)
ping 127.0.0.1 -n 2 >nul
exit