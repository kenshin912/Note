@echo off
REM AUTHOR:YUAN
REM Controll Adapter status via WLAN service status.
sc query Wlansvc >nul
if errorlevel 1 (
  goto tips
)

for /f "tokens=4" %%i in ('sc qc Wlansvc ^| findstr /i "start_type"') do (
  if /i "%%i"=="auto_start" (
    sc config Wlansvc start= demand
  )
  if /i "%%i"=="disabled" (
    sc config Wlansvc start= demand
  )
)

for /f "tokens=4" %%i in ('sc query Wlansvc ^|findstr /i "state.*:"') do (
  if /i "%%i"=="stopped" (
    echo "Starting WIFI..."
    sc start Wlansvc >nul
    netsh interface set interface "Local Area Connection" disabled
    netsh interface set interface "Wireless Network Connection" enabled
  )else (
    echo "Closing WIFI..."
    sc stop Wlansvc >nul
    netsh interface set interface "Wireless Network Connection" disabled
    netsh interface set interface "Local Area Connection" enabled
  )
)
exit
:tips
mshta vbscript:msgbox("WLAN·þÎñÎ´×¢²á!",16,"Error")(window.close)
exit