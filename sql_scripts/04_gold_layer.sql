-- BUSINESS QUESTIONS --
------------------------------------------------------------------------------------------------------------------------
-- 1) How did monthly Gross Merchandise Value (GMV) evolve over time? What was the month-over-month growth rate, and 
-- are there any observable seasonal patterns?

-- 2) What is the average order value (AOV)? How frequently do customers purchase, and what 
-- percentage of customers make repeat purchases?

-- 3) What is the average actual delivery time across different states, and how does it compare to the estimated 
-- delivery date?

-- 4) Which five product categories generate the highest Gross Merchandise Value (GMV) in the three states with 
-- the highest overall GMV?

-- GOLD LAYER DESIGN --
------------------------------------------------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS gold;

-- gold.orders
-- granularity: one row represents one order
-- order_id, customer_unique_id, customer_state, order_purchase_timestamp, order_status, items_value, freight_value, 
-- total_payment_value, order_delivered_customer_date, order_estimated_delivery_date
 
CREATE OR REPLACE VIEW gold.orders AS
WITH CTE_items_per_order AS
 	(SELECT 
 		order_id,
 		SUM(price) AS items_value,
 		SUM(freight_value) AS freight_value
 	FROM silver.order_items
 	GROUP BY order_id), 
 CTE_payments_per_order AS 
 	(SELECT
 		order_id,
 		SUM(payment_value) AS total_payment_value
 	FROM silver.order_payments
 	GROUP BY order_id)
 
SELECT
	o.order_id,
	c.customer_unique_id,
	c.customer_state,
	o.order_purchase_timestamp,
	o.order_status,
	ipo.items_value,
	ipo.freight_value,
	ppo.total_payment_value,
	o.order_delivered_customer_date, 
	o.order_estimated_delivery_date
from silver.orders o
LEFT JOIN silver.customers c
	ON o.customer_id = c.customer_id
LEFT JOIN CTE_items_per_order ipo
	ON o.order_id = ipo.order_id
LEFT JOIN CTE_payments_per_order ppo
	ON o.order_id = ppo.order_id;

-- checking whether all rows get to gold.orders and the transformation was done correctly
SELECT
	COUNT(*) AS row_count,
	SUM(items_value) AS items_value_sum,
	SUM(freight_value) AS freight_value_sum,
	SUM(total_payment_value) AS payment_value_sum
FROM gold.orders;

SELECT 
	COUNT(*) AS row_count
FROM silver.orders;

SELECT
	SUM(price) AS items_value_sum,
	SUM(freight_value) AS freight_value_sum
FROM silver.order_items;

SELECT
	SUM(payment_value) AS payment_value_sum
FROM silver.order_payments;

-- checking whether the granularity is correctly transformed
SELECT 
	COUNT(order_id) AS order_id_count,
	COUNT(DISTINCT order_id) AS distinct_order_id_count
FROM gold.orders;

-- checking the NULL values
SELECT
	COUNT(CASE WHEN customer_unique_id IS NULL THEN 1 END) AS customer_unique_id_null_amount,
	COUNT(CASE WHEN customer_state IS NULL THEN 1 END) AS customer_state_null_amount,
	COUNT(CASE WHEN items_value IS NULL THEN 1 END) AS items_value_null_amount,
	COUNT(CASE WHEN freight_value IS NULL THEN 1 END) AS freight_value_null_amount,
	COUNT(CASE WHEN total_payment_value IS NULL THEN 1 END) AS total_payment_value_null_amount
FROM gold.orders;

SELECT
	COUNT(CASE WHEN customer_unique_id IS NULL THEN 1 END) AS customer_unique_id_null_amount,
	COUNT(CASE WHEN customer_state IS NULL THEN 1 END) AS customer_state_null_amount
FROM silver.customers;

SELECT
	COUNT(CASE WHEN price IS NULL THEN 1 END) AS items_value_null_amount,
	COUNT(CASE WHEN freight_value IS NULL THEN 1 END) AS freight_value_null_amount
FROM silver.order_items;

SELECT
    order_status,
    COUNT(*) AS orders_count
FROM gold.orders
WHERE items_value IS NULL
GROUP BY order_status
ORDER BY orders_count DESC;

SELECT
	COUNT(CASE WHEN payment_value IS NULL THEN 1 END) AS total_payment_value_null_amount
FROM silver.order_payments;

SELECT
    order_id,
    order_status,
    total_payment_value
FROM gold.orders
WHERE total_payment_value IS NULL;

SELECT *
FROM gold.orders
WHERE order_id = 'bfbd0f9bdef84302105ad712db648a6c';

SELECT *
FROM silver.order_payments
WHERE order_id = 'bfbd0f9bdef84302105ad712db648a6c';

-- Gold layer validation:
-- All orders have matching customer records.
-- 775 orders have no matching order items, most are unavailable (603) or canceled (164).
-- One delivered order has no matching payment record.
-- The order has valid item and freight values.
-- Missing values were retained as NULL.
------------------------------------------------------------------------------------------------------------------------	
-- gold.order_items
-- granularity: one row represents one item within an order.
-- order_id, order_item_id, product_id, product_category, price, freight_value

CREATE OR REPLACE VIEW gold.order_items AS
SELECT
	oi.order_id,
	oi.order_item_id,
	oi.product_id,
	coalesce(ct.product_category_name_english, p.product_category_name, 'Uncategorized') AS product_category,
	oi.price,
	oi.freight_value
FROM silver.order_items oi
LEFT JOIN silver.products p 
	ON oi.product_id = p.product_id
LEFT JOIN silver.category_translation ct 
	ON p.product_category_name = ct.product_category_name;

-- checking whether all rows get to gold.order_items and the transformation was done correctly
SELECT
	COUNT(*) AS row_count
FROM gold.order_items;

SELECT 
	COUNT(*) AS row_count
FROM silver.order_items;

SELECT
	order_id,
	order_item_id
FROM gold.order_items
GROUP BY order_id, order_item_id 
HAVING COUNT(*) > 1;

SELECT 
	SUM(price) AS price_sum,
	SUM(freight_value) AS freight_value_sum
FROM gold.order_items;

SELECT 
	SUM(price) AS price_sum,
	SUM(freight_value) AS freight_value_sum
FROM silver.order_items;

SELECT
	product_category
FROM gold.order_items
WHERE product_category IS NULL;

SELECT 
	COUNT(*) AS row_count
FROM gold.order_items
WHERE product_category = 'Uncategorized';

SELECT *
FROM silver.order_items oi
LEFT JOIN silver.products p
	ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Gold layer validation:
-- Row count matches silver.order_items.
-- No duplicate order_id + order_item_id combinations found.
-- Total price and freight values match Silver source data.
-- All order items have matching product records.
-- 1,603 order items have no assigned product category.
-- Missing product categories are labeled as 'Uncategorized'.
