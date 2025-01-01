#!/system/bin/sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 10
done

sleep 10

su -c "bash /data/adb/modules/BatteryStats/battery.sh" &

exit 0