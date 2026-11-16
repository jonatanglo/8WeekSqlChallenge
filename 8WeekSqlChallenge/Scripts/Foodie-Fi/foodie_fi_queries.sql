SELECT * FROM foodie_fi."plans" p 

SELECT * FROM foodie_fi.subscriptions s 


--Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
SELECT * 
FROM subscriptions s 
LEFT JOIN "plans" p 
	ON s.plan_id = p.plan_id 
WHERE customer_id = 19--IN (1, 2, 11, 13, 15, 16, 18, 19) 
--customer 1 have started trial and after that he switched to the basic monthly plan 
--customer 2 have started trial and after 7 days switched to the pro annual plan
--customer 11 have started trial, then after 7 days he churned
--customer 13 have started trial, after 7 days the plan have switched automatically to basic monthly and after 3 months he moved to pro monthly
--customer 15 have started the trial, the switched to pro monthly, and after over month he have churned
--customer 16 have started the trial, after the trial the basic monthly plan have started automatically and after over 4 months he decided to go to pro annual
--customer 18 have started the trial and after that the pro monthly plan started automatically
--customer 19 have started the trial, after 7 days he automatically moved to pro monthly and after 2 months he have chosen pro annual

--1.How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) FROM subscriptions s 
--1000

--2.What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
	EXTRACT(DAY FROM s.start_date) AS DAY,
	COUNT(*)
FROM subscriptions s
LEFT JOIN "plans" p 
	ON s.plan_id = p.plan_id 
WHERE p.plan_name = 'trial'
GROUP BY EXTRACT(DAY FROM s.start_date) 
ORDER BY 1

--3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
	plan_name,
	COUNT(*)
FROM subscriptions s 
LEFT JOIN "plans" p 
	ON s.plan_id = p.plan_id 
WHERE start_date >= '2021-01-01'
GROUP BY plan_name

--4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
	COUNT(DISTINCT customer_id) AS churned,
	100.0 * COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS churn_percentage
FROM subscriptions 
WHERE plan_id = 4

--5.How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte AS (SELECT 
	*,
	LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY s.customer_id) AS prev_plan
FROM subscriptions s 
ORDER BY s.customer_id, s.start_date 
)
SELECT COUNT(*) 
FROM cte
WHERE plan_id = 4 AND prev_plan = 0

--6.What is the number and percentage of customer plans after their initial free trial?
--7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
--8.How many customers have upgraded to an annual plan in 2020?
--9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
--10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
--11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?