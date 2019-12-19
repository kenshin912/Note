@echo off
cd %~dp0
set self=%~dp0service.cmd
reg add HKCR\cat /ve /t REG_SZ /d "URL: Cat Application Protocol" >nul
reg add HKCR\cat /v "URL Protocol" /t REG_SZ /d "" >nul
reg add HKCR\cat\DefaultIcon /ve /t REG_SZ /d "%self%,1" >nul
reg add HKCR\cat\shell\open\command /ve /t REG_SZ /d "\"%self%\" \"%%^1\"" >nul
exit