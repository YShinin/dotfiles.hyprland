#!/bin/bash

THEME="$HOME/.config/rofi/menu.rasi"

# Инициализируем массивы
ids=()
descriptions=()

# Читаем список устройств
# Логика та же: берем Name и Description, склеиваем в одну строку
while read -r line; do
    # Первое слово в строке — это ID
    id=$(echo "$line" | awk '{print $1}')
    
    # Всё остальное (начиная со 2-го символа после первого пробела) — это Описание
    # Используем awk, чтобы аккуратно отрезать первое слово
    desc=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
    
    # Добавляем в массивы
    ids+=("$id")
    descriptions+=("$desc")
    
done < <(pactl list sinks | grep -E "Name:|Description:" | sed 'N;s/\n/ /' | sed 's/Name: //;s/Description: //')

# 1. Показываем меню
# printf печатает описания с новой строки.
# -format i говорит Rofi: "Верни мне номер выбранной строки (0, 1, 2...), а не текст"
SELECTED_INDEX=$(printf "%s\n" "${descriptions[@]}" | rofi -dmenu -i -format i -p "Аудиоустройство" -theme "$THEME")

# Если нажали Esc (переменная пустая), выходим
if [ -z "$SELECTED_INDEX" ]; then
    exit 0
fi

# 2. Вытаскиваем данные по индексу
# Берем ID из массива ids по номеру, который вернул Rofi
DEVICE_NAME="${ids[$SELECTED_INDEX]}"
# Берем Описание для уведомления
DEVICE_DESC="${descriptions[$SELECTED_INDEX]}"

# 3. Переключаем дефолтное устройство
pactl set-default-sink "$DEVICE_NAME"

# 4. Переносим звук всех активных приложений на новое устройство
pactl list short sink-inputs | cut -f1 | while read stream; do
    pactl move-sink-input "$stream" "$DEVICE_NAME"
done

# Уведомление
notify-send "Audio" "Звук переключен на:\n$DEVICE_DESC" -i audio-speakers
