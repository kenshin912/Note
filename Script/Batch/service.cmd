@echo off
REM Author:Yuan
REM DESC: Use 'cat' protocol, open winscp or mstsc & input username/password automatically

for /f "tokens=1,2,3,4,5 delims=>_" %%i in (%1) do (
  set "type=%%i"
  set "ip=%%j"
  set "username=%%k"
  set "pass=%%l"
  set "port=%%m"
)

for /f "delims=" %%n in ('echo %pass% ^| base64 -d') do set password=%%n

REM 10/29/2019
REM URLs can only be sent over the Internet using the ASCII character-set.
REM URL encoding replaces unsafe ASCII characters with a "%" followed by two hexadecimal digits.
REM URLs cannot contain spaces , URL encoding normally replaces "%" with "%25"

REM So. When "%" character in %pass% , it will replaced to "%25" by URL encoding.
REM That is not the problem with service.cmd but URL encoding cause.

if /i "%type:~6,3%"=="Lin" goto winscp
if /i "%type:~6,3%"=="Win" goto mstsc
if /i "%type:~6,3%"=="ftp" goto ftp
echo "That's impossible!"

:winscp
REM Because "&" is special charset in variable %pass% , so we need to use "".
start %~dp0WinSCP.exe %username%:"%password%"@%ip%:%port:~0,-1%
start %~dp0putty.exe -ssh -l %username% -pw "%password%" -P %port:~0,-1% %ip%
echo %password%|clip
exit

:mstsc
(
echo screen mode id:i:1
echo desktopwidth:i:1440
echo desktopheight:i:900
echo session bpp:i:32
echo winposstr:s:0,1,227,42,1683,980
echo compression:i:1
echo keyboardhook:i:2
echo audiocapturemode:i:0
echo videoplaybackmode:i:1
echo connection type:i:6
echo displayconnectionbar:i:1
echo disable wallpaper:i:0
echo allow font smoothing:i:1
echo allow desktop composition:i:1
echo disable full window drag:i:0
echo disable menu anims:i:0
echo disable themes:i:0
echo disable cursor setting:i:0
echo bitmapcachepersistenable:i:1
echo full address:s:%ip%
echo audiomode:i:0
echo redirectprinters:i:0
echo redirectcomports:i:0
echo redirectsmartcards:i:1
echo redirectclipboard:i:1
echo redirectposdevices:i:0
echo redirectdirectx:i:1
echo drivestoredirect:s:*
echo autoreconnection enabled:i:1
echo username:s:%username%
echo domain:s:
echo authentication level:i:0
echo prompt for credentials:i:0
echo negotiate security layer:i:1
echo remoteapplicationmode:i:0
echo alternate shell:s:
echo shell working directory:s:
echo gatewayhostname:s:
echo gatewayusagemethod:i:4
echo gatewaycredentialssource:i:4
echo gatewayprofileusagemethod:i:0
echo promptcredentialonce:i:1
echo use redirection server name:i:0
echo use multimon:i:0
) >%~dp0Luna.rdp 2>nul
start %windir%\system32\mstsc.exe %~dp0Luna.rdp
echo %password%|clip
exit

:ftp
start %~dp0WinSCP.exe ftp://%username%:"%password%"@%ip%:%port:~0,-1%
exit