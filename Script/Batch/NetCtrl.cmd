@echo off
REM Author:Yuan
REM 
title Net Control
for /f %%d in ('"powershell (Get-Date).DayOfWeek.Value__"') do set week=%%d

if %week% lss 6 (
  if %time:~0,2% geq 8 (
    if %time:~0,2% leq 17 (
      goto working
    )
  )
) else (
  goto offwork
)

:working
netsh advfirewall firewall set rule name="Remote Desktop - User Mode (TCP-In)" new dir=in protocol=tcp remoteip=localsubnet action=allow
ping 127.0.0.1 -n 2 >nul
exit

:offwork
netsh advfirewall firewall set rule name="Remote Desktop - User Mode (TCP-In)" new dir=in protocol=tcp remoteip=any action=allow
ping 127.0.0.1 -n 2 >nul
exit