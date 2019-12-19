@echo off
color 0A
title Activation Windows Server 2019 DataCenter

set key="WMDGN-G9PQG-XVVXX-R3X43-63DFG"
set kms=kms.03k.org

slmgr /ipk %key%
slmgr /skms %kms%
slmgr /ato
exit