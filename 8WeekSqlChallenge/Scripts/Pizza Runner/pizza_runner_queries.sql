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

--Naprawa pizza recipes
DROP TABLE IF EXISTS pizza_recipes_old;
ALTER TABLE pizza_recipes RENAME TO pizza_recipes_old;
CREATE TABLE pizza_recipes AS
	SELECT
		pizza_id
		,TRIM(UNNEST(regexp_split_to_array(toppings, ','))) toppings --https://medium.com/@suhasthakral/split-strings-lists-into-rows-in-postgres-82bfa5dbef53
	FROM pizza_recipes_old;
DROP TABLE pizza_recipes_old;
ALTER TABLE pizza_recipes ALTER COLUMN toppings TYPE integer USING (toppings::integer); --https://stackoverflow.com/questions/26439033/change-column-datatype-from-text-to-integer-in-postgresql

--Stworzenie nowej tabeli przechowującej nazwę typu zmiany w zamówieniu i wypełnienie jej wartościami
CREATE TABLE change_type (change_type_id integer, change_name varchar(50));
INSERT INTO change_type (change_type_id, change_name) 
	VALUES (1, 'exclusions') ,(2, 'extras');

--Stworzenie nowej tabeli przechowującej tabelę wszystkich zmian w zamówieniach i wypełnienie jej wartościami na postawie customer_orders
CREATE TABLE change_orders (change_id integer GENERATED ALWAYS AS IDENTITY, customer_order_id integer, change_type_id integer, topping_id integer);

--Wypełnienie tabeli wartościami z wykluczeniami (exclusions) z zamówien
INSERT INTO change_orders (customer_order_id, change_type_id, topping_id)
	SELECT
		order_id
		, 1 
		, TRIM(UNNEST(regexp_split_to_array(exclusions, ',')))::integer
	FROM customer_orders
	WHERE exclusions IS NOT NULL;

--Wypełnienie tabeli wartościami z dodatkami (extras) do zamówien
INSERT INTO change_orders (customer_order_id, change_type_id, topping_id)
	SELECT
		order_id
		, 2
		, TRIM(UNNEST(regexp_split_to_array(extras, ',')))::integer
	FROM customer_orders
	WHERE extras IS NOT NULL;


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
	EXTRACT(dow from order_time::timestamp) AS weekday
	,COUNT(*) AS number_of_orders
FROM customer_orders
GROUP BY EXTRACT(dow from order_time::timestamp)
ORDER BY weekday;

-- B1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
	TO_CHAR(registration_date, 'W')  AS week_no
	,COUNT(*) AS signed_up_runners
FROM runners
GROUP BY week_no
ORDER BY week_no ASC;

-- B2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH orders AS (
	SELECT 
		 DISTINCT co.order_time 
		,ro.runner_id AS runner
		,co.order_id 
		,ro.pickup_time 
		,ro.pickup_time - co.order_time AS time
	FROM runner_orders ro
	LEFT JOIN customer_orders co 
		ON ro.order_id = co.order_id
	LEFT JOIN runners r 
		ON ro.runner_id = r.runner_id 
	WHERE ro.pickup_time IS NOT NULL
	ORDER BY runner, co.order_time 
)
SELECT 
	runner
	,TO_CHAR(AVG(time), 'HH24:MI:SS')
FROM orders
GROUP BY runner 
ORDER BY runner;

-- B3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH sq AS (
	SELECT 
		DISTINCT co.order_time
		,co.order_id
		,ro.pickup_time 
		,ro.pickup_time - co.order_time duration
		,COUNT(*) OVER(PARTITION BY co.order_id) AS number_of_orders
	FROM customer_orders co 
	LEFT JOIN runner_orders ro 
		ON co.order_id = ro.order_id
	WHERE ro.pickup_time  IS NOT NULL
	ORDER BY co.order_id
)
SELECT
	number_of_orders
	,TO_CHAR(AVG(duration), 'HH24:MI:SS') prep_time
FROM sq
GROUP BY number_of_orders
ORDER BY number_of_orders

-- B4. What was the average distance travelled for each customer?

SELECT 
	co.customer_id
	,ROUND(AVG(ro.distance)::numeric, 2)
FROM runner_orders ro
LEFT JOIN customer_orders co 
	ON ro.order_id = co.order_id 
WHERE ro.pickup_time IS NOT NULL
GROUP BY co.customer_id 
ORDER BY co.customer_id 

-- B5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(ro.duration) - MIN(ro.duration)
FROM runner_orders ro 
WHERE ro.cancellation IS NULL

-- B6.What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
	ro.runner_id
	,ro.order_id 
	,ROUND((ro.distance / ro.duration * 60)::numeric, 2) avg_speed
FROM runner_orders ro 
WHERE ro.cancellation IS NULL
ORDER BY avg_speed DESC

-- B7. What is the successful delivery percentage for each runner?
WITH successful_deliveries AS (
	SELECT 
		ro.runner_id 
		,SUM(CASE 
			WHEN ro.cancellation IS NULL THEN 1
			ELSE 0
		END)  successful_deliveries
	FROM runner_orders ro 
	GROUP BY ro.runner_id
	ORDER BY ro.runner_id 
	)
SELECT 
	ro.runner_id 
	,MAX(sd.successful_deliveries)::numeric / COUNT(*)::numeric * 100 successful_delivery_percentage
FROM runner_orders ro 
JOIN successful_deliveries sd
	ON ro.runner_id = sd.runner_id 
GROUP BY ro.runner_id 
ORDER BY ro.runner_id 

-- C1. What are the standard ingredients for each pizza?

SELECT 
	pn.pizza_name
	, STRING_AGG(pt.topping_name , ', ') --https://neon.com/postgresql/aggregate-functions/string_agg-function
FROM pizza_names pn
LEFT JOIN pizza_recipes pr 
	ON pn.pizza_id = pr.pizza_id 
LEFT JOIN pizza_toppings pt 
	ON pr.toppings = pt.topping_id 
GROUP BY pn.pizza_name 

-- C2. What was the most commonly added extra?

SELECT 
	pt.topping_name 
	, COUNT(*) added_extras
FROM change_orders cho
INNER JOIN change_type ct
	ON cho.change_type_id = ct.change_type_id 
INNER JOIN pizza_toppings pt 
	ON cho.topping_id = pt.topping_id 
WHERE ct.change_name = 'extras'
GROUP BY pt.topping_name
ORDER BY added_extras DESC
LIMIT 1;
 
-- C3. What was the most common exclusion?

SELECT 
	pt.topping_name 
	, COUNT(*) exlusions
FROM change_orders cho
INNER JOIN change_type ct
	ON cho.change_type_id = ct.change_type_id 
INNER JOIN pizza_toppings pt 
	ON cho.topping_id = pt.topping_id 
WHERE ct.change_name = 'exclusions'
GROUP BY pt.topping_name
ORDER BY exlusions DESC
LIMIT 1;

-- C4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;
SELECT * FROM customer_orders;
SELECT * FROM change_type;
SELECT * FROM change_orders;
