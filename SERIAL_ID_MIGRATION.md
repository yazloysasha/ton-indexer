# Миграция Serial ID для Actions

## Описание

Эта миграция добавляет уникальное поле `serial_id` к таблице `actions`, которое обеспечивает последовательную сортировку действий по времени их завершения.

## Что изменилось

### База данных

- Добавлена PostgreSQL sequence `action_serial_id_seq`
- Добавлено поле `serial_id BIGINT NOT NULL UNIQUE` в таблицу `actions`
- Создан уникальный индекс `actions_serial_id_idx`
- Все существующие записи получили serial_id через sequence

### Python код (indexer)

- Обновлена модель `Action` в `indexer/indexer/core/database.py`
- Добавлено поле `serial_id` с автоматическим заполнением через `server_default`
- Обновлен метод `to_dict()` для включения `serial_id`

### Go код (API)

- Обновлены структуры `Action`, `RawAction`, `ActionRow` во всех файлах
- Обновлены SQL запросы для включения `serial_id`
- Изменена логика сортировки: по умолчанию сортировка по `serial_id` DESC
- Обновлены функции парсинга для обработки `serial_id`

## Преимущества

1. **Последовательная сортировка**: Actions теперь имеют строгую временную последовательность
2. **Уникальность**: Каждое действие имеет уникальный ID
3. **Производительность**: Сортировка по одному BIGINT быстрее чем по нескольким полям
4. **Удобство**: Простая пагинация и сортировка для клиентов API

## Применение миграции

1. Установите переменную окружения `DATABASE_URL`
2. Запустите скрипт миграции:
   ```bash
   ./migrate_serial_id.sh
   ```

## API Changes

### Response

Все действия теперь включают поле `serial_id`:

```json
{
  "serial_id": "123456789",
  "trace_id": "...",
  "action_id": "...",
  ...
}
```

### Сортировка

По умолчанию все действия сортируются по `serial_id` DESC (новые первые).
Сортировка по времени (`order_by_now`) по-прежнему работает через параметры времени.

### Новый параметр include_transactions

Добавлен новый параметр `include_transactions` в API действий:

```bash
# Получить действия с полными данными транзакций
GET /api/v3/actions?include_transactions=true

# Получить действия с аккаунтами и транзакциями
GET /api/v3/actions?include_accounts=true&include_transactions=true
```

Когда `include_transactions=true`, каждое действие будет содержать массив `transaction_details` с полной информацией о связанных транзакциях:

```json
{
  "serial_id": "123456789",
  "trace_id": "...",
  "action_id": "...",
  "type": "jetton_transfer",
  "transactions": ["hash1", "hash2"],
  "transaction_details": [
    {
      "hash": "hash1",
      "account": "...",
      "lt": "...",
      "now": 1234567890,
      "description": { ... },
      "in_msg": { ... },
      "out_msgs": [ ... ]
    },
    {
      "hash": "hash2",
      "account": "...",
      "lt": "...",
      "now": 1234567891,
      "description": { ... },
      "in_msg": { ... },
      "out_msgs": [ ... ]
    }
  ]
}
```

## Обратная совместимость

- Все существующие API endpoints работают без изменений
- Добавлено новое поле в ответах API
- Изменена только логика сортировки по умолчанию
