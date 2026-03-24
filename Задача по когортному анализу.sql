with first_cogorta_transaction as 
(
select 
  card,
  datetime::DATE as datetime,
  first_value(datetime) OVER(partition by card order by datetime)::DATE as first_transaction,
  date_trunc('month', first_value(datetime) OVER(partition by card order by datetime))::DATE as cogorta,
  (datetime::DATE - first_value(datetime) OVER(partition by card order by datetime)::DATE) as diff,
  summ_with_disc
from checks 
where card like '2000%'
)

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
