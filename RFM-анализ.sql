with date_card
as (
select 
  card,
  MAX(datetime) OVER()::DATE as last_date,
  MAX(datetime) OVER(partition by card)::DATE as last_date_user,
  summ_with_disc 
from checks 
where card like '2000%'
order by datetime 
),

metrics as 
(
select 
  card,
  MAX(last_date - last_date_user) as Recency,
  COUNT(card) as Frequency,
  SUM(summ_with_disc) as Monetary
 from date_card
 group by card
 ),

percentiles AS (
SELECT
  PERCENTILE_DISC(0.33) WITHIN GROUP (ORDER BY Recency) AS r33,
  PERCENTILE_DISC(0.66) WITHIN GROUP (ORDER BY Recency) AS r66,
  PERCENTILE_DISC(0.33) WITHIN GROUP (ORDER BY Frequency) AS f33,
  PERCENTILE_DISC(0.66) WITHIN GROUP (ORDER BY Frequency) AS f66,
  PERCENTILE_DISC(0.33) WITHIN GROUP (ORDER BY Monetary) AS m33,
  PERCENTILE_DISC(0.66) WITHIN GROUP (ORDER BY Monetary) AS m66
FROM metrics
),
 
RFM as 
(
 select 
   card,
   CONCAT(
   case
      when Recency <= (select r33 from percentiles) then 1
      when Recency <= (select r66 from percentiles) then 2
      else 3
   end,
   case
      when Frequency <= (select f33 from percentiles) then 3
      when Frequency <= (select f66 from percentiles) then 2
      else 1
   end,   
   case
      when Monetary <= (select m33 from percentiles) then 3
      when Monetary <= (select m66 from percentiles) then 2
      else 1
   end
   ) as RFM
from metrics
),

kovlo_frm as
(
select 
    rfm,
    count(card) as kolvo
from RFM 
group by 1
order by 1
),

statistics as
(
select *, 
     CONCAT(ROUND(100 * kolvo / SUM(kolvo) OVER(), 2), '%') as percent
from kovlo_frm 
),

spisok_card as 
(
select
   RFM,
   STRING_AGG(card, '; ') as spisok_card
from RFM
group by 1
order by 1
)


