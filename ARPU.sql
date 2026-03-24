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
),

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
