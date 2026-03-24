# Когортный и RFM анализ клиентов Dodo Pizza

## Описание проекта

Провести когортный анализ LTV, ARPU и ARPPU, а также RFM сегментацию клиентов Dodo Pizza для оценки ценности пользователей, их поведения и активности с целью выявления ключевых сегментов, повышения удержания и оптимизации маркетинга.

## Реализация

Код анализа разделен на несколько SQL-файлов:

- `Задача по когортному анализу.sql` — когортный анализ LTV
- `ARPU.sql` — расчет ARPU
- `ARPPU.sql` — расчет ARPPU
- `RFM-анализ.sql` — сегментация клиентов по модели RFM

## Исходные данные

**Таблица:** `checks`

### Атрибуты таблицы `checks`

- `datetime` — дата и время покупки
- `shop` — наименование аптеки
- `card` — идентификатор карты покупателя
- `bonus_earned` — количество начисленных бонусов
- `bonus_spent` — количество списанных бонусов
- `summ` — сумма без учета скидки
- `summ_with_disc` — сумма с учетом списания бонусов
- `doc_id` — идентификатор чека

## Логика анализа

Анализ проводится по клиентам (`card`) и временным характеристикам (`datetime`).

## Когортный анализ LTV

### Описание

Когортный анализ LTV позволяет оценить среднюю ценность клиента по месяцам его первой покупки и отследить, как растет выручка от клиента во времени.

Метрика LTV рассчитывается как совокупная выручка когорты, деленная на количество уникальных клиентов.

---

### Параметры анализа

- Когорта — месяц первой покупки клиента  
- Метрика — `summ_with_disc`  
- Показатель — средний LTV на клиента  
- Периоды — 0, 30, 60, 90, 120, 150, 180 дней  
- Расчет — накопительный итог  

---

## SQL-реализация

**1. Формирование когорт и расчет жизненного цикла клиента**

```sql
WITH first_cogorta_transaction AS (

    SELECT 
        card,
        datetime::DATE AS datetime,
        FIRST_VALUE(datetime) OVER(PARTITION BY card ORDER BY datetime)::DATE AS first_transaction,
        DATE_TRUNC('month', FIRST_VALUE(datetime) OVER(PARTITION BY card ORDER BY datetime))::DATE AS cogorta,
        (datetime::DATE - FIRST_VALUE(datetime) OVER(PARTITION BY card ORDER BY datetime)::DATE) AS diff,
        summ_with_disc
    FROM checks 
    WHERE card LIKE '2000%'
)
```

**2. Расчет LTV по когортам**

```sql
select 
   cogorta,
   COUNT(distinct card) as kolvo_users,
   ROUND(SUM(summ_with_disc) filter (where diff = 0) / COUNT(distinct card)) as "0_day",
   ROUND(case when MAX(diff) >= 30 then SUM(summ_with_disc) filter (where diff <= 30) / COUNT(distinct card) else 0 end) as "30_day",
   ROUND(case when MAX(diff) >= 60 then SUM(summ_with_disc) filter (where diff <= 60) / COUNT(distinct card) else 0 end) as "60_day",
   ROUND(case when MAX(diff) >= 90 then SUM(summ_with_disc) filter (where diff <= 90) / COUNT(distinct card) else 0 end) as "90_day",
   ROUND(case when MAX(diff) >= 120 then SUM(summ_with_disc) filter (where diff <= 120) / COUNT(distinct card) else 0 end) as "120_day",
   ROUND(case when MAX(diff) >= 150 then SUM(summ_with_disc) filter (where diff <= 150) / COUNT(distinct card) else 0 end) as "150_day",
   ROUND(case when MAX(diff) >= 180 then SUM(summ_with_disc) filter (where diff <= 180) / COUNT(distinct card) else 0 end) as "180_day"
 from first_cogorta_transaction
 where cogorta not in ('2021-07-01', '2022-06-01')
 group by cogorta
```
