
# Foodie-Fi SQL Challenge Solutions

This repository contains my solutions for the **Foodie-Fi SQL Challenge** from Data With Danny. The challenge involves analyzing subscription data from a fictional streaming service, Foodie-Fi, which offers various food-related plans to its customers. Below are my solutions to the data analysis questions presented in the challenge.

---

## Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?

```sql
SELECT 
  COUNT(DISTINCT customer_id) AS Number_of_Customers 
FROM 
  subscriptions;
```

### 2. What is the monthly distribution of trial plan start_date values for our dataset (grouped by the start of the month)?

```sql
SELECT 
  plan_name, 
  MONTH(start_date) AS Month_of_start, 
  COUNT(DISTINCT customer_id) AS Number_of_Customers 
FROM 
  subscriptions AS s 
  LEFT JOIN plans AS p ON p.plan_id = s.plan_id 
WHERE 
  plan_name = 'trial' 
GROUP BY 
  plan_name, 
  Month_of_start 
ORDER BY 
  Month_of_start ASC;
```

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.

```sql
SELECT 
  plan_name, 
  COUNT(*) AS number_of_events 
FROM 
  subscriptions AS s 
  LEFT JOIN plans AS p ON p.plan_id = s.plan_id 
WHERE 
  YEAR(start_date) > 2020 
GROUP BY 
  plan_name 
ORDER BY 
  plan_name ASC;
```

### 4. What is the customer count and percentage of customers who have churned (rounded to 1 decimal place)?

```sql
WITH churn_table AS (
  SELECT 
    COUNT(DISTINCT customer_id) AS churners 
  FROM 
    subscriptions 
  WHERE 
    plan_id = 4
) 
SELECT 
  COUNT(DISTINCT customer_id) AS Number_of_Customers, 
  churners, 
  ROUND(100 * churners / number_of_customers, 0) AS churn_percentage 
FROM 
  subscriptions AS s 
  LEFT JOIN churn_table AS c ON 1 = 1 
GROUP BY 
  churners;
```

### 5. How many customers have churned straight after their initial free trial? What percentage is this (rounded to the nearest whole number)?

```sql
WITH prev_plan AS (
  SELECT 
    *, 
    LAG(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS previous_plan 
  FROM 
    subscriptions
), 
first_plan_trial AS (
  SELECT 
    customer_id 
  FROM 
    prev_plan 
  WHERE 
    plan_id = 0 QUALIFY previous_plan IS NULL
), 
churners AS (
  SELECT 
    COUNT(*) AS churned 
  FROM 
    prev_plan AS pp 
    LEFT JOIN first_plan_trial AS fpt ON fpt.customer_id = pp.customer_id 
  WHERE 
    plan_id = 4 
    AND previous_plan = 0
) 
SELECT 
  COUNT(*) AS trial_as_first_plan, 
  churned, 
  ROUND(100 * churned / trial_as_first_plan, 0) AS churn_percent 
FROM 
  first_plan_trial 
  LEFT JOIN churners ON 1 = 1 
GROUP BY 
  churned;
```

### 6. What is the number and percentage of customer plans after their initial free trial?

```sql
WITH plan_cte AS (
  SELECT 
    *, 
    LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS next_plan, 
    LAG(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS previous_plan 
  FROM 
    subscriptions
), 
first_plan_trial AS (
  SELECT 
    customer_id, 
    start_date 
  FROM 
    plan_cte 
  WHERE 
    plan_id = 0 QUALIFY previous_plan IS NULL
), 
retain_cte AS (
  SELECT 
    next_plan, 
    COUNT(*) AS retained 
  FROM 
    plan_cte AS pc 
    LEFT JOIN first_plan_trial AS fpt ON fpt.customer_id = pc.customer_id 
    AND pc.start_date = fpt.start_date 
  WHERE 
    plan_id = 0 
  GROUP BY 
    next_plan
) 
SELECT 
  plan_name, 
  COUNT(*) AS trial_count, 
  retained, 
  ROUND(100 * retained / trial_count, 1) AS retention_percent 
FROM 
  first_plan_trial 
  LEFT JOIN retain_cte AS rc ON 1 = 1 
  LEFT JOIN plans ON next_plan = plans.plan_id 
GROUP BY 
  plan_name, 
  retained;
```

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

```sql
WITH max_dates AS (
  SELECT 
    customer_id, 
    MAX(start_date) AS max_date 
  FROM 
    subscriptions 
  WHERE 
    start_date <= TO_DATE('2020-12-31') 
  GROUP BY 
    customer_id
), 
plan_dist AS (
  SELECT 
    plan_name, 
    COUNT(*) AS customer_count 
  FROM 
    subscriptions AS s 
    INNER JOIN max_dates AS md ON md.customer_id = s.customer_id 
    AND md.max_date = s.start_date 
    LEFT JOIN plans AS p ON p.plan_id = s.plan_id 
  GROUP BY 
    plan_name
) 
SELECT 
  pd.plan_name, 
  pd.customer_count, 
  ROUND(100 * pd.customer_count / SUM(pdt.customer_count), 1) AS percentage 
FROM 
  plan_dist AS pdt 
  LEFT JOIN plan_dist AS pd ON 1 = 1 
GROUP BY 
  pd.customer_count, 
  pd.plan_name;
```

### 8. How many customers have upgraded to an annual plan in 2020?

```sql
WITH non_annual AS (
  SELECT 
    customer_id 
  FROM 
    subscriptions 
  WHERE 
    plan_id != 4 
    AND plan_id != 3 
    AND YEAR(start_date) < 2021 
  GROUP BY 
    customer_id
), 
annual_customer AS (
  SELECT 
    s.customer_id 
  FROM 
    subscriptions AS s 
  WHERE 
    plan_id = 3 
    AND YEAR(start_date) < 2021 
  GROUP BY 
    s.customer_id
) 
SELECT 
  COUNT(*) AS annual_upgrades 
FROM 
  annual_customer AS ac 
  INNER JOIN non_annual AS na ON na.customer_id = ac.customer_id;
```

### 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?

```sql
WITH non_annual AS (
  SELECT 
    customer_id, 
    MIN(start_date) AS join_date 
  FROM 
    subscriptions 
  WHERE 
    plan_id != 4 
    AND plan_id != 3 
  GROUP BY 
    customer_id
), 
annual_customer AS (
  SELECT 
    s.customer_id, 
    MIN(start_date) AS annual_date 
  FROM 
    subscriptions AS s 
  WHERE 
    plan_id = 3 
  GROUP BY 
    s.customer_id
), 
day_to_upgrade_cte AS (
  SELECT 
    na.customer_id, 
    annual_date, 
    join_date, 
    DATEDIFF('day', join_date, annual_date) AS days_to_upgrade 
  FROM 
    annual_customer AS ac 
    INNER JOIN non_annual AS na ON na.customer_id = ac.customer_id
) 
SELECT 
  ROUND(AVG(days_to_upgrade), 1) AS avg_days_to_upgrade 
FROM 
  day_to_upgrade_cte;
```

### 10. Can you further breakdown this average value into 30-day periods (e.g., 0-30 days, 31-60 days)?

```sql
WITH non_annual AS (
  SELECT 
    customer_id, 
    MIN(start_date) AS join_date 
  FROM 
    subscriptions 
  WHERE 
    plan_id != 4 
    AND plan_id != 3 
  GROUP BY 
    customer_id
), 
annual_customer AS (
  SELECT 
    s.customer_id, 
    MIN(start_date) AS annual_date 
  FROM 
    subscriptions AS s 
  WHERE 
    plan_id = 3 
  GROUP BY 
    s.customer_id
), 
day_to_upgrade_cte AS (
  SELECT 
    na.customer_id, 
    annual_date, 
    join_date, 
    DATEDIFF('day', join_date, annual_date) AS days_to_upgrade 
  FROM 
    annual_customer AS ac 
    INNER JOIN non_annual AS na ON na.customer_id = ac.customer_id
), 
period_cte AS (
  SELECT 
    customer_id, 
    days_to_upgrade, 
    CASE 
      WHEN FLOOR(days_to_upgrade / 30) * 30 = 0 
        THEN FLOOR(days_to_upgrade / 30) * 30 || '-' || (
          (FLOOR(days_to_upgrade / 30) + 1) * 30
        ) 
      ELSE FLOOR(days_to_upgrade / 30) * 30 + 1 || '-' || (
          (FLOOR(days_to_upgrade / 30) + 1) * 30
        ) 
    END AS period 
  FROM 
    day_to_upgrade_cte
) 
SELECT 
  period, 
  ROUND(AVG(days_to_upgrade), 1) AS avg_days_to_upgrade, 
  COUNT(*) AS number_of_customers 
FROM 
  period_cte 
GROUP BY 
  period 
ORDER BY 
  SPLIT_PART(period, '-', 1)::NUMBER ASC;
```

### 11. How many customers downgraded from a Pro monthly to a Basic monthly plan in 2020?

```sql
WITH change_cte AS (
  SELECT 
    customer_id, 
    plan_id AS changed_to, 
    start_date AS changed_to_start_date, 
    LAG(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS previous_plan, 
    LAG(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS previous_plan_start_date 
  FROM 
    subscriptions QUALIFY previous_plan = 2 
    AND changed_to = 1
) 
SELECT 
  COUNT(*) AS pro_to_basic_downgrades 
FROM 
  change_cte 
WHERE 
  YEAR(changed_to_start_date) = 2020;
```

---

## Conclusion

These solutions were designed to efficiently extract insights from the Foodie-Fi subscription dataset using SQL queries. Feel free to explore each query and modify them for further analysis.
