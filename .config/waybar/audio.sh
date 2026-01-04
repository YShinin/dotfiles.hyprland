#!/bin/bash

THEME="$HOME/.config/rofi/menu.rasi"

# Функция получения списка: Сначала Описание, потом ID (через разделитель ¦)
get_devices() {
    pactl list sinks | grep -E "Name:|Description:" | \
    sed 'N;s/\n/ /' | \
    sed 's/Name: //;s/Description: //' | \
    # Меняем местами: $2..$NF (Описание) ставим вперед, $1 (ID) назад
    awk -F ' ' '{id=$1; $1=""; print substr($0,2)}'
}

# 1. Показываем меню
# Теперь в Rofi вы увидите: "Starship/Matisse HD Audio... ¦ alsa_output..."
SELECTED=$(get_devices | rofi -dmenu -i -p "Аудиоустройство" -theme "$THEME")

if [ -z "$SELECTED" ]; then
    exit 0
fi

# 2. Вытаскиваем ID (теперь он во второй части, после ¦)
# awk -F ' ¦ ' делит строку по разделителю " ¦ "
DEVICE_NAME=$(echo "$SELECTED" | awk -F ' ¦ ' '{print $2}')
DEVICE_DESC=$(echo "$SELECTED" | awk -F ' ¦ ' '{print $1}')

# 3. Переключаем
pactl set-default-sink "$DEVICE_NAME"

# 4. Переносим звук
pactl list short sink-inputs | cut -f1 | while read stream; do
    pactl move-sink-input "$stream" "$DEVICE_NAME"
done

notify-send "Audio" "Звук переключен на:\n$DEVICE_DESC" -i audio-speakers
