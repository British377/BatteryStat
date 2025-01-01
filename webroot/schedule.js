    let chart;
    let timeRange = 60; // По умолчанию 1 час
    // Добавьте в начало файла после объявления переменных
    let activeInfoType = localStorage.getItem('activeInfoType') || 'standard';
    
    // Функция инициализации графика
    function initChart(initialData) {
        const ctx = document.getElementById('batteryTempChart').getContext('2d');
        chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Температура батареи (°C)',
                    data: [],
                    borderColor: 'rgb(75, 192, 192)',
                    tension: 0.1,
                    fill: false
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: false,
                        title: {
                            display: true,
                            text: 'Температура (°C)',
                            font: {
                                size: 14
                            }
                        },
                        ticks: {
                            font: {
                                size: 12
                            }
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Время',
                            font: {
                                size: 14
                            }
                        },
                        ticks: {
                            font: {
                                size: 12
                            }
                        }
                    }
                },
                plugins: {
                    legend: {
                        position: 'top',
                        labels: {
                            font: {
                                size: 14
                            }
                        }
                    }
                }
            }
        });
        updateChartData(initialData);
    }
    // Функция обновления данных графика
    function updateChartData(data) {
        if (!chart) return;
        
        // Проверяем, являются ли данные начальными
        if (data.length === 1 && data[0].time === 0) {
            chart.data.labels = [];
            chart.data.datasets[0].data = [];
            chart.update('none');
            return;
        }
    
        // Получаем текущее время
        const now = new Date();
        // Фильтруем данные по выбранному временному промежутку
        const filteredData = data.filter(item => {
            try {
                const itemTime = new Date();
                if (typeof item.time === 'string' && item.time.includes(':')) {
                    const [hours, minutes, seconds] = item.time.split(':');
                    itemTime.setHours(hours, minutes, seconds);
                    const diffInMinutes = (now - itemTime) / (1000 * 60);
                    return diffInMinutes <= timeRange;
                }
                return false;
            } catch (error) {
                console.error('Error processing time:', error);
                return false;
            }
        });
    
        chart.data.labels = filteredData.map(item => item.time);
        chart.data.datasets[0].data = filteredData.map(item => item.temp);
        
        chart.update('none');
    }
    // Функция получения новых данных температуры
    async function fetchTempData() {
        try {
            const response = await fetch('temp_data.json');
            const data = await response.json();
            updateChartData(data);
        } catch (error) {
            console.error('Ошибка получения данных температуры:', error);
        }
    }
    // Модифицируйте функцию updateDeviceInfo
    async function updateDeviceInfo() {
        try {
            const response = await fetch(window.location.href);
            const html = await response.text();
            const parser = new DOMParser();
            const newDoc = parser.parseFromString(html, 'text/html');
            
            // Обновляем информацию
            const deviceInfoContainer = document.querySelector('.device-info-container');
            const newDeviceInfoContainer = newDoc.querySelector('.device-info-container');
            
            if (deviceInfoContainer && newDeviceInfoContainer) {
                deviceInfoContainer.innerHTML = newDeviceInfoContainer.innerHTML;
                
                // Применяем сохраненное состояние
                const buttons = deviceInfoContainer.querySelectorAll('.info-btn');
                const blocks = deviceInfoContainer.querySelectorAll('.info-block');
                
                buttons.forEach(btn => {
                    if (btn.dataset.type === activeInfoType) {
                        btn.classList.add('active');
                    } else {
                        btn.classList.remove('active');
                    }
                });
    
                blocks.forEach(block => {
                    if (block.classList.contains(`${activeInfoType}-info`)) {
                        block.classList.add('active');
                    } else {
                        block.classList.remove('active');
                    }
                });
                
                // Переподключаем обработчики событий
                attachInfoButtonListeners();
            }
        } catch (error) {
            console.error('Ошибка обновления информации:', error);
        }
    }
    
    // Модифицируйте функцию attachInfoButtonListeners
    function attachInfoButtonListeners() {
        const infoButtons = document.querySelectorAll('.info-btn');
        const infoBlocks = document.querySelectorAll('.info-block');
    
        // Установка начального состояния
        infoButtons.forEach(btn => {
            if (btn.dataset.type === activeInfoType) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });
    
        infoBlocks.forEach(block => {
            if (block.classList.contains(`${activeInfoType}-info`)) {
                block.classList.add('active');
            } else {
                block.classList.remove('active');
            }
        });
    
        infoButtons.forEach(button => {
            button.addEventListener('click', function() {
                const type = this.dataset.type;
                activeInfoType = type;
                localStorage.setItem('activeInfoType', type);
                
                infoButtons.forEach(btn => btn.classList.remove('active'));
                this.classList.add('active');
                
                infoBlocks.forEach(block => {
                    block.classList.remove('active');
                    if (block.classList.contains(`${type}-info`)) {
                        block.classList.add('active');
                    }
                });
            });
        });
    }

    // Инициализация графика при загрузке страницы
    const initialData = [{time: 0, temp: 0}];
    initChart(initialData);
    // Добавьте после инициализации графика
    document.getElementById('timeRange').addEventListener('change', function(e) {
        timeRange = parseInt(e.target.value);
        fetchTempData();
    });
    // Обновление данных температуры каждую минуту
    setInterval(fetchTempData, 1000);
    // Обновление общей информации динамически
    setInterval(updateDeviceInfo, 1000);
    // Отключаем автоматическое обновление страницы по кнопке
    document.querySelector('.reload-button').onclick = function(e) {
        e.preventDefault();
        updateDeviceInfo();
    };
    
    // Добавьте после существующего кода
    document.addEventListener('DOMContentLoaded', function() {
        const infoButtons = document.querySelectorAll('.info-btn');
        const infoBlocks = document.querySelectorAll('.info-block');
    
        infoButtons.forEach(button => {
            button.addEventListener('click', function() {
                const type = this.dataset.type;
                
                // Обновляем активную кнопку
                infoButtons.forEach(btn => btn.classList.remove('active'));
                this.classList.add('active');
                
                // Показываем соответствующий блок информации
                infoBlocks.forEach(block => {
                    block.classList.remove('active');
                    if (block.classList.contains(`${type}-info`)) {
                        block.classList.add('active');
                    }
                });
            });
        });
    });