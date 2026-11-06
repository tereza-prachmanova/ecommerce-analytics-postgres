-- EXPLORATORY DATA ANALYSIS --
------------------------------------------------------------------------------------------------------------------------
-- silver.customers 

-- Dimension exploration
SELECT	DISTINCT 
	customer_state
FROM silver.customers
ORDER BY customer_state;

SELECT	DISTINCT 
	customer_state,
	customer_city
FROM silver.customers
ORDER BY customer_state, customer_city;

-- Measures exploration
SELECT
	COUNT(DISTINCT customer_unique_id) AS customer_unique_id_count
FROM silver.customers;

-- Magnitude analysis
SELECT 
	customer_state,
	COUNT(DISTINCT customer_unique_id) AS customer_unique_id_count
FROM silver.customers
GROUP BY customer_state
ORDER BY COUNT(DISTINCT customer_unique_id) DESC;

SELECT 
	customer_city,
	customer_state,
	COUNT(DISTINCT customer_unique_id) AS customer_unique_id_count
FROM silver.customers
GROUP BY customer_city, customer_state
ORDER BY COUNT(DISTINCT customer_unique_id) DESC;

------------------------------------------------------------------------------------------------------------------------
-- silver.orders 

-- Dimension exploration
SELECT
	DISTINCT order_status 
FROM silver.orders;

-- Date exploration
SELECT
	MIN(order_purchase_timestamp) AS min_order_purchase_timestamp,
	MAX(order_purchase_timestamp) AS max_order_purchase_timestamp,
	MIN(order_approved_at) AS min_order_approved_at,
	MAX(order_approved_at) AS max_order_approved_at,
	MIN(order_delivered_carrier_date) AS min_order_delivered_carrier_date,
	MAX(order_delivered_carrier_date) AS max_order_delivered_carrier_date,
	MIN(order_delivered_customer_date) AS min_order_delivered_customer_date,
	MAX(order_delivered_customer_date) AS max_order_delivered_customer_date,
	MIN(order_estimated_delivery_date) AS min_order_estimated_delivery_date,
	MAX(order_estimated_delivery_date) AS max_order_estimated_delivery_date
FROM silver.orders;

-- Measures exploration
SELECT 
	COUNT(DISTINCT order_id) AS count_of_orders
FROM silver.orders;

-- Magnitude analysis
SELECT
	order_status,	
	COUNT(DISTINCT order_id) AS count_of_orders
FROM silver.orders
GROUP BY order_status
ORDER BY COUNT(DISTINCT order_id) DESC;

-- Time analysis
SELECT 
	EXTRACT(YEAR FROM order_purchase_timestamp) AS order_purchase_year,
	COUNT(DISTINCT order_id) AS count_of_orders
FROM silver.orders
GROUP BY EXTRACT(YEAR FROM order_purchase_timestamp)
ORDER BY order_purchase_year;

SELECT 
	EXTRACT(YEAR FROM order_purchase_timestamp) AS order_purchase_year,
	EXTRACT(MONTH FROM order_purchase_timestamp) AS order_purchase_month,
	COUNT(DISTINCT order_id) AS count_of_orders
FROM silver.orders
GROUP BY EXTRACT(YEAR FROM order_purchase_timestamp), EXTRACT(MONTH FROM order_purchase_timestamp)
ORDER BY order_purchase_year, order_purchase_month;

SELECT 
	DATE_TRUNC('month', order_purchase_timestamp) AS order_purchase_month,
	COUNT(DISTINCT order_id) AS count_of_orders
FROM silver.orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY order_purchase_month;

------------------------------------------------------------------------------------------------------------------------
-- silver.order_items 

-- Dimension exploration
SELECT
	COUNT(*) AS order_items_count,	
	COUNT(DISTINCT order_id) AS orders_count,
	COUNT(DISTINCT product_id) AS products_count,	
	COUNT(DISTINCT seller_id) AS sellers_count
FROM silver.order_items;

-- Measures exploration
SELECT 
	SUM(price) AS sum_price, 
	AVG(price) AS avg_price,
	MIN(price) AS min_price,
	MAX(price) AS max_price,
	SUM(freight_value) AS sum_freight_value,
	AVG(freight_value) AS avg_freight_value,
	MIN(freight_value) AS min_freight_value,
	MAX(freight_value) AS max_freight_value
FROM silver.order_items;

-- Date exploration
SELECT
	MIN(shipping_limit_date) AS min_shipping_limit_date,
	MAX(shipping_limit_date) AS max_shipping_limit_date
FROM silver.order_items;

-- Magnitude analysis
WITH CTE_items_per_order AS 
(SELECT 
    order_id,
    COUNT(order_item_id) AS item_count
FROM silver.order_items
GROUP BY order_id)

SELECT
	AVG(item_count) AS avg_items_per_order
FROM CTE_items_per_order;

-- Ranking analysis
SELECT 
	product_id,
	SUM(price) AS total_price
FROM silver.order_items
GROUP BY product_id
ORDER BY SUM(price) DESC;

SELECT 
	product_id,
	COUNT(order_id) AS items_sold
FROM silver.order_items
GROUP BY product_id
ORDER BY COUNT(order_id) DESC;

------------------------------------------------------------------------------------------------------------------------
-- silver.order_payments 

-- Dimension exploration
SELECT
	DISTINCT payment_type
FROM silver.order_payments;

-- Measures exploration
SELECT 
	AVG(payment_installments) AS avg_payment_installments, 
	MIN(payment_installments) AS min_payment_installments,
	MAX(payment_installments) AS max_payment_installments,
	SUM(payment_value) AS sum_payment_value,
	AVG(payment_value) AS avg_payment_value,
	MIN(payment_value) AS min_payment_value,
	MAX(payment_value) AS max_payment_value
FROM silver.order_payments;

-- Magnitude analysis
SELECT
	payment_type,
	SUM(payment_value) AS sum_payment_value
FROM silver.order_payments
GROUP BY payment_type
ORDER BY SUM(payment_value) DESC;

SELECT
	payment_type,
	AVG(payment_installments) AS avg_payment_installments
FROM silver.order_payments
GROUP BY payment_type
ORDER BY AVG(payment_installments) DESC;

SELECT
	payment_type,
	COUNT(*) AS payment_count
FROM silver.order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;

------------------------------------------------------------------------------------------------------------------------
-- silver.order_reviews 

-- Dimension exploration
SELECT
	COUNT(*) AS reviews_count,	
	COUNT(DISTINCT order_id) AS orders_count,
	COUNT(review_comment_message) AS comment_message_count,
	COUNT(review_comment_title) AS comment_title_count
FROM silver.order_reviews;

-- Measures exploration
SELECT
	MIN(review_score) AS min_review_score,
	MAX(review_score) AS max_review_score,
	AVG(review_score) AS avg_review_score,
	COUNT(review_score) AS review_score_count
FROM silver.order_reviews;

-- Date exploration
SELECT 
	MIN(review_creation_date) AS min_review_creation_date, 
	MAX(review_creation_date) AS max_review_creation_date,
	MIN(review_answer_timestamp) AS min_review_answer_timestamp,
	MAX(review_answer_timestamp) AS max_review_answer_timestamp
FROM silver.order_reviews;

-- Magnitude analysis
SELECT
	review_score,
	COUNT(review_score) AS score_count,
	COUNT(review_comment_message) AS comment_message_count,
	COUNT(review_comment_title) AS comment_title_count
FROM silver.order_reviews
GROUP BY review_score;

SELECT	
	review_score,
	COUNT(*) AS comment_count
FROM silver.order_reviews
WHERE review_comment_message IS NOT NULL OR review_comment_title IS NOT NULL 
GROUP BY review_score
ORDER BY comment_count DESC;

-- Time analysis
SELECT
	DATE_TRUNC('month', review_answer_timestamp) AS review_month,
	COUNT(review_score) AS review_score_count,
	COUNT(review_comment_message) AS comment_message_count,
	COUNT(review_comment_title) AS comment_title_count
FROM silver.order_reviews
WHERE review_answer_timestamp IS NOT NULL
GROUP BY DATE_TRUNC('month', review_answer_timestamp)
ORDER BY review_month;

SELECT
	CAST(review_answer_timestamp AS DATE) - review_creation_date AS days_to_review_after_request
FROM silver.order_reviews
WHERE review_answer_timestamp IS NOT NULL;

SELECT
	CAST(review_answer_timestamp AS DATE) - review_creation_date AS days_to_review_after_request,
	COUNT(*) AS reviews_count
FROM silver.order_reviews
WHERE review_answer_timestamp IS NOT NULL
GROUP BY CAST(review_answer_timestamp AS DATE) - review_creation_date
ORDER BY reviews_count DESC;

SELECT
	MIN(CAST(review_answer_timestamp AS DATE) - review_creation_date) AS min_days_to_review_after_request,
	MAX(CAST(review_answer_timestamp AS DATE) - review_creation_date) AS max_days_to_review_after_request,
	AVG(CAST(review_answer_timestamp AS DATE) - review_creation_date) AS avg_days_to_review_after_request
FROM silver.order_reviews;

SELECT *
FROM silver.order_reviews
WHERE (CAST(review_answer_timestamp AS DATE) - review_creation_date) = 518;

SELECT 
	COUNT(CASE WHEN (CAST(review_answer_timestamp AS DATE) - review_creation_date) > 30 THEN 1 END) AS review_after_30_days,
	COUNT(CASE WHEN (CAST(review_answer_timestamp AS DATE) - review_creation_date) > 90 THEN 1 END) AS review_after_90_days,
	COUNT(CASE WHEN (CAST(review_answer_timestamp AS DATE) - review_creation_date) > 365 THEN 1 END) AS review_after_365_days,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(review_answer_timestamp AS DATE) - review_creation_date) AS median_days_to_review_after_request
FROM silver.order_reviews;

-- Review response times are right-skewed.
-- Median response time is 1 day, while the average is 2.58 days.
-- The maximum response time is 518 days.
-- 10 reviews were submitted more than 365 days after the review request.
-- These unusually long response times were retained, no data error was confirmed.
------------------------------------------------------------------------------------------------------------------------
-- silver.products 

-- Dimension exploration
SELECT 
	DISTINCT product_category_name
FROM silver.products;

-- Measures exploration
SELECT 
	MIN(product_name_length) AS min_product_name_length,
	MAX(product_name_length) AS max_product_name_length,
	AVG(product_name_length) AS avg_product_name_length,
	MIN(product_description_length) AS min_product_description_length,
	MAX(product_description_length) AS max_product_description_length,
	AVG(product_description_length) AS avg_product_description_length,
	MIN(product_photos_qty) AS min_product_photos_qty,
	MAX(product_photos_qty) AS max_product_photos_qty,
	AVG(product_photos_qty) AS avg_product_photos_qty,
	MIN(product_weight_g) AS min_product_weight_g,
	MAX(product_weight_g) AS max_product_weight_g,
	AVG(product_weight_g) AS avg_product_weight_g,
	MIN(product_length_cm) AS min_product_length_cm,
	MAX(product_length_cm) AS max_product_length_cm,
	AVG(product_length_cm) AS avg_product_length_cm,
	MIN(product_height_cm) AS min_product_height_cm,
	MAX(product_height_cm) AS max_product_height_cm,
	AVG(product_height_cm) AS avg_product_height_cm,
	MIN(product_width_cm) AS min_product_width_cm,
	MAX(product_width_cm) AS max_product_width_cm,
	AVG(product_width_cm) AS avg_product_width_cm
FROM silver.products;

-- Additional investigation: missing product categories
SELECT COUNT(*)
FROM silver.products
WHERE product_category_name IS NULL;

SELECT *
FROM silver.products
WHERE product_category_name IS NULL;

-- 610 out of 32 951 products (1,9 %) have no category.
-- Of these, 609 also lack name length, description length and photo quantity, while one product has only product_id.
-- Missing values were retained as NULL in Silver.

-- Magnitude analysis
SELECT
	product_category_name,	
	COUNT(*) AS product_count,
	AVG(product_photos_qty) AS avg_product_photos_qty
FROM silver.products
GROUP BY product_category_name
ORDER BY product_count DESC;

SELECT
	product_category_name,	
	AVG(product_weight_g) AS avg_product_weight_g,
	AVG(product_length_cm) AS avg_product_length_cm,
	AVG(product_height_cm) AS avg_product_height_cm,
	AVG(product_width_cm) AS avg_product_width_cm
FROM silver.products
GROUP BY product_category_name;

------------------------------------------------------------------------------------------------------------------------
-- silver.sellers 

-- Dimension exploration
SELECT DISTINCT
	seller_state
FROM silver.sellers;

SELECT DISTINCT
	seller_state,
	seller_city 
FROM silver.sellers
ORDER BY seller_state, seller_city;

SELECT
    COUNT(CASE WHEN seller_city IS NULL THEN 1 END) AS null_city_count,
    COUNT(CASE WHEN seller_state IS NULL THEN 1 END) AS null_state_count
FROM silver.sellers;

SELECT *
FROM silver.sellers
WHERE seller_city IS null;

SELECT
    seller_id,
    seller_city,
    seller_state
FROM bronze.olist_sellers_dataset
WHERE seller_id IN (
    'ceb7b4fb9401cd378de7886317ad1b47',
    '4b5f66b7adcf57f1ecc0d3c07dd6b177'
);

-- Two sellers have NULL values in seller_city.
-- Invalid source values (numeric string and email address) were replaced with NULL in Silver.

-- Measures exploration
SELECT
	COUNT(*) AS seller_count
FROM silver.sellers;

-- Magnitude analysis
SELECT
	seller_state,
	COUNT(*) AS seller_count
FROM silver.sellers
GROUP BY seller_state
ORDER BY seller_count DESC;

SELECT
	seller_state,
	seller_city,
	COUNT(*) AS seller_count
FROM silver.sellers
GROUP BY seller_state, seller_city
ORDER BY seller_count DESC;

------------------------------------------------------------------------------------------------------------------------
-- silver.geolocation 

-- Dimension exploration
SELECT DISTINCT 
	geolocation_state 
FROM silver.geolocation;

SELECT DISTINCT
	geolocation_state,
	geolocation_city 
FROM silver.geolocation
ORDER BY geolocation_state, geolocation_city;

SELECT
    COUNT(CASE WHEN geolocation_city IS NULL THEN 1 END) AS null_city_count,
    COUNT(CASE WHEN geolocation_state IS NULL THEN 1 END) AS null_state_count
FROM silver.geolocation;

SELECT *
FROM silver.geolocation
WHERE geolocation_city IS null;

SELECT *
FROM bronze.olist_geolocation_dataset
WHERE geolocation_city IS null;
-- One geolocation has NULL values in geolocation_city.
-- Generic source value (* cidade) was replaced with NULL in Silver.

-- Measures exploration
SELECT
	COUNT(*) AS geolocation_count
FROM silver.geolocation;

-- Magnitude analysis
SELECT
	geolocation_state,
	COUNT(*) AS geolocation_count
FROM silver.geolocation
GROUP BY geolocation_state
ORDER BY geolocation_count DESC;

SELECT
	geolocation_zip_code_prefix,
	COUNT(DISTINCT geolocation_state) AS geolocation_state_count,
	COUNT(DISTINCT geolocation_city) AS geolocation_city_count
FROM silver.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_state) > 1 OR COUNT(DISTINCT geolocation_city) > 1
ORDER BY geolocation_state_count, geolocation_city_count DESC;

SELECT DISTINCT 
	geolocation_zip_code_prefix,
	geolocation_state,
	geolocation_city
FROM silver.geolocation
WHERE geolocation_zip_code_prefix = '65935';

-- Some ZIP code prefixes are associated with multiple city names.
-- Example: prefix 65935 has four distinct city values, including likely spelling variations.
-- A ZIP code prefix does not always uniquely identify a city.
-- This must be considered when joining geolocation data in Gold.
------------------------------------------------------------------------------------------------------------------------
-- silver.category_translation 

SELECT  
	COUNT(DISTINCT product_category_name),
	COUNT(DISTINCT product_category_name_english) 
FROM silver.category_translation;

SELECT
	COUNT(CASE WHEN product_category_name IS NULL THEN 1 END) AS product_category_name_null_amount,
	COUNT(CASE WHEN product_category_name_english IS NULL THEN 1 END) AS product_category_name_english_null_amount
FROM silver.category_translation;

SELECT 
	product_category_name,	
	COUNT(*) AS translation_count
FROM silver.category_translation
GROUP BY product_category_name
ORDER BY translation_count DESC;

SELECT
	p.product_category_name,
	COUNT(*) AS category_missing_translation_count
FROM silver.products p 
LEFT JOIN silver.category_translation ct 
	ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL AND ct.product_category_name IS NULL
GROUP BY p.product_category_name;

-- Two product categories have no matching English translation (portateis_cozinha_e_preparadores_de_alimentos, pc_gamer)
-- Keep original category names as fallback in Gold layer.

------------------------------------------------------------------------------------------------------------------------
-- EDA SUMMARY

-- Some products have missing category information.
-- Two product categories have no matching English translation.
-- Review response times contain extreme values.
-- Some location values are missing or inconsistent.
-- ZIP code prefixes are not always uniquely associated with a city.
-- 2017 is the only complete calendar year in the dataset

-- Implications for Gold layer:
-- Preserve products with missing categories or translations.
-- Avoid row multiplication when joining geolocation data.
-- Consider table granularity when joining orders, items and payments.
