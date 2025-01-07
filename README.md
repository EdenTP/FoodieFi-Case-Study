# Foodie-Fi SQL Analysis - Solutions

## Overview
This repository contains SQL solutions for the **Foodie-Fi** case study, part of the **8 Week SQL Challenge** by **Data With Danny**. The case study focuses on subscription analytics for a food-based streaming platform, providing insights into customer behavior, subscription trends, churn rates, and plan transitions.

Link to the case study: [8 Week SQL Challenge - Case Study 3](https://8weeksqlchallenge.com/case-study-3/)

---

## Dataset Description
The dataset includes:
- **subscriptions**: Records of customer subscriptions with plan details and start dates.
- **plans**: Metadata about different subscription plans (e.g., trial, basic, pro, annual).

---

## SQL Solutions
### 1. Customer Count
**Query:** Determines the total number of unique customers.
```sql
Select
  count(distinct customer_id) as Number_of_Customers
from
  subscriptions;
```
**Insight:** Foodie-Fi has a total count of unique customers.

---

### 2. Monthly Distribution of Trial Plan Starts
**Query:** Calculates monthly distribution of customers starting on a trial plan.
```sql
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
```
**Insight:** Provides the distribution of trial plan starts by month.

---

### 3. Plan Starts After 2020
**Query:** Lists plan start events after 2020, grouped by plan type.
```sql
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
```
**Insight:** Breaks down plans started after 2020.

---

### 4. Customer Churn Analysis
**Query:** Computes churn rate and percentage.
```sql
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
```
**Insight:** Shows customer churn count and percentage.

---

### 5. Churn After Free Trial
**Query:** Calculates churn after initial free trial.
```sql
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
```
**Insight:** Determines the percentage of customers who churned immediately after their free trial.

---

### 6. Plan Transitions After Free Trial
**Query:** Computes customer transitions and retention rates after free trials.
```sql
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
```
**Insight:** Tracks customer movements after their trial.

---

### 7. Downgrade Analysis
**Query:** Counts customers who downgraded from pro to basic plans in 2020.
```sql
with change_cte as (
  select
    customer_id,
    plan_id as changed_to,
    start_date as changed_to_start_date,
    lag(plan_id, 1) over (
      partition by customer_id
      order by
        start_date asc
    ) as previous_plan
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
```
**Insight:** Measures downgrades between premium and basic plans.

---

## Author
This analysis was created as part of **[Data With Danny](https://github.com/datawithdanny)**'s SQL challenge.

---

## License
This project is licensed under the MIT License.
