#!/bin/bash

# Миграция для добавления serial_id к таблице actions
# Этот скрипт применяет миграцию 1.2.2

echo "Применение миграции 1.2.2 для добавления serial_id к таблице actions..."

# Переходим в директорию с migration tool
cd ton-index-worker/ton-index-postgres

# Собираем migration tool
echo "Сборка migration tool..."
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make migrate

# Применяем миграцию
echo "Применение миграции..."
./migrate --pg "$DATABASE_URL"

echo "Миграция завершена!"
echo ""
echo "Теперь таблица actions имеет поле serial_id, которое автоматически заполняется"
echo "последовательными значениями на основе времени завершения действий."
echo ""
echo "Все новые действия будут автоматически получать уникальный serial_id."
echo "API теперь использует serial_id для сортировки по умолчанию." 