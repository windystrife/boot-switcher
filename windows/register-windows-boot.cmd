@echo off
rem Re-assert Windows Boot Manager in the UEFI firmware boot menu (for flaky
rem boards that drop/hide it). Safe: it only adds {bootmgr} to the firmware
rem boot order (at the end, so it does not become the default).
bcdedit /set "{fwbootmgr}" displayorder "{bootmgr}" /addlast
