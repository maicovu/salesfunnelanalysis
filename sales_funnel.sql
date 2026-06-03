SELECT  FROM `sales-funnnel-analysis.sql_practice.user_events` LIMIT 1000

SELECT *
FROM `sales-funnnel-analysis.sql_practice.user_events` 
LIMIT 5;
-- define sales funnel and different stages
WITH FUNNEL_STAGES AS(
  SELECT
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'page_view' THEN USER_ID END) AS STAGE_1_VIEWS,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'add_to_cart' THEN USER_ID END) AS STAGE_2_CART,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'checkout_start' THEN USER_ID END) AS STAGE_3_CHECKOUT,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'payment_info' THEN USER_ID END) AS STAGE_4_PAYMENT,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'purchase' THEN USER_ID END) AS STAGE_5_PURCHASE,
FROM `sales-funnnel-analysis.sql_practice.user_events` 
where event_date >= TIMESTAMP(date_sub(current_date(), interval 30 day))
)

SELECT *
FROM FUNNEL_STAGES

-- conversion rates through the funnel
WITH FUNNEL_STAGES AS(
  SELECT
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'page_view' THEN USER_ID END) AS STAGE_1_VIEWS,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'add_to_cart' THEN USER_ID END) AS STAGE_2_CART,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'checkout_start' THEN USER_ID END) AS STAGE_3_CHECKOUT,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'payment_info' THEN USER_ID END) AS STAGE_4_PAYMENT,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'purchase' THEN USER_ID END) AS STAGE_5_PURCHASE,
FROM `sales-funnnel-analysis.sql_practice.user_events` 
where event_date >= TIMESTAMP(date_sub(current_date(), interval 30 day))
)
SELECT
  STAGE_1_VIEWS,
  STAGE_2_CART,
  CONCAT  (ROUND(STAGE_2_CART * 100/ STAGE_1_VIEWS),'%') AS VIEWS_TO_CART_RATE,
  STAGE_3_CHECKOUT,
  CONCAT  (ROUND(STAGE_3_CHECKOUT * 100 / STAGE_2_CART), '%') AS CART_TO_CHECKOUT_RATE,
  STAGE_4_PAYMENT,
  CONCAT  (ROUND(STAGE_4_PAYMENT * 100 / STAGE_3_CHECKOUT), '%') AS CHECKOUT_TO_PAYMENT_RATE,
  STAGE_5_PURCHASE,
  CONCAT  (ROUND(STAGE_5_PURCHASE * 100 / STAGE_4_PAYMENT), '%') AS PAYMENT_TO_PURHCASE_RATE,
  CONCAT  (ROUND(STAGE_5_PURCHASE * 100 / STAGE_1_VIEWS), '%') AS OVERALL_CONVERSION_RATE,

FROM FUNNEL_STAGES

-- funnel by source
WITH SOURCE_FUNNEL AS(
  SELECT
    TRAFFIC_SOURCE,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'page_view' THEN USER_ID END) AS VIEWS,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'add_to_cart' THEN USER_ID END) AS CARTS,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'purchase' THEN USER_ID END) AS PURCHASE,
FROM `sales-funnnel-analysis.sql_practice.user_events`
where event_date >= TIMESTAMP(date_sub(current_date(), interval 30 day))
GROUP BY 1
)
SELECT 
  TRAFFIC_SOURCE,
  VIEWS,
  CARTS,
  PURCHASE,
  CONCAT  (ROUND(CARTS * 100 / VIEWS), '%') AS CART_CONVERSION_RATE,
  CONCAT  (ROUND(PURCHASE * 100 / VIEWS), '%') AS PURCHASE_CONVERSION_RATE,
  CONCAT  (ROUND(PURCHASE * 100 / CARTS), '%') AS CARTS_TO_PURCHASE_CONVERSION_RATE
FROM SOURCE_FUNNEL
ORDER BY PURCHASE DESC


--- time to conversion analysis

WITH user_journey AS(
  SELECT
    user_id,
    MIN( CASE WHEN EVENT_TYPE = 'page_view' THEN event_date END) AS views_time,
    MIN( CASE WHEN EVENT_TYPE = 'add_to_cart' THEN event_date END) AS cart_time,
    MIN( CASE WHEN EVENT_TYPE = 'purchase' THEN event_date END) AS purchase_time,
FROM `sales-funnnel-analysis.sql_practice.user_events`
where event_date >= TIMESTAMP(date_sub(current_date(), interval 30 day))
GROUP BY 1
HAVING MIN( CASE WHEN EVENT_TYPE = 'purchase' then event_date END) is not null
)
select
  count (*) as converted_users,
  round(avg(timestamp_diff(cart_time, views_time, minute)),2) as avg_view_to_cart_minute,
  round(avg(timestamp_diff(purchase_time, cart_time, minute)),2) as avg_cart_to_purchase_minute,
  round(avg(timestamp_diff(purchase_time, views_time, minute)),2) as avg_total_journey_minute
from user_journey

 --- revenue funnel analyst

 WITH revenue_funnel AS(
  SELECT
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'page_view' THEN USER_ID END) AS total_visitors,
    COUNT(DISTINCT CASE WHEN EVENT_TYPE = 'purchase' THEN USER_ID END) AS total_buyers,
    SUM(CASE WHEN  EVENT_TYPE = 'purchase' THEN AMOUNT END) AS total_revenue,
    count(CASE WHEN EVENT_TYPE = 'purchase' THEN 1 END) AS total_orders
FROM `sales-funnnel-analysis.sql_practice.user_events`
where event_date >= TIMESTAMP(date_sub(current_date(), interval 30 day))
 )

 select
  total_visitors,
  total_buyers,
  total_revenue,
  total_orders,
  round(total_revenue/total_orders,2) as avg_ord_value,
  round(total_revenue/total_buyers,2) as revenue_page_buyer,
  round(total_revenue/total_visitors,2) as revenue_page_visitors
from revenue_funnel
  




