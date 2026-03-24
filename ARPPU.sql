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
