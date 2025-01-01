#!/system/bin/sh

echo -e "
┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ㅤBattery Statㅤㅤㅤㅤㅤㅤㅤㅤ‏ㅤSIMON
┃"

echo "┣ Setting permissions..."
set_permissions() {
    set_perm_recursive $MODPATH 0 0 0777 0755
    set_perm $MODPATH/service.sh 0 0 0755
    set_perm $MODPATH/battery.sh 0 0 0755
}
set_permissions
echo -e "┃\n┣ Setting permissions successfully..\n┃"

echo -e "┃\n┣ Checking for indexes file...\n┃"

indexes_file=$(find /data -type f -name "INT.INDEXES" -print -quit)

if [ -n "$indexes_file" ]; then
    echo "┃ indexes file found: $indexes_file"
else
    echo "┃┗ Error: indexes file not found"
    exit 1
fi

echo -e "┃\n┗ Initialization script completed successfully!\n"