SELECT * FROM runners;

SELECT * FROM customer_orders;

SELECT * FROM runner_orders;

SELECT * FROM pizza_names;

SELECT * FROM pizza_recipes;

SELECT * FROM pizza_toppings;

--Naprawa customer_orders.exclusions
UPDATE customer_orders 
SET exclusions = NULL
WHERE exclusions = 'null' OR exclusions = '';

--Naprawa customer_orders.extras
UPDATE customer_orders 
SET extras = NULL
WHERE extras = 'null' OR extras = '';

--Naprawa runner_orders
SELECT * FROM runner_orders;

--Naprawa runner_orders.picup_time
UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null' OR pickup_time = '';

ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::TIMESTAMP;

--Naprawa runner_orders.distance
UPDATE runner_orders
SET distance = REPLACE(distance, 'km', '');

UPDATE runner_orders
SET distance = REPLACE(distance, ' ', '');

UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null';

ALTER TABLE runner_orders
ALTER COLUMN distance TYPE FLOAT USING CAST(distance AS FLOAT);
COMMIT;

--Naprawa runner_orders.duration
UPDATE runner_orders
SET duration = REPLACE(duration, ' minutes', '');


UPDATE runner_orders
SET duration = REPLACE(duration, ' mins', '');

UPDATE runner_orders
SET duration = REPLACE(duration, 'mins', '');

UPDATE runner_orders
SET duration = REPLACE(duration, ' minute', '');

UPDATE runner_orders
SET duration = REPLACE(duration, 'minutes', '');

UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null';

ALTER TABLE runner_orders
ALTER COLUMN duration TYPE INT USING CAST(duration AS INT);
COMMIT;

--Naprawa runner_orders.cancellation
UPDATE runner_orders
SET cancellation = NULL 
WHERE cancellation = 'null' OR cancellation = '';

-- A1. How many pizzas were ordered?
SELECT COUNT(DISTINCT order_id)
FROM customer_orders;

-- A2. How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id)
FROM customer_orders;

-- A3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(runner_id)
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;

-- A4. How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(pn.pizza_name)
FROM pizza_names pn 
LEFT JOIN customer_orders co 
	ON pn.pizza_id = co.pizza_id 
LEFT JOIN runner_orders ro 
	ON co.order_id = ro.order_id 
WHERE ro.cancellation IS NULL
GROUP BY pn.pizza_name;

-- A5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id, pn.pizza_name, COUNT(co.customer_id)
FROM customer_orders co 
LEFT JOIN pizza_names pn 
	ON co.pizza_id = pn.pizza_id 
GROUP BY co.customer_id, pn.pizza_name
ORDER BY co.customer_id;

-- A6. What was the maximum number of pizzas delivered in a single order?
SELECT co.order_id, COUNT(co.order_id) max
FROM customer_orders co 
LEFT JOIN runner_orders ro 
	ON co.order_id = ro.order_id 
WHERE ro.cancellation IS NULL
GROUP BY co.order_id 
ORDER BY max DESC
LIMIT 1;

-- A7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
	co.customer_id
	,SUM(CASE
		WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 0
		ELSE 1
	END) has_changes
FROM customer_orders co 
LEFT JOIN runner_orders ro 
	ON co.order_id = ro.order_id 
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;

-- A8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
	SUM(CASE
		WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1
		ELSE 0
	END) both_changes
FROM customer_orders co 
LEFT JOIN runner_orders ro 
	ON co.order_id = ro.order_id 
WHERE ro.cancellation IS NULL;

-- A9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	EXTRACT(HOUR FROM co.order_time) "hour"
	, COUNT(co.pizza_id)
FROM customer_orders co 
GROUP BY "hour";

-- A10. What was the volume of orders for each day of the week?
SELECT 
	EXTRACT(dow from order_time::timestamp)
	,COUNT(*) AS number_of_orders
FROM customer_orders
GROUP BY EXTRACT(dow from order_time::timestamp);

