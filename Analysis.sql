-- Monthly Sales
SELECT 
	DATE_TRUNC('month', oi.created_at) AS order_date,
	SUM(oi.sale_price) AS revenue,
	COUNT(DISTINCT oi.order_id) AS order_count,
	COUNT(DISTINCT oi.user_id) AS customers_purchased
FROM order_items oi
WHERE oi.status = 'Complete'
GROUP BY 1
ORDER BY 1 DESC


--Customers by country and gender
WITH customers AS (
	SELECT
	    DISTINCT oi.user_id,
	    SUM(CASE WHEN u.gender = 'M' THEN 1 ELSE null END) AS male,
	    SUM(CASE WHEN u.gender = 'F' THEN 1 ELSE null END) AS female,
	    u.country AS country
    FROM order_items oi
    JOIN users u ON oi.user_id = u.id
    WHERE oi.status = 'Complete'
    GROUP BY 1, 4
)

SELECT
	country,
	COUNT(DISTINCT user_id) AS customers_count,
	COUNT(female) AS female,
	COUNT(male) AS male
FROM customers
GROUP BY 1
ORDER BY 2 DESC;


--Revenue, orders and customers by month
SELECT
	EXTRACT(MONTH FROM oi.created_at) AS month,
	ROUND(SUM(oi.sale_price), 2) AS revenue,
	COUNT(DISTINCT oi.order_id) AS orders,
	COUNT(DISTINCT oi.user_id) AS customers
FROM order_items oi
JOIN orders AS o  ON oi.order_id = o.order_id
WHERE oi.status = 'Complete'
GROUP BY 1
ORDER BY 2 DESC;


--Analysis of the distribution of users by age group, gender and country
WITH age_group as (
	SELECT
		CASE
			WHEN u.age < 12 THEN '12<'
	    	WHEN u.age BETWEEN 12 AND 18 THEN '12-18'
			WHEN u.age BETWEEN 18 AND 25 THEN '18-25'
	    	WHEN u.age BETWEEN 25 AND 35 THEN '25-35'
	    	WHEN u.age BETWEEN 35 AND 55 THEN '35-55'
			WHEN u.age BETWEEN 55 AND 65 THEN '35-55'
			ELSE '65+' END AS age_group,
		u.gender,
		u.country,
		count(o.user_id) as total_user
	FROM orders o
	JOIN users u ON o.user_id = u.id
	WHERE
		status = 'Complete'
	GROUP BY 1,2,3
	ORDER BY 4 desc
),
user_distribution as (
	SELECT
		age_group,
		gender,
		country,
		total_user, 
		SUM(total_user) OVER(ORDER BY total_user) as running_total_user
	FROM age_group
	ORDER BY total_user desc
)
 
SELECT
	*,
	ROUND((total_user/running_total_user) * 100, 2) as percentage
FROM user_distribution


--Revenue and quantity by gender
SELECT
	u.gender,
	COUNT(oi.order_id) as total_quantity,
	SUM(sale_price) as revenue
FROM order_items oi
JOIN users u ON oi.user_id = u.id
GROUP BY 1
ORDER BY 3 DESC

	

--Users who purchased on the same day they registered
SELECT
    u.id,
    u.created_at AS registration_date,
    MIN(e.created_at) AS first_purchase_date
FROM events e
LEFT JOIN users u ON e.user_id = u.id
WHERE
    e.event_type = 'purchase' and DATE(u.created_at) = DATE(e.created_at)
GROUP BY u.id, u.created_at
ORDER BY 1


--Users without orders
SELECT
	*
FROM users
WHERE
	id not in (
		SELECT
			distinct user_id
		FROM order_items
)


--Analysis of sold items by distribution center and country
SELECT
	dc.name as distribution_center,
	u.country as country_destination,
	COUNT(oi.order_id) as total_item_sold
FROM distribution_centers dc
JOIN products p ON dc.id = p.distribution_center_id
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN users u ON oi.user_id = u.id
WHERE oi.status = 'Complete'
GROUP BY 1,2
ORDER BY 3 DESC;

	
--Average number of days from registration to purchase
WITH first_purchase AS (
	SELECT
		u.id AS user_id,
		u.created_at AS reg_date,
		MIN(oi.created_at) AS fp_date
	FROM users u
	JOIN order_items oi ON u.id = oi.user_id
	GROUP BY 1,2
	ORDER BY 2
)


SELECT
	AVG(DATE(fp_date) - DATE(reg_date)) as avg_days
FROM first_purchase;


--Top 10 users for the number of successful purchases
SELECT
	user_id,
	COUNT(*) as total_orders
FROM orders
WHERE
	status = 'Complete'
GROUP BY 1
HAVING
	COUNT(*) > 1
ORDER BY 2 DESC
LIMIT 10


--Revenue and quantity by brand
SELECT
	p.brand, --p.category for check by category
	SUM(oi.sale_price) as revenue,
	COUNT(order_id) as quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.id
WHERE
	oi.status = 'Complete'
GROUP BY 1
ORDER BY 2 DESC --BY 2 for check top by revenue, BY 3 for check top by quantity


--Checking whether there are sales at a discount
SELECT
	o_items.product_id,
	o_items.sale_price,
	prod.cost,
	prod.retail_price
FROM order_items o_items
LEFT JOIN products prod ON o_items.product_id = prod.id
WHERE
	o_items.sale_price < prod.retail_price


--Calculation of profit from product sales
SELECT
	o_items.product_id,
	prod.name,
	SUM(o_items.sale_price) - SUM(prod.cost) as profit
FROM order_items o_items
LEFT JOIN products prod ON o_items.product_id = prod.id
GROUP BY 1, 2
ORDER BY 3 DESC


--Calculating how much time passed between each customer's first and last purchase
SELECT 
    user_id,
    MIN(created_at) AS first_order,
    MAX(created_at) AS last_order,
    EXTRACT(DAY FROM (MAX(created_at) - MIN(created_at))) AS days_between_orders
FROM orders
WHERE status = 'Complete'
GROUP BY 1
ORDER BY 4 DESC


--Brands cancel and returns
SELECT 
	p.brand, --p.category if want to check by category
	SUM(CASE WHEN oi.status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled,
	SUM(CASE WHEN oi.status = 'Returned' THEN 1 ELSE 0 END) AS Returned
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY 1
ORDER BY 2 DESC;


--Comparison of current sales with the previous month
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', created_at) AS order_date,
        SUM(sale_price) AS total_sales
    FROM order_items
    WHERE status = 'Complete'
    GROUP BY 1
)
SELECT 
    order_date,
    total_sales,
    LAG(total_sales) OVER (ORDER BY order_date) AS previous_month_sales,
    total_sales - LAG(total_sales) OVER (ORDER BY order_date) AS sales_difference
FROM monthly_sales
ORDER BY 1;


--RFM analysis
WITH RFM AS(
	SELECT
		ord_items.user_id,
		MAX(ord_items.created_at) as most_recently_purchase_date,
		DATE_PART('day', CURRENT_DATE - MAX(ord_items.created_at)) as recency,
		COUNT(DISTINCT ord_items.order_id) as frequency,
		SUM(ord_items.sale_price - prod.cost) as monetary
	FROM order_items ord_items
	JOIN products prod ON ord_items.product_id = prod.id
	WHERE
		ord_items.status = 'Complete'
	GROUP BY 1
	HAVING
		DATE_PART('day', CURRENT_DATE - MAX(ord_items.created_at)) <= 365
),
rfm_calc AS (
	SELECT
		*,
		NTILE(4) OVER (ORDER BY recency DESC) as rfm_recency,
		NTILE(4) OVER (ORDER BY frequency) as rfm_frequency,
		NTILE(4) OVER (ORDER BY monetary) as rfm_monetary
	FROM RFM
	 ORDER BY rfm_monetary
),
rfm_tb AS (
	SELECT 
		*,
		rfm_recency + rfm_frequency + rfm_monetary as rfm_score,
		CAST(CONCAT(rfm_recency, rfm_frequency, rfm_monetary) AS INT) as rfm
	FROM rfm_calc
),
rfm_segmentation AS (
	SELECT 
		*,
		CASE
			WHEN rfm IN (444,443,434,433) THEN 'Churned Best Customer'
	        WHEN rfm IN (342,332,341,331) THEN 'Declining Customer'
	        WHEN rfm IN (344,343,334,333) THEN 'Slipping Best Customer'
	        WHEN rfm IN (142,141,143,131,132,133,242,241,243,231,232,233) THEN 'Active Loyal Customer'
	        WHEN rfm IN (112,111,113,114,211,213,214,212) THEN 'New Customer'
	        WHEN rfm IN (144) THEN 'Best Customer'
	        WHEN rfm IN (411,412,413,414,313,312,314,311) THEN 'One Time Customer'
	        WHEN rfm IN (222,221,223,224) THEN 'Potential Customer'
			ELSE 'Customer' END AS rfm_segment
	FROM rfm_tb
)

SELECT
	*
FROM rfm_segmentation


--Users distribution by traffic, event types
SELECT
	traffic_source,
	event_type,
	COUNT(DISTINCT user_id) AS users
FROM events
WHERE
	user_id is not null
GROUP BY 1,2
ORDER BY 3 DESC

	
--Determination of the most effective categories of products by the coefficient of repeat purchases
WITH repeat_customers AS (
	SELECT
		o_i.user_id,
		p.category,
		COUNT(DISTINCT o_i.order_id) as total_orders
	FROM order_items o_i
	JOIN products p ON o_i.product_id = p.id
	GROUP BY 1, 2
	HAVING
		COUNT(DISTINCT o_i.order_id) > 1
)

SELECT 
    category, 
    COUNT(user_id) AS repeat_customers,
    ROUND(COUNT(DISTINCT user_id) * 100.0 / 
        (SELECT COUNT(DISTINCT user_id) FROM orders WHERE status = 'Complete'), 3)
        AS repeat_rate
FROM repeat_customers
GROUP BY 1
ORDER BY 3 DESC;


--Analysis of the frequency of product returns
WITH returned_orders AS (
	SELECT
		product_id,
		COUNT(*) as count_returns
	FROM order_items
	WHERE
		status = 'Returned'
	GROUP BY 1
),
total_orders AS (
	SELECT
		product_id,
		COUNT(*) as count_sales
	FROM order_items
	GROUP BY 1
)

SELECT 
    p.name,
    ts.count_sales,
    rs.count_returns,
    ROUND((rs.count_returns::decimal / ts.count_sales) * 100, 2) AS return_percentage
FROM total_orders ts
RIGHT JOIN returned_orders rs ON ts.product_id = rs.product_id
JOIN products p ON ts.product_id = p.id
ORDER BY 4 DESC, 3 DESC


--Identification of customers with the largest increase in spending by month
WITH customer_monthly_spending AS (
    SELECT
        user_id,
		order_id,
        DATE_TRUNC('month', created_at) AS date,
        SUM(sale_price) AS monthly_spending
    FROM order_items
	WHERE
		status = 'Complete'
    GROUP BY 1, 2, 3
	ORDER BY 3
),
spending_change AS (
    SELECT
        user_id,
        date,
        monthly_spending,
        LAG(monthly_spending) OVER (PARTITION BY user_id ORDER BY date) AS previous_month_spending
    FROM customer_monthly_spending
)
SELECT
    user_id,
    date,
    monthly_spending,
    previous_month_spending,
    (monthly_spending - previous_month_spending) AS spending_difference
FROM spending_change
WHERE
    previous_month_spending IS NOT NULL
ORDER BY 2 DESC, 5 DESC