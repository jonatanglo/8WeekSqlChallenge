SELECT * FROM sales;

SELECT * FROM menu;

SELECT * FROM members;

SELECT * 
FROM sales s
LEFT JOIN menu men
	ON s.product_id = men.product_id
LEFT JOIN members mem
	ON s.customer_id = mem.customer_id 
ORDER BY s.customer_id ASC, s.order_date ASC;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price)
FROM sales s
LEFT JOIN menu m 
	ON s.product_id = m.product_id 
GROUP BY S.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id, COUNT(DISTINCT s.order_date)
FROM sales s
GROUP BY s.customer_id; 

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT customer_id, product_name
FROM (
	SELECT 
	s.customer_id
	, m.product_name 
	, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM sales s
	LEFT JOIN menu m 
		ON s.product_id = m.product_id 
)
WHERE rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	s.product_id
	, COUNT(s.product_id) number_of_sales
FROM sales s 
GROUP BY s.product_id 
ORDER BY number_of_sales DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name, count
FROM (
	SELECT s.customer_id, s.product_id, COUNT(s.product_id) count, RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) rank
	FROM sales s
	GROUP BY s.customer_id, s.product_id
) sq
LEFT JOIN menu m
		ON sq.product_id = m.product_id 
WHERE rank = 1	
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT sq.customer_id, m.product_name
FROM (
	SELECT s.customer_id, s.order_date, s.product_id, RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) rank
	FROM sales s 
	JOIN members m 
		ON s.customer_id  = m.customer_id 
	WHERE s.order_date >= m.join_date
) sq
LEFT JOIN menu m
	ON sq.product_id = m.product_id
WHERE rank = 1
ORDER BY sq.customer_id;

-- 7. Which item was purchased just before the customer became a member?
SELECT sq.customer_id, m.product_name
FROM (
	SELECT 
	s.customer_id
	, s.order_date
	, s.product_id
	, RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) rank
	FROM sales s 
	JOIN members m 
		ON s.customer_id  = m.customer_id 
	WHERE s.order_date < m.join_date
) sq
LEFT JOIN menu m
	ON sq.product_id = m.product_id
WHERE rank = 1
ORDER BY sq.customer_id; 

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
	s.customer_id
	,SUM(men.price)
	,COUNT(s.customer_id)
	FROM sales s 
JOIN members mem
	ON s.customer_id  = mem.customer_id 
LEFT JOIN menu men
	ON s.product_id = men.product_id 
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points)
FROM (
	SELECT 
		s.customer_id
		, s.product_id
		, men.product_name
		, men.price 
		, CASE 
			WHEN men.product_name = 'sushi' THEN men.price * 2 * 10
			ELSE men.price * 10
		END points
	FROM sales s
	LEFT JOIN menu men
		ON s.product_id = men.product_id 
)
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
	sq.customer_id, SUM(sq.points)
FROM (
	SELECT
		s.customer_id
		, s.order_date 
		, mem.join_date 
		, s.product_id
		, men.product_name
		, men.price
		,CASE 
			WHEN s.order_date BETWEEN mem.join_date AND mem.join_date + 7 THEN men.price * 2 * 10
			ELSE men.price * 10
		END points
	FROM sales s
	LEFT JOIN members mem
		ON s.customer_id  = mem.customer_id 
	LEFT JOIN menu men
		ON s.product_id = men.product_id 
		WHERE s.order_date < '2021-02-01'
) sq
GROUP BY sq.customer_id
ORDER BY customer_id;

-- *11
SELECT 
	s.customer_id 
	,s.order_date 
	,men.product_name 
	,men.price 
	,CASE 
		WHEN s.order_date < mem.join_date OR mem.join_date IS NULL THEN 'N'
		ELSE 'Y'
	END member
FROM sales s
LEFT JOIN members mem
	ON s.customer_id  = mem.customer_id 
LEFT JOIN menu men
	ON s.product_id = men.product_id 
ORDER BY s.customer_id, s.order_date;

-- *12
SELECT 
	s.customer_id 
	,s.order_date 
	,men.product_name 
	,men.price 
	,CASE 
		WHEN s.order_date < mem.join_date OR mem.join_date IS NULL THEN 'N'
		ELSE 'Y'
	END member
	,CASE 
		WHEN s.order_date < mem.join_date OR mem.join_date IS NULL THEN NULL
		--ELSE DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date)
		ELSE 
		DENSE_RANK() OVER(PARTITION BY 
			(CASE WHEN s.order_date < mem.join_date OR mem.join_date IS NULL THEN 0 ELSE 1 END) ORDER BY s.order_date)
	END --ranking
FROM sales s
LEFT JOIN members mem
	ON s.customer_id  = mem.customer_id 
LEFT JOIN menu men
	ON s.product_id = men.product_id 
ORDER BY s.customer_id, s.order_date; 


