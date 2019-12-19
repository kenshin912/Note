@echo off
title Activation Microsoft Windows and Microsoft Office
color 0A

set KMS_Server=kms.03k.org
set OfficePath=%HOMEDRIVE%\Program Files\Microsoft Office
set Win10Pro_Key=W269N-WFGWX-YVC9B-4J6C9-T83GX
set Win10Ent_Key=NPPR9-FWDCX-D2C8J-H872K-2YT43
set Win10Edu_Key=NW6C2-QMPVW-D7KKK-3GKT6-VCFB2
set Win10ProN_Key=MH37W-N47XK-V7XM9-C7227-GCQG9
set Win10EntN_Key=DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4
set Win10EduN_Key=2WH4N-8QGBV-H22JP-CT43Q-MDWWJ

REM wmic os get Caption /value
for /f "delims=>= tokens=2" %%i in ('wmic os get caption ^/value') do (set Version=%%i)
if "%Version%"=="Microsoft Windows 10 Pro" (
    set Current_Key=%Win10Pro_Key%
    call :ActivationWindows
)

:ActivationWindows
slmgr /skms %KMS_Server%
slmgr /ipk %Current_Key%
slmgr /ato

:ActivationOffice
if not exist %OfficePath% goto NoOffice
cd "C:\Program Files\Microsoft Office\Office1*"
cscript ospp.vbs /sethst:%KMS_Server%
cscript ospp.vbs /act

:NoOffice
mshta vbscript:msgbox("There's no Microsoft Office in your Computer",16,"Application Error")(window.close)
exit