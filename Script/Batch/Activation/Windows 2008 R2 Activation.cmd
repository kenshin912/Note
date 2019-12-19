@echo off
color 0A
title Activation Windows 2008 R2 , Code by Kenshin.

set KEY="489J6-VHDMP-X63PK-3K798-CPX3Y"
set KMS_Server=kms.03k.org

slmgr /skms %KMS_Server%
slmgr /ipk %KEY%
slmgr /ato