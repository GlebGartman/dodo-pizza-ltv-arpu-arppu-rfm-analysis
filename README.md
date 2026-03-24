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

### 📈 Результаты когортного анализа LTV
![Когортный анализ](https://drive.google.com/uc?export=view&id=102RVMJ9XtWD9-72N5PflCjmyoZCh83Zn)

## Выводы

- Средний LTV за 180 дней достигает до ~3300 ₽, при этом сентябрьская когорта наиболее ценная.

- Наблюдается снижение LTV у более поздних когорт, что может указывать на ухудшение качества привлечения.

- Высокий первый чек не гарантирует высокий LTV: например, мартовская когорта показывает слабый рост после первой покупки.

- Ключевой период формирования ценности клиента — первые 120 дней, в которые формируется ~80–85% итогового LTV.

- Коэффициент роста LTV90/LTV0 у большинства когорт ≥ 2, однако есть проблемные когорты с низкой динамикой (≤ 1.7).

- Основные усилия по удержанию клиентов следует концентрировать в период 0–120 дней после первой покупки.

- Проблемные когорты (например, март и декабрь) требуют дополнительной проработки и реактивации.

## Когортный анализ ARPU и ARPPU

### Описание

Когортный анализ позволяет оценить средний вклад клиентов по периодам после первой покупки.

ARPU отражает среднюю выручку на одного пользователя когорты, включая неактивных клиентов.  
ARPPU показывает среднюю выручку только среди активных клиентов.

---

### Параметры анализа

- Когорта — месяц первой покупки клиента  
- Метрика — `summ_with_disc`  
- Основной показатель — ARPU  
- Дополнительный показатель — ARPPU  
- Периоды — 0, 1-30, 31-60, 61-90, 91-120, 121-150, 151-180 дней  
- Расчет — без накопительного итога  
- Округление — до 2 знаков  

---

## SQL-реализация

**1. Формирование когорт и жизненного цикла клиента**

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
),
```
**2. Формирование периодов ARPU**

```sql
arpu_diff as (
select *,
case 
	when diff = 0 then '0_arpu'
	when diff <= 30 then '30_arpu'
	when diff <= 60 then '60_arpu'
	when diff <= 90 then '90_arpu'
	when diff <= 120 then '120_arpu'
	when diff <= 150 then '150_arpu'
	when diff <= 180 then '180_arpu'
end as arpu
from first_cogorta_transaction
)
```

**3. Расчет ARPU по когортам**

```sql
select 
   cogorta,
   COUNT(distinct card) as kolvo_users,
   ROUND(SUM(summ_with_disc) filter (where arpu = '0_arpu') / COUNT(distinct card), 2) as "0_day",
   ROUND(SUM(summ_with_disc) filter (where arpu = '30_arpu') / COUNT(distinct card), 2) as "30_day",
   ROUND(SUM(summ_with_disc) filter (where arpu = '60_arpu') / COUNT(distinct card), 2) as "60_day",
   ROUND(SUM(summ_with_disc) filter (where arpu = '90_arpu') / COUNT(distinct card), 2) as "90_day",
   ROUND(SUM(summ_with_disc) filter (where arpu = '120_arpu') / COUNT(distinct card), 2) as "120_day",
   ROUND(SUM(summ_with_disc) filter (where arpu = '150_arpu') / COUNT(distinct card), 2) as "150_day",
   ROUND(SUM(summ_with_disc) filter (where arpu = '180_arpu') / COUNT(distinct card), 2) as "180_day"
 from arpu_diff
 where cogorta not in ('2021-07-01', '2022-06-01')
 group by cogorta
```

### 📊 Результаты когортного анализа ARPU
![ARPU анализ](https://drive.google.com/uc?export=view&id=1Ivi7QCcf3-_2PaXyIeVdKBwPBnBW8R_U)

**4. Формирование периодов ARPPU**
```sql
arppu_diff as (
select *,
case 
	when diff = 0 then '0_arppu'
	when diff <= 30 then '30_arppu'
	when diff <= 60 then '60_arppu'
	when diff <= 90 then '90_arppu'
	when diff <= 120 then '120_arppu'
	when diff <= 150 then '150_arppu'
	when diff <= 180 then '180_arppu'
end as arppu
from first_cogorta_transaction
)
```

**5. Расчет ARPPU по когортам**

```sql
select 
   cogorta,
   COUNT(distinct card) as kolvo_users,
   ROUND(SUM(summ_with_disc) filter (where arppu = '0_arppu') / COUNT(distinct card) filter (where arppu = '0_arppu'), 2) as "0_day",
   ROUND(SUM(summ_with_disc) filter (where arppu = '30_arppu') / COUNT(distinct card) filter (where arppu = '30_arppu'), 2) as "30_day",
   ROUND(SUM(summ_with_disc) filter (where arppu = '60_arppu') / COUNT(distinct card) filter (where arppu = '60_arppu'), 2) as "60_day",
   ROUND(SUM(summ_with_disc) filter (where arppu = '90_arppu') / COUNT(distinct card) filter (where arppu = '90_arppu'), 2) as "90_day",
   ROUND(SUM(summ_with_disc) filter (where arppu = '120_arppu') / COUNT(distinct card) filter (where arppu = '120_arppu'), 2) as "120_day",
   ROUND(SUM(summ_with_disc) filter (where arppu = '150_arppu') / COUNT(distinct card) filter (where arppu = '150_arppu'), 2) as "150_day",
   ROUND(SUM(summ_with_disc) filter (where arppu = '180_arppu') / COUNT(distinct card) filter (where arppu = '180_arppu'), 2) as "180_day"
 from arppu_diff
 where cogorta not in ('2021-07-01', '2022-06-01')
 group by cogorta
```

### 📊 Результаты когортного анализа ARPPU
![ARPPU анализ](https://drive.google.com/uc?export=view&id=1D8UlakIFEfercOGo85q9IiZc5WIIcTAS)

## Выводы

- Наблюдается снижение притока новых клиентов: размер когорт сокращается со временем.

- При этом качество клиентов остается высоким: ARPPU стабильно на уровне 1200–1800 ₽, пик приходится на 2–3 месяц после первой покупки.

- Основной вклад в выручку дают активные клиенты, которые продолжают совершать повторные покупки.

- Важно учитывать ограничение данных: когорты с коротким периодом наблюдения нельзя корректно сравнивать с более старыми.

- Выражена сезонность: осенне-зимние когорты показывают более высокий ARPPU, весной и летом наблюдается снижение активности.

- Проблемная когорта (март 2022) показывает резкое падение ARPPU на 4 месяце, что связано с сезонным фактором.

- В целом, проблема не в качестве клиентов, а в снижении их количества.

