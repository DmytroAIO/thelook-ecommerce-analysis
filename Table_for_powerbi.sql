WITH years AS (
	SELECT
		DATE('2023-01-01') AS start_date_2023,
		DATE('2023-12-31') AS end_date_2023,
		DATE('2024-01-01') AS start_date_2024,
		DATE('2024-12-31') AS end_date_2024
),RFM AS(
	SELECT
		ord_items.user_id,
		MAX(ord_items.created_at) as most_recently_purchase_date,
		DATE_PART('day', CURRENT_DATE - MAX(ord_items.created_at)) as recency,
		COUNT(DISTINCT ord_items.order_id) as frequency,
		SUM(ord_items.sale_price - prod.cost) as monetary
	FROM order_items ord_items
	JOIN products prod ON ord_items.product_id = prod.id
	JOIN years y ON TRUE
	WHERE
		ord_items.status = 'Complete'
		AND DATE(ord_items.created_at) BETWEEN y.start_date_2023 AND y.end_date_2023
	GROUP BY 1
),
rfm_calc AS (
	SELECT
		*,
		NTILE(4) OVER (ORDER BY recency) as rfm_recency,
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
), first_buy_info AS (
	SELECT
		user_id,
		MIN(DATE(created_at)) as first_buy
	FROM order_items
	JOIN years y ON TRUE
	WHERE
		DATE(created_at) BETWEEN y.start_date_2023 AND y.end_date_2023
	GROUP BY 1
),orders_info AS (
	SELECT
		oi.user_id,
		DATE(oi.created_at) AS order_date,
		oi.order_id,
		u.country,
		u.gender,
		CASE 
	    	WHEN u.age < 12 THEN '12<'
	    	WHEN u.age BETWEEN 12 AND 18 THEN '12-18'
			WHEN u.age BETWEEN 18 AND 25 THEN '18-25'
	    	WHEN u.age BETWEEN 25 AND 35 THEN '25-35'
	    	WHEN u.age BETWEEN 35 AND 55 THEN '35-55'
			WHEN u.age BETWEEN 55 AND 65 THEN '55-65'
			ELSE '65+' END AS age_group,
		p.category AS product_category,
		p.brand,
		oi.status,
		p.cost AS cost_price,
		oi.sale_price,
		TO_CHAR(fb.first_buy, 'YYYY-MM') AS cohort_month,
		(DATE_PART('month', oi.created_at) - DATE_PART('month', fb.first_buy)) AS month_num
	FROM order_items oi
	JOIN products p ON oi.product_id = p.id
	JOIN users u ON oi.user_id = u.id
	JOIN first_buy_info fb ON oi.user_id = fb.user_id
	JOIN years y ON TRUE
	WHERE
		DATE(oi.created_at) BETWEEN y.start_date_2023 AND y.end_date_2023
)


INSERT INTO orders_ecommerce
SELECT
	oi.user_id,
	oi.order_id,
	oi.country,
	oi.order_date,
	oi.gender,
	oi.age_group,
	rfm_segm.recency,
	rfm_segm.frequency,
	rfm_segm.monetary,
	oi.product_category,
	oi.brand,
	oi.status,
	rfm_segm.rfm_segment,
	oi.cost_price,
	oi.sale_price,
	oi.cohort_month,
	oi.month_num
FROM orders_info oi
FULL JOIN rfm_segmentation rfm_segm ON oi.user_id = rfm_segm.user_id


