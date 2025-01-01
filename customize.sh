#!/system/bin/sh

SYSTEM_BIN="$MODPATH/system/bin"

echo -e "
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ㅤLibrary Permission Setupㅤㅤㅤㅤ‏ㅤ  SIMON
┃"

su -c "chmod 755 /data/adb/modules"
su -c "cp -r $MODPATH/nginx /data/local/"
su -c "chmod 755 /data/local/nginx"

set_permissions() {
    set_perm_recursive $MODPATH 0 0 0755 0777
    set_perm $SYSTEM_BIN/awk 0 0 0777
    set_perm $SYSTEM_BIN/bash 0 0 0777
    set_perm $SYSTEM_BIN/gawk 0 0 0777
    set_perm $SYSTEM_BIN/gawkbug 0 0 0777
    set_perm $SYSTEM_BIN/jq 0 0 0777
    set_perm $SYSTEM_BIN/python 0 0 0777
    set_perm $SYSTEM_BIN/python-config 0 0 0777
    set_perm $SYSTEM_BIN/python3 0 0 0777
    set_perm $SYSTEM_BIN/python3-config 0 0 0777
    set_perm $SYSTEM_BIN/python3.12 0 0 0777
    set_perm $SYSTEM_BIN/python3.12-config 0 0 0777
    set_perm $SYSTEM_BIN/redsocks 0 0 0777
    set_perm $SYSTEM_BIN/nginx 0 0 0777
}
set_permissions

echo -e "┃\n┗ The permissions have been successfully set for all required files" && printf "\n\n\n";