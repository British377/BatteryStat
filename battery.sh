#!/system/bin/sh

HTML_FILE="/data/adb/modules/BatteryStats/webroot/index.html"
TEMP_DATA_FILE="/data/adb/modules/BatteryStats/webroot/temp_data.json"

BATTERY_INFO_FILE="/sys/class/power_supply/battery/"
BATTERY_STATUS_FILE="$BATTERY_INFO_FILE/status"
BATTERY_VOLTAGE_FILE="$BATTERY_INFO_FILE/voltage_now"
BATTERY_CAPACITY_FILE="$BATTERY_INFO_FILE/capacity"
BATTERY_TEMP_FILE="$BATTERY_INFO_FILE/temp"
BATTERY_HEALTH_FILE="$BATTERY_INFO_FILE/health"
BATTERY_TECHNOLOGY_FILE="$BATTERY_INFO_FILE/technology"

LANGSYS=$(settings get system system_locales)

is_russian() {
  [[ "$LANGSYS" == *"en-RU"* || "$LANGSYS" == *"ru-"* ]]
}

lang=$(is_russian && echo "RU" || echo "EN")

get_device_info() {
    local device_model=$(su -c "getprop ro.product.model")
    local android_version=$(su -c "getprop ro.build.version.release")
    local manufacturer=$(su -c "getprop ro.product.manufacturer")
    local build_number=$(su -c "getprop ro.build.display.id")
    local user_apps=$(su -c "pm list packages -3" | wc -l)
    local system_apps=$(su -c "pm list packages -s" | wc -l)
    local total_apps=$((user_apps + system_apps))
    local selinux_status=$(su -c "getenforce")

    # Расширенная информация
    local cpu_abi=$(su -c "getprop ro.product.cpu.abi")
    local kernel_version=$(su -c "uname -r")
    local screen_density=$(su -c "getprop ro.sf.lcd_density")
    local screen_resolution=$(su -c "wm size" | cut -d' ' -f3)
    local total_ram=$(su -c "free -m" | awk '/Mem:/ {print $2}')
    local available_ram=$(su -c "free -m" | awk '/Mem:/ {print $4}')
    local internal_storage=$(su -c "df -h /data" | awk 'NR==2 {print $2}')
    local free_storage=$(su -c "df -h /data" | awk 'NR==2 {print $4}')
    local security_patch=$(su -c "getprop ro.build.version.security_patch")

    echo "<div class='device-info-container'>"
    echo "<div class='info-selector'>"
    echo "<button class='info-btn active' data-type='standard'>Стандартная информация</button>"
    echo "<button class='info-btn' data-type='extended'>Расширенная информация</button>"
    echo "</div>"
    
    # Стандартная информация
    echo "<div class='standard-info info-block active'>"
    echo "<h2>Информация об устройстве</h2>"
    echo "<p>Модель устройства: $device_model</p>"
    echo "<p>Производитель: $manufacturer</p>"
    echo "<p>Версия Android: $android_version</p>"
    echo "<p>Номер сборки: $build_number</p>"
    echo "<p>Количество пользовательских приложений: $user_apps</p>"
    echo "<p>Количество системных приложений: $system_apps</p>"
    echo "<p>Общее количество установленных приложений: $total_apps</p>"
    echo "<p>Статус SELinux: $selinux_status</p>"
    echo "</div>"

    # Расширенная информация
    echo "<div class='extended-info info-block'>"
    echo "<h2>Расширенная информация об устройстве</h2>"
    echo "<p>Архитектура CPU: $cpu_abi</p>"
    echo "<p>Версия ядра: $kernel_version</p>"
    echo "<p>Плотность экрана: ${screen_density}dpi</p>"
    echo "<p>Разрешение экрана: $screen_resolution</p>"
    echo "<p>Оперативная память: $total_ram МБ (доступно: $available_ram МБ)</p>"
    echo "<p>Внутреннее хранилище: $internal_storage (свободно: $free_storage)</p>"
    echo "<p>Патч безопасности: $security_patch</p>"
    echo "<p>Модель устройства: $device_model</p>"
    echo "<p>Производитель: $manufacturer</p>"
    echo "<p>Версия Android: $android_version</p>"
    echo "<p>Номер сборки: $build_number</p>"
    echo "<p>Статус SELinux: $selinux_status</p>"
    echo "</div>"
    echo "</div>"
}

get_battery_info_from_files() {
    local battery_level=$(su -c "cat $BATTERY_CAPACITY_FILE" 2>/dev/null || echo "N/A")
    local battery_status=$(su -c "cat $BATTERY_STATUS_FILE" 2>/dev/null || echo "N/A")
    local battery_voltage_raw=$(su -c "cat $BATTERY_VOLTAGE_FILE" 2>/dev/null || echo "N/A")
    local battery_health=$(su -c "cat $BATTERY_HEALTH_FILE" 2>/dev/null || echo "N/A")
    local battery_technology=$(su -c "cat $BATTERY_TECHNOLOGY_FILE" 2>/dev/null || echo "N/A")

    # Конвертация температуры батареи в Цельсии
    local battery_temperature=$(su -c "cat $BATTERY_TEMP_FILE" 2>/dev/null || echo "N/A")
    if [[ "$battery_temperature" != "N/A" ]]; then
        battery_temperature=$(echo "scale=1; $battery_temperature / 10" | bc)
    fi

    if [[ "$battery_voltage_raw" != "N/A" ]]; then
        battery_voltage=$(echo "scale=4; $battery_voltage_raw / 1000000" | bc)
    else
        battery_voltage="N/A"
    fi

    echo "$battery_level $battery_status $battery_voltage $battery_temperature $battery_health $battery_technology"
}


get_battery_info() {
    local battery_info=$(get_battery_info_from_files)

    # Проверка на корректность
    if [[ "$battery_info" == "N/A N/A N/A N/A N/A N/A" ]]; then
        echo "<h2>Ошибка получения информации о батарее</h2>"
        return
    fi

    # Извлечение информации
    read battery_level battery_status battery_voltage battery_temperature battery_health battery_technology <<< "$battery_info"

    # Получаем температуру ЦПУ
    local cpu_temp=$(su -c "cat /sys/class/thermal/thermal_zone0/temp")
    local cpu_temp_celsius=$(echo "scale=1; $cpu_temp/1000" | bc)
    local cpu_temp_fahrenheit=$(echo "scale=1; ($cpu_temp_celsius * 9/5) + 32" | bc)

    # Форматирование напряжения батареи с учетом статуса
    local raw_battery_voltage="${battery_voltage}V"
    if [[ "$battery_status" == "Charging" ]]; then
        raw_battery_voltage="+${raw_battery_voltage}"
    elif [[ "$battery_status" == "Discharging" ]]; then
        raw_battery_voltage="-${raw_battery_voltage}"
    fi

    # Конвертация температуры батареи в Фаренгейты
    local battery_temp_fahrenheit=$(echo "scale=1; ($battery_temperature * 9/5) + 32" | bc)

    echo "<h2>Информация о батарее</h2>"
    echo "<p>Уровень заряда батареи: $battery_level%</p>"
    echo "<p>Статус зарядки: $battery_status</p>"
    echo "<p>Напряжение батареи: ${raw_battery_voltage}</p>"
    echo "<p>Температура батареи: $battery_temperature°C / $battery_temp_fahrenheit°F</p>"
    echo "<p>Температура ЦПУ: $cpu_temp_celsius°C / $cpu_temp_fahrenheit°F</p>"
    echo "<p>Состояние батареи: $battery_health</p>"
    echo "<p>Технология батареи: $battery_technology</p>"
}

# Модифицируем collect_battery_temp_data
collect_battery_temp_data() {
    echo "[]" > "$TEMP_DATA_FILE"
    while true; do
        local battery_temp=$(su -c "dumpsys battery" | grep "temperature:" | awk -F':' '{print $2/10}')
        local timestamp=$(date +"%H:%M:%S")
        local current_data=$(cat "$TEMP_DATA_FILE")
        local new_data=$(echo "$current_data" | jq ". + [{\"time\": \"$timestamp\", \"temp\": ${battery_temp%.*}}]" 2>/dev/null)
        if [ $? -eq 0 ]; then
            # Оставляем данные только за последние 12 часов
            echo "$new_data" | jq 'if length > 720 then .[720:] else . end' > "$TEMP_DATA_FILE"
        fi
        sleep 60
    done
}

update_html() {
    local device_info=$(get_device_info)
    local battery_info=$(get_battery_info)
    local explanation_block=""

    if [[ "$lang" == "EN" ]]; then
        explanation_block="<h2>Explanation of Values</h2>
        <h3>Charging Status:</h3>
        <ul>
            <li>Charging: The battery is currently charging.</li>
            <li>Discharging: The battery is discharging.</li>
            <li>Full: The battery is fully charged.</li>
            <li>Not charging: The battery is not receiving a charge.</li>
            <li>Unknown: Charging status cannot be determined.</li>
        </ul>
        <h3>Battery Condition:</h3>
        <ul>
            <li>Good: The battery is in good condition.</li>
            <li>Overheat: The battery is overheated.</li>
            <li>Dead: The battery is drained.</li>
            <li>Unknown: The battery condition cannot be determined.</li>
        </ul>
        <h3>Battery Technologies:</h3>
        <ul>
            <li>Li-ion: Widely used technology.</li>
            <li>Li-poly: Lighter and more flexible technology.</li>
            <li>NiMH: Used in some devices.</li>
            <li>NiCd: Older technology, usually not used.</li>
        </ul>
        <h3>SELinux:</h3>
        <p>SELinux (Security-Enhanced Linux) is a security mechanism that provides access control to system resources. The SELinux status can be:
            <ul>
                <li><strong>Enforcing:</strong> SELinux policies are enforced.</li>
                <li><strong>Permissive:</strong> SELinux policies are applied but do not block actions.</li>
                <li><strong>Disabled:</strong> SELinux policies are disabled.</li>
            </ul>
        </p>"
    else
        explanation_block="<h2>Объяснение значений</h2>
        <h3>Статус зарядки:</h3>
        <ul>
            <li>Charging - Зарядка: Батарея находится в процессе зарядки.</li>
            <li>Discharging - Разрядка: Батарея разряжается.</li>
            <li>Full - Полностью заряжен: Батарея полностью заряжена.</li>
            <li>Not charging - Не заряжается: Батарея не получает заряд.</li>
            <li>Unknown - Неизвестный статус: Статус зарядки не может быть определён.</li>
        </ul>
        <h3>Состояние батареи:</h3>
        <ul>
            <li>Good - Хорошее состояние: Батарея в хорошем состоянии.</li>
            <li>Overheat - Перегрев: Батарея перегрета.</li>
            <li>Dead - Разряжен: Батарея разряжена.</li>
            <li>Unknown - Неизвестное состояние: Состояние батареи не может быть определено.</li>
        </ul>
        <h3>Технологии батареи:</h3>
        <ul>
            <li>Li-ion - Литий-ионная батарея: Широко используемая технология.</li>
            <li>Li-poly - Литий-полимерная батарея: Более легкая и гибкая технология.</li>
            <li>NiMH - Никель-металлгидридная батарея: Используется в некоторых устройствах.</li>
            <li>NiCd - Никель-кадмиевая батарея: Старая технология, обычно не используется.</li>
        </ul>
        <h3>SELinux:</h3>
        <p>SELinux (Security-Enhanced Linux) — это механизм безопасности, который предоставляет контроль доступа к ресурсам системы. Статус SELinux может быть:
            <ul>
                <li><strong>Enforcing:</strong> Политики SELinux применяются.</li>
                <li><strong>Permissive:</strong> Политики SELinux применяются, но не блокируют действия.</li>
                <li><strong>Disabled:</strong> Политики SELinux отключены.</li>
            </ul>
        </p>"
    fi

    cat > "$HTML_FILE" <<EOF
<!DOCTYPE html>
<html lang="$lang">
<head>
    <title>Информация об устройстве</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="chart.js"></script>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="wrapper">
        <div class="container">
            <div class="column">
                $device_info
                $battery_info
            </div>
            <div class="column">
                <h2>График температуры батареи</h2>
                <div class="time-selector">
                    <label for="timeRange">Временной промежуток:</label>
                    <select id="timeRange">
                        <option value="10">10 минут</option>
                        <option value="30">30 минут</option>
                        <option value="60">1 час</option>
                        <option value="120">2 часа</option>
                        <option value="360">6 часов</option>
                        <option value="720">12 часов</option>
                    </select>
                </div>
                <div class="chart-container">
                    <canvas id="batteryTempChart"></canvas>
                </div>
            </div>
        </div>
        <div class="column">
            $explanation_block
        </div>
    </div>
    
    <div class="reload-button" onclick="location.reload()">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M23 4v6h-6"></path>
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
        </svg>
    </div>
</body>
    <script src="schedule.js"></script>
</html>
EOF
}

cycle_html() {
    while true; do
        update_html
        sleep 1
    done
}

collect_battery_temp_data &
cycle_html &