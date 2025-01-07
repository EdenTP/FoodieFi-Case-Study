-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
Select 
  count(distinct customer_id) as Number_of_Customers 
from 
  subscriptions;
-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select 
  plan_name, 
  month(start_date) as Month_of_start, 
  count(distinct customer_id) as Number_of_Customers 
from 
  subscriptions as s 
  left join plans as p on p.plan_id = s.plan_id 
where 
  plan_name = 'trial' 
group by 
  plan_name, 
  month_of_start 
order by 
  month_of_start asc;
-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select 
  plan_name, 
  start_date, 
  count(plan_name) number_of_events 
from 
  subscriptions as s 
  left join plans as p on p.plan_id = s.plan_id 
where 
  year(start_date)> 2020 
group by 
  plan_name, 
  start_date, 
  start_date 
order by 
  plan_name asc, 
  start_date asc;
-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
with customer_number as (
  Select 
    count(distinct customer_id) as Number_of_Customers, 
    1 as dummy 
  from 
    subscriptions
), 
churn_count as (
  select 
    plan_name, 
    count(distinct customer_id) as Number_of_Churners, 
    1 as dummy 
  from 
    subscriptions as s 
    left join plans as p on p.plan_id = s.plan_id 
  where 
    plan_name = 'churn' 
  group by 
    plan_name, 
    1
) 
select 
  number_of_customers, 
  round(
    100 * Number_of_Churners / number_of_customers, 
    0
  ) as churn_percent 
from 
  churn_count as cc 
  join customer_number as cn on cn.dummy = cc.dummy;
-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with first_trial as (
  select 
    plan_name, 
    p.plan_id, 
    min(start_date) as first_trial_date, 
    customer_id 
  from 
    subscriptions as s 
    left join plans as p on p.plan_id = s.plan_id 
  where 
    plan_name = 'trial' 
  group by 
    plan_name, 
    customer_id, 
    p.plan_id
), 
first_plan_change as (
  select 
    s.customer_id, 
    s.plan_id, 
    start_date, 
    datediff(
      'day', first_trial_date, start_date
    ) as days_from_trial, 
    RANK() OVER (
      PARTITION BY ft.customer_id 
      ORDER BY 
        days_from_trial asc
    ) as plan_change 
  from 
    subscriptions as s 
    join first_trial as ft on ft.customer_id = s.customer_id 
  where 
    start_date != first_trial_date qualify plan_change = 1 
  order by 
    s.customer_id asc
), 
churners as (
  select 
    count(distinct customer_id) as churned, 
    1 as dummy 
  from 
    first_plan_change 
  where 
    plan_id = 4
) 
select 
  count(distinct customer_id) as total_trialers, 
  ch.churned 
from 
  first_plan_change as fp 
  left join churners as ch on ch.dummy = 1 
group by 
  churned -- What is the number and percentage of customer plans after their initial free trial?
  -- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
  -- How many customers have upgraded to an annual plan in 2020?
  -- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
  -- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
  -- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
