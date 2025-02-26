DROP TABLE IF EXISTS distribution_centers;
CREATE TABLE distribution_centers (
	id INT,
	name VARCHAR(255),
	latitude FLOAT,
	longitude FLOAT,
	distribution_center_geom VARCHAR(255)
);


DROP TABLE IF EXISTS products;
CREATE TABLE products (
	id INT,
	cost numeric(10, 2),
	category VARCHAR(255),
	name VARCHAR(255),
	brand VARCHAR(255),
	retail_price numeric(10, 2),
	department VARCHAR(255),
	sku VARCHAR(255),
	distribution_center_id INT
);

	
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
	order_id INT,
	user_id INT,
	status VARCHAR(32),
	gender VARCHAR (1),
	created_at timestamp,
	returned_at timestamp,
	shipped_at timestamp,
	delivered_at timestamp,
	num_of_item INT
);


DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id INT,
	first_name VARCHAR(255),
	last_name VARCHAR(255),
	email VARCHAR(255),
	age INT,
	gender VARCHAR(1),
	state VARCHAR(255),
	street_address VARCHAR(255),
	postal_code VARCHAR(255),
	city VARCHAR(255),
	country VARCHAR(255),
	latitude FLOAT,
	longitude FLOAT,
	traffic_source VARCHAR(255),
	created_at timestamp,
	user_geom VARCHAR(255)
);


DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
	id INT,
	order_id INT,
	user_id INT,
	product_id INT,
	inventory_item_id INT,
	status VARCHAR(32),
	created_at timestamp,
	shipped_at timestamp,
	delivered_at timestamp,
	returned_at timestamp,
	sale_price numeric(10, 2)
);


DROP TABLE IF EXISTS inventory_items;
CREATE TABLE inventory_items (
	id INT,
	product_id INT,
	created_at timestamp,
	sold_at timestamp,
	cost numeric(10, 2),
	product_category VARCHAR(255),
	product_name VARCHAR(255),
	product_brand VARCHAR(255),
	product_retail_price numeric(10, 2),
	product_department VARCHAR(255),
	product_sku VARCHAR(255),
	product_distribution_center_id INT
);


DROP TABLE IF EXISTS events;
CREATE TABLE events (
	id INT,
	user_id INT,
	sequence_number INT,
	session_id VARCHAR(255),
	created_at timestamp,
	ip_address VARCHAR(255),
	city VARCHAR(255),
	state VARCHAR(255),
	postal_code VARCHAR(255),
	browser VARCHAR(255),
	traffic_source VARCHAR(255),
	uri VARCHAR(255),
	event_type VARCHAR(255)
);

DROP TABLE IF EXISTS orders_and_segments;
CREATE TABLE orders_and_segments (
	user_id INT,
    order_id INT,
	country VARCHAR(255),
	order_date DATE,
	gender VARCHAR(1),
	age_group TEXT,
	product_category VARCHAR(255),
	product_name VARCHAR(255),
	status VARCHAR(32),
	rfm_segment TEXT,
	cost_price numeric(10, 2),
	sale_price numeric(10, 2)
);

DROP TABLE IF EXISTS orders_ecommerce;
CREATE TABLE orders_ecommerce (
	user_id INT,
    order_id INT,
	country VARCHAR(255),
	order_date DATE,
	gender VARCHAR(1),
	age_group TEXT,
	recency INT,
	frequency INT,
	monetary numeric(10, 2),
	product_category VARCHAR(255),
	brand VARCHAR(255),
	status VARCHAR(32),
	rfm_segment TEXT,
	cost_price numeric(10, 2),
	sale_price numeric(10, 2),
	cohort_month TEXT,
	month_num INT
);











