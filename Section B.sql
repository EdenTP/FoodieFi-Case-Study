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
  count(*) number_of_events 
from 
  subscriptions as s 
  left join plans as p on p.plan_id = s.plan_id 
where 
  year(start_date)> 2020 
group by 
  plan_name 
order by 
  plan_name asc;
-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
with churn_table as (
  Select 
    count(distinct customer_id) as churners 
  from 
    subscriptions 
  where 
    plan_id = 4
) 
select 
  count(distinct customer_id) as Number_of_Customers, 
  churners, 
  round(
    100 * churners / number_of_customers, 
    0
  ) as churn_percentage 
from 
  subscriptions as s 
  left join churn_table as c on 1 = 1 
group by 
  churners;
-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with prev_plan as (
  select 
    *, 
    lag(plan_id, 1) over (
      partition by customer_id 
      order by 
        start_date asc
    ) as previous_plan 
  from 
    subscriptions
), 
first_plan_trial as (
  select 
    customer_id 
  from 
    prev_plan 
  where 
    plan_id = 0 qualify previous_plan is null
), 
churners as (
  select 
    count(*) as churned 
  from 
    prev_plan as pp 
    left join first_plan_trial as fpt on fpt.customer_id = pp.customer_id 
  where 
    plan_id = 4 
    and previous_plan = 0
) 
select 
  count(*) as trial_as_first_plan, 
  churned, 
  round(
    100 * churned / trial_as_first_plan, 
    0
  ) as churn_percent 
from 
  first_plan_trial 
  left join churners on 1 = 1 
group by 
  churned;
-- What is the number and percentage of customer plans after their initial free trial?
with plan_cte as (
  select 
    *, 
    lead(plan_id, 1) over (
      partition by customer_id 
      order by 
        start_date asc
    ) as next_plan, 
    lag(plan_id, 1) over (
      partition by customer_id 
      order by 
        start_date asc
    ) as previous_plan 
  from 
    subscriptions
), 
first_plan_trial as (
  select 
    customer_id, 
    start_date 
  from 
    plan_cte 
  where 
    plan_id = 0 qualify previous_plan is null
), 
retain_cte as (
  select 
    next_plan, 
    count(*) as retained 
  from 
    plan_cte as pc 
    left join first_plan_trial as fpt on fpt.customer_id = pc.customer_id 
    and pc.start_date = fpt.start_date 
  where 
    plan_id = 0 
  group by 
    next_plan
) 
select 
  plan_name, 
  count(*) as trial_count, 
  retained, 
  round(100 * retained / trial_count, 1) as retention_percent 
from 
  first_plan_trial 
  left join retain_cte as rc on 1 = 1 
  left join plans on next_plan = plans.plan_id 
group by 
  plan_name, 
  retained;
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with max_dates as (
  select 
    customer_id, 
    max(start_date) as max_date 
  from 
    subscriptions 
  where 
    start_date <= to_date('2020-12-31') 
  group by 
    customer_id
), 
plan_dist as (
  select 
    plan_name, 
    count(*) as customer_count 
  from 
    subscriptions as s 
    inner join max_dates as md on md.customer_id = s.customer_id 
    and md.max_date = s.start_date 
    left join plans as p on p.plan_id = s.plan_id 
  group by 
    plan_name
) 
select 
  pd.plan_name, 
  pd.customer_count, 
  round(
    100 * pd.customer_count / sum(pdt.customer_count), 
    1
  ) as percentage 
from 
  plan_dist as pdt 
  left join plan_dist as pd on 1 = 1 
group by 
  pd.customer_count, 
  pd.plan_name;
-- How many customers have upgraded to an annual plan in 2020?
with non_annual as (
  select 
    customer_id 
  from 
    subscriptions 
  where 
    plan_id != 4 
    and plan_id != 3 
    and year(start_date)< 2021 
  group by 
    customer_id
), 
annual_customer as (
  select 
    s.customer_id 
  from 
    subscriptions as s 
  where 
    plan_id = 3 
    and year(start_date)< 2021 
  group by 
    s.customer_id
) 
select 
  count(*) as annual_upgrades 
from 
  annual_customer as ac 
  inner join non_annual as na on na.customer_id = ac.customer_id;
-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with non_annual as (
  select 
    customer_id, 
    min(start_date) as join_date 
  from 
    subscriptions 
  where 
    plan_id != 4 
    and plan_id != 3 
  group by 
    customer_id
), 
annual_customer as (
  select 
    s.customer_id, 
    min(start_date) as annual_date 
  from 
    subscriptions as s 
  where 
    plan_id = 3 
  group by 
    s.customer_id
), 
day_to_upgrade_cte as (
  select 
    na.customer_id, 
    annual_date, 
    join_date, 
    datediff('day', join_date, annual_date) as days_to_upgrade 
  from 
    annual_customer as ac 
    inner join non_annual as na on na.customer_id = ac.customer_id
) 
select 
  round(
    avg(days_to_upgrade), 
    1
  ) as avg_days_to_upgrade 
from 
  day_to_upgrade_cte;
-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with non_annual as (
  select 
    customer_id, 
    min(start_date) as join_date 
  from 
    subscriptions 
  where 
    plan_id != 4 
    and plan_id != 3 
  group by 
    customer_id
), 
annual_customer as (
  select 
    s.customer_id, 
    min(start_date) as annual_date 
  from 
    subscriptions as s 
  where 
    plan_id = 3 
  group by 
    s.customer_id
), 
day_to_upgrade_cte as (
  select 
    na.customer_id, 
    annual_date, 
    join_date, 
    datediff('day', join_date, annual_date) as days_to_upgrade 
  from 
    annual_customer as ac 
    inner join non_annual as na on na.customer_id = ac.customer_id
), 
period_cte as (
  select 
    customer_id, 
    days_to_upgrade, 
    Case when floor(days_to_upgrade / 30)* 30 = 0 then floor(days_to_upgrade / 30)* 30 || '-' ||(
      (
        floor(days_to_upgrade / 30)+ 1
      )* 30
    ) else floor(days_to_upgrade / 30)* 30 + 1 || '-' ||(
      (
        floor(days_to_upgrade / 30)+ 1
      )* 30
    ) end as period 
  from 
    day_to_upgrade_cte
) 
select 
  period, 
  round(
    avg(days_to_upgrade), 
    1
  ) as avg_days_to_upgrade, 
  count(*) as number_of_customers 
from 
  period_cte 
group by 
  period 
order by 
  split_part(period, '-', 1):: number asc;
-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with change_cte as (
  select 
    customer_id, 
    plan_id as changed_to, 
    start_date as changed_to_start_date, 
    lag(plan_id, 1) over (
      partition by customer_id 
      order by 
        start_date asc
    ) as previous_plan, 
    lag(start_date, 1) over (
      partition by customer_id 
      order by 
        start_date asc
    ) as previous_plan_start_date 
  from 
    subscriptions qualify previous_plan = 2 
    and changed_to = 1
) 
select 
  count(*) as pro_to_basic_downgrades 
from 
  change_cte 
where 
  year(changed_to_start_date)= 2020;
