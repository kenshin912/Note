@echo off
title SHA1 Calculator
color 0A
powershell -command "Get-FileHash %1 -Algorithm MD5| Format-List"
pause
exit