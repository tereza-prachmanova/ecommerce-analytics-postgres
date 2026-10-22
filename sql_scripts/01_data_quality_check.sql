-- Data quality check --
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-- table: olist_customers_dataset

-- 1)
-- count of rows:
SELECT COUNT(*) 
FROM bronze.olist_customers_dataset;

-- column names, data types and null setting:
SELECT 
	column_name,
	data_type,
	is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'bronze' AND table_name = 'olist_customers_dataset';

-- granularity:
SELECT 
	customer_unique_id, 
	COUNT(customer_id) AS customer_id_count
FROM bronze.olist_customers_dataset 
GROUP BY customer_unique_id
ORDER BY COUNT(customer_id) DESC;

-- Each row represents a customer record (customer_id) associated with one order,
-- including the customer's location.
-- customer_id is unique for each order/customer record.
-- customer_unique_id identifies the same customer across multiple orders and can therefore occur multiple times.

-- 2) primary key:
SELECT 
    COUNT(*) AS row_count, 
    COUNT(DISTINCT customer_id) AS distinct_customer_id, 
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS null_amount_customer_id
FROM bronze.olist_customers_dataset;

-- Primary key is not set for this table.
-- customer_id has no NULL values and COUNT(DISTINCT customer_id) equals the total row count.
-- Therefore, customer_id is suitable as a primary key.

-- 3) NULL and empty values:
SELECT 		
	COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS customer_id_null_amount,	
	COUNT(CASE WHEN customer_unique_id IS NULL THEN 1 END) AS customer_unique_id_null_amount,
	COUNT(CASE WHEN customer_city IS NULL THEN 1 END) AS customer_city_null_amount,
	COUNT(CASE WHEN customer_state IS NULL THEN 1 END) AS customer_state_null_amount,
	COUNT(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 END) AS customer_zip_null_amount
FROM bronze.olist_customers_dataset;

SELECT 		
	COUNT(CASE WHEN TRIM(customer_id) = '' THEN 1 END) AS empty_customer_id,
	COUNT(CASE WHEN TRIM(customer_unique_id) = '' THEN 1 END) AS empty_unique_id,
	COUNT(CASE WHEN TRIM(customer_city) = '' THEN 1 END) AS empty_city,
	COUNT(CASE WHEN TRIM(customer_state) = '' THEN 1 END) AS empty_state
FROM bronze.olist_customers_dataset;
-- No NULL or empty values in columns.

-- 4) duplicates:
-- There are no duplicates - COUNT(DISTINCT customer_id) = COUNT(*).

-- 5) value validity and category consistency:
SELECT
    customer_state,
    COUNT(*) AS occurrence_count
FROM bronze.olist_customers_dataset
GROUP BY customer_state
ORDER BY customer_state;

SELECT 
    customer_zip_code_prefix,
    STRING_AGG(DISTINCT customer_city, ', ') AS same_zip_code_cities,
    COUNT(DISTINCT customer_city) AS customer_city_amount
FROM bronze.olist_customers_dataset
GROUP BY customer_zip_code_prefix
HAVING COUNT(DISTINCT customer_city) > 1;
-- Values in customer_state column are consistent.
-- Due to high granularity of customer_city column it is complicated to check category consistency - verification done 
-- with customer_zip_code_prefix column.
-- Some ZIP code prefixes are associated with multiple city names.
-- The result shows naming inconsistencies - requires further validation before standardization in the Silver layer.

-- olist_customers_dataset summary:
---- customer_id is unique, complete and suitable as a primary key.
---- No NULL or empty values were found.
---- No duplicate customer_id values were found.
---- customer_unique_id can occur multiple times due to the table granularity.
---- customer_state values are consistent.
---- Some ZIP code prefixes are associated with multiple city names - requires further validation before any 
---- standardization.

------------------------------------------------------------------------------------------------------------------------
-- -- table: olist_orders_dataset
-- 1)
-- count of rows:
SELECT COUNT(*)
FROM bronze.olist_orders_dataset;

-- column names, data types and null setting:
SELECT
	column_name, 
	data_type,
	is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema ='bronze' AND table_name = 'olist_orders_dataset';

-- granularity:
SELECT 
	COUNT(*) AS row_count,
	COUNT(order_id) AS order_id_count
FROM bronze.olist_orders_dataset;

-- Column order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date and 
-- order_estimated_delivery_date have data type VARCHAR and contain information about date and time - requires change 
-- data type to TIMESTAMP.
-- Each row represents one order - order_id identifies an order. customer_id identifies the customer record associated 
-- with the order.


-- 2) primary key:
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT order_id) AS order_id_distinct,
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_null_amount
FROM bronze.olist_orders_dataset;

-- Primary key is not set for this table.
-- order_id is suitable as a primary key - it has no NULL values and COUNT(DISTINCT order_id) = COUNT(*).

-- 3) NULL and empty values:
SELECT
	COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS customer_id_null_amount,
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_null_amount,
	COUNT(CASE WHEN order_status IS NULL THEN 1 END) AS order_status_null_amount,
	COUNT(CASE WHEN order_purchase_timestamp IS NULL THEN 1 END) AS order_purchase_null_amount,
	COUNT(CASE WHEN order_approved_at IS NULL THEN 1 END) AS order_approved_null_amount,
	COUNT(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 END) AS order_delivered_carrier_null_amount,
	COUNT(CASE WHEN order_delivered_customer_date IS NULL THEN 1 END) AS order_delivered_customer_null_amount,
	COUNT(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 END) AS order_estimated_delivery_null_amount
FROM bronze.olist_orders_dataset;

SELECT
	COUNT(CASE WHEN TRIM(customer_id) = '' THEN 1 END) AS empty_customer_id,
	COUNT(CASE WHEN TRIM(order_id) = '' THEN 1 END) AS empty_order_id,
	COUNT(CASE WHEN TRIM(order_status) = '' THEN 1 END) AS empty_order_status,
	COUNT(CASE WHEN TRIM(order_purchase_timestamp) = '' THEN 1 END) AS empty_order_purchase,
	COUNT(CASE WHEN TRIM(order_approved_at) = '' THEN 1 END) AS empty_order_approved_at,
	COUNT(CASE WHEN TRIM(order_delivered_carrier_date) = '' THEN 1 END) AS empty_order_delivered_carrier_date,
	COUNT(CASE WHEN TRIM(order_delivered_customer_date) = '' THEN 1 END) AS empty_order_delivered_customer_date,
	COUNT(CASE WHEN TRIM(order_estimated_delivery_date) = '' THEN 1 END) AS empty_order_estimated_delivery
FROM bronze.olist_orders_dataset;

-- Check whether missing timestamps are associated with particular order statuses.
SELECT
    order_status,
    COUNT(CASE WHEN TRIM(order_purchase_timestamp) = ''
               THEN 1 END) AS empty_order_purchase,
    COUNT(CASE WHEN TRIM(order_approved_at) = ''
               THEN 1 END) AS empty_order_approved_at,
    COUNT(CASE WHEN TRIM(order_delivered_carrier_date) = ''
               THEN 1 END) AS empty_order_delivered_carrier_date,
    COUNT(CASE WHEN TRIM(order_delivered_customer_date) = ''
               THEN 1 END) AS empty_order_delivered_customer_date,
    COUNT(CASE WHEN TRIM(order_estimated_delivery_date) = ''
               THEN 1 END) AS empty_order_estimated_delivery
FROM bronze.olist_orders_dataset
GROUP BY order_status
ORDER BY order_status;
	
-- No NULL values in columns. 
-- In columns order_approved_at, order_delivered_carrier_date and order_delivered_customer_date are empty values.
-- Missing timestamp values are stored as empty - they should be converted to NULL in Silver layer.
-- Missing timestamp values are associated with particular order statuses.
-- Some missing timestamps are therefore expected based on the order status and do not necessarily indicate a data 
-- quality issue.

-- 4) duplicates:
SELECT 
	COUNT(*) AS row_count,	
	COUNT(order_id) AS order_id_count,
	COUNT(DISTINCT order_id) AS distinct_order_id_count
FROM bronze.olist_orders_dataset;

-- There are no duplicates in order_id column - COUNT(DISTINCT order_id) = COUNT(*).

-- 5) value validity and category consistency:
SELECT 
	order_status,
	COUNT(*) AS occurrence_count
FROM bronze.olist_orders_dataset
GROUP BY order_status
ORDER BY order_status;

-- Values in order_status columns are consistent. 

--6) chronological consistency
-- check if order events follow the expected chronological order: purchase -> approval -> carrier -> customer delivery.
SELECT
	COUNT(CASE WHEN CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) < CAST(NULLIF(order_purchase_timestamp,'') AS TIMESTAMP) THEN 1 END) AS approved_before_purchase,
	COUNT(CASE WHEN CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) < CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) THEN 1 END) AS carrier_before_approved,
	COUNT(CASE WHEN CAST(NULLIF(order_delivered_customer_date,'') AS TIMESTAMP) < CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) THEN 1 END) AS customer_before_carrier
FROM bronze.olist_orders_dataset;
-- Chronological inconsistencies were identified in the delivery process and require further examination.

-- Check if chronological inconsistencies are associated with particular order statuses.
SELECT
	order_status,	
	COUNT(CASE WHEN CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) < CAST(NULLIF(order_purchase_timestamp,'') AS TIMESTAMP) THEN 1 END) AS approved_before_purchase,
	COUNT(CASE WHEN CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) < CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) THEN 1 END) AS carrier_before_approved,
	COUNT(CASE WHEN CAST(NULLIF(order_delivered_customer_date,'') AS TIMESTAMP) < CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) THEN 1 END) AS customer_before_carrier
FROM bronze.olist_orders_dataset
GROUP BY order_status;

-- Examine the range of time differences for orders handed to the carrier before approval.
SELECT
	MIN(CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) - CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP)) AS min_time_difference_carrier_before_approved,
	MAX(CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) - CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP)) AS max_time_difference_carrier_before_approved
FROM bronze.olist_orders_dataset
WHERE CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) < CAST(NULLIF(order_approved_at,'') AS TIMESTAMP); 
-- Time differences range from 21 seconds to 171 days 05:15:22.
-- Because of the wide range, the distribution is examined below.

WITH CTE_time_difference_category AS
(
SELECT
	order_id,
	CASE 
		WHEN (CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) - CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP)) < INTERVAL '1 hour' THEN 'up to 1 hour'
		WHEN (CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) - CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP)) <= INTERVAL '24 hours' THEN '1-24 hours'
		WHEN (CAST(NULLIF(order_approved_at,'') AS TIMESTAMP) - CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP)) <= INTERVAL '7 days' THEN '1-7 days'
		ELSE 'more than 7 days'
	END AS time_difference_category
FROM bronze.olist_orders_dataset
WHERE CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) < CAST(NULLIF(order_approved_at,'') AS TIMESTAMP)
)

SELECT 
	time_difference_category,
	COUNT(*) AS number_of_orders
FROM CTE_time_difference_category
GROUP BY time_difference_category;

-- 901 of 1,359 cases occur within 24 hours.
-- 458 cases exceed one day, including 14 cases exceeding seven days.

-- Examine the range of time differences for orders recorded as delivered to the customer before being handed to the 
-- carrier.
SELECT
	MIN(CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) - CAST(NULLIF(order_delivered_customer_date,'') AS TIMESTAMP)) AS min_time_difference_customer_before_carrier,
	MAX(CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP) - CAST(NULLIF(order_delivered_customer_date,'') AS TIMESTAMP)) AS max_time_difference_customer_before_carrier
FROM bronze.olist_orders_dataset
WHERE CAST(NULLIF(order_delivered_customer_date,'') AS TIMESTAMP) < CAST(NULLIF(order_delivered_carrier_date,'') AS TIMESTAMP);
-- Time differences range from 23 minutes 18 seconds to 16 days 02:18:29.

-- Inspect the 23 customer_before_carrier cases individually, ordered from the largest time difference.
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,

    CAST(NULLIF(order_delivered_carrier_date, '') AS TIMESTAMP)
    - CAST(NULLIF(order_delivered_customer_date, '') AS TIMESTAMP)
        AS time_difference_customer_before_carrier

FROM bronze.olist_orders_dataset

WHERE CAST(NULLIF(order_delivered_customer_date, '') AS TIMESTAMP)
      < CAST(NULLIF(order_delivered_carrier_date, '') AS TIMESTAMP)

ORDER BY time_difference_customer_before_carrier DESC;

-- The dataset contains chronological inconsistencies in delivery timestamps.
-- The source data does not provide enough information to determine which
-- timestamp is incorrect or what the correct value should be.
-- Therefore, these timestamps will be retained without correction.
-- In Silver, empty timestamp strings will be converted to NULL and
-- timestamp columns will be converted to the appropriate data type.

-- olist_orders_dataset summary:
---- Each row represents one order - order_id identifies an order. customer_id identifies the customer record associated
---- with the order.
---- Column order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date and 
---- order_estimated_delivery_date have data type VARCHAR and contain information about date and time - requires change 
---- data type to TIMESTAMP. 
---- order_id is unique, complete and suitable as a primary key.
---- There are no NULL values in columns. 
---- There are no duplicates in order_id column.
---- Values in the column order_status are consistent. 
---- Missing timestamp values are stored as empty strings and should be converted to NULL in the Silver layer. Some 
---- missing timestamps are expected based on order_status and do not necessarily indicate a data quality issue.
---- Chronological inconsistencies were identified in delivery timestamps.
---- Since the correct values cannot be reliably inferred from the available data, the timestamps will be retained 
---- without correction.

------------------------------------------------------------------------------------------------------------------------
-- table: olist_order_items_dataset
-- 1)
-- count of rows:
SELECT 
	COUNT(*)
FROM bronze.olist_order_items_dataset;

-- column names, data types and null setting:
SELECT 
	column_name,
	data_type,
	is_nullable
FROM information_schema."columns" 
WHERE table_schema ='bronze' AND table_name ='olist_order_items_dataset';

-- granularity:
SELECT
	COUNT(*) AS row_count,	
	COUNT(order_item_id) AS order_item_id_count
FROM bronze.olist_order_items_dataset;

-- Column shipping_limit_date contain information about date and time - requires change datatype to TIMESTAMP.
-- Each row represents one item within an order.
-- order_item_id represents the item number within an order.
-- product_id identifies the product associated with the order item.

-- 2) primary key:
SELECT
	COUNT(*) AS row_count,
	COUNT(DISTINCT order_item_id) AS order_item_id_count,
	COUNT(DISTINCT order_id) AS order_id_count,
	COUNT(CASE WHEN order_item_id IS NULL THEN 1 END) AS order_item_id_null_amount,
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_null_amount
FROM bronze.olist_order_items_dataset;

SELECT
	order_item_id,
	order_id
FROM bronze.olist_order_items_dataset
GROUP BY order_item_id, order_id
HAVING COUNT(*) > 1;

-- Primary key is not set for this table.
-- The combination of order_id and order_item_id is unique and both columns contain no NULL values - they are suitable 
-- as a composite primary key.

-- 3) NULL and empty values:
SELECT
	COUNT(CASE WHEN order_id IS NULL THEN 1 end) AS order_id_null_amount,
	COUNT(CASE WHEN order_item_id IS NULL THEN 1 end) AS order_item_id_null_amount,
	COUNT(CASE WHEN product_id IS NULL THEN 1 end) AS product_id_null_amount,
	COUNT(CASE WHEN seller_id IS NULL THEN 1 end) AS seller_id_null_amount,
	COUNT(CASE WHEN shipping_limit_date IS NULL THEN 1 end) AS shipping_limit_date_null_amount,
	COUNT(CASE WHEN price IS NULL THEN 1 end) AS price_null_amount,
	COUNT(CASE WHEN freight_value IS NULL THEN 1 end) AS freight_value_null_amount
FROM bronze.olist_order_items_dataset;

SELECT
	COUNT(CASE WHEN TRIM(order_id) = '' THEN 1 END) AS empty_order_id,
	COUNT(CASE WHEN TRIM(product_id) = '' THEN 1 END) AS empty_product_id,
	COUNT(CASE WHEN TRIM(seller_id) = '' THEN 1 END) AS empty_seller_id,
	COUNT(CASE WHEN TRIM(shipping_limit_date) = '' THEN 1 END) AS empty_shipping_limit_date
FROM bronze.olist_order_items_dataset;

-- No NULL or empty values in columns.

-- 4) duplicates

-- Individual columns contain repeated values, which is expected given the granularity of the table.
-- The combination of order_id and order_item_id uniquely identifies each row and creates no duplicates.

-- 5) value validity 
SELECT
	MIN(price) AS min_price,
	MAX(price) AS max_price,
	MIN(freight_value) AS min_freight_value,
	MAX(freight_value) AS max_freight_value
FROM bronze.olist_order_items_dataset;

-- No negative values were found.
-- High values may be further examined in EDA.

-- olist_order_items_dataset summary:
---- Column shipping_limit_date contains date and time information and should be converted to TIMESTAMP.
---- Each row represents one item within an order.
---- The combination of order_id and order_item_id identifies a specific order item.
---- order_item_id represents the item number within an order.
---- product_id identifies the product associated with the order item.
---- Primary key is not set for this table.
---- The combination of order_id and order_item_id is unique and both columns contain no NULL values.
---- They are suitable as a composite primary key.
---- No NULL or empty values were found.
---- Repeated values in individual columns are expected given the granularity of the table.
---- No duplicates exist at the expected table grain.
---- No negative values were found.
---- High values may be further examined during EDA.

------------------------------------------------------------------------------------------------------------------------
-- table: olist_order_payments_dataset
-- 1)
-- count of rows:
SELECT
	COUNT(*) AS row_count
FROM bronze.olist_order_payments_dataset;

-- column names, data type and null setting:
SELECT
	column_name,
	data_type,
	is_nullable
FROM information_schema.columns 
WHERE table_schema = 'bronze' AND table_name = 'olist_order_payments_dataset';
-- granularity:
SELECT 
	COUNT(*) AS row_count,
	COUNT(order_id) AS order_id_count
FROM bronze.olist_order_payments_dataset;
-- Each row represents one payment within an order. Some orders are paid using multiple payments.
-- order_id identifies the order.
-- payment_sequential represents the sequence of payments within an order.

-- 2) primary key:
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT order_id) AS order_id_distinct,
	COUNT(DISTINCT payment_sequential) AS payment_sequential_distinct,
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_null_amount,
	COUNT(CASE WHEN payment_sequential IS NULL THEN 1 END) AS payment_sequential_null_amount
FROM bronze.olist_order_payments_dataset;
	
SELECT
	order_id,
	payment_sequential
FROM bronze.olist_order_payments_dataset
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;
-- Primary key is not set for this table.
-- The combination of order_id and payment_sequential is unique and both columns contain no NULL values - they are 
-- suitable as a composite primary key.

-- 3) NULL and empty values:
SELECT 
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_null_amount,
	COUNT(CASE WHEN payment_sequential IS NULL THEN 1 END) AS payment_sequential_null_amount,
	COUNT(CASE WHEN payment_type IS NULL THEN 1 END) AS payment_type_null_amount,
	COUNT(CASE WHEN payment_installments IS NULL THEN 1 END) AS payment_installments_null_amount,
	COUNT(CASE WHEN payment_value IS NULL THEN 1 END) AS payment_value_null_amount
FROM bronze.olist_order_payments_dataset;

SELECT
	COUNT(CASE WHEN TRIM(order_id) = '' THEN 1 END) AS empty_order_id,
	COUNT(CASE WHEN TRIM(payment_type) = '' THEN 1 END) AS empty_payment_type
FROM bronze.olist_order_payments_dataset;

-- No NULL or empty values in columns.

-- 4) duplicates:

-- Individual columns contain repeated values, which is expected given the granularity of the table.
-- The combination of order_id and payment_sequential uniquely identifies each row and creates no duplicates.

-- 5) value validity and category consistency:
SELECT 
	payment_type,	
	COUNT(order_id) AS order_id_count
FROM bronze.olist_order_payments_dataset
GROUP BY payment_type;

SELECT 
	MIN(payment_sequential) AS min_payment_sequential,
	MAX(payment_sequential) AS max_payment_sequential,
	MIN(payment_installments) AS min_payment_installments,
	MAX(payment_installments) AS max_payment_installments,
	MIN(payment_value) AS min_payment_value,
	MAX(payment_value) AS max_payment_value
FROM bronze.olist_order_payments_dataset;	

SELECT 
	payment_installments,
	payment_type,
	COUNT(order_id) AS order_id_count
FROM bronze.olist_order_payments_dataset
GROUP BY payment_installments, payment_type
HAVING payment_installments = 0;

SELECT 
	payment_value,
	payment_type,
	COUNT(order_id) AS order_id_count
FROM bronze.olist_order_payments_dataset
GROUP BY payment_value, payment_type
HAVING payment_value = 0;

-- Values in the payment_type column are consistent.
-- No negative values were found.
-- Zero payment_installments were found in 2 credit card payment records.
-- Zero payment_value was found in 9 payment records: 6 vouchers and 3 not_defined.
-- These values were flagged as potentially unusual but retained because
-- their correct values cannot be reliably inferred.
-- High values may be further examined during EDA.

-- olist_order_payments_dataset summary:
---- Each row represents one payment within an order. Some orders are paid using multiple payments.
---- order_id identifies the order, payment_sequential represents the sequence of payments within an order.
---- Primary key is not set for this table.
---- The combination of order_id and payment_sequential is unique and both columns contain no NULL values - they are 
---- suitable as a composite primary key.
---- No NULL or empty values in columns.
---- Individual columns contain repeated values, which is expected given the granularity of the table. The combination 
---- of order_id and payment_sequential uniquely identifies each row and creates no duplicates.
---- Values in payment_type column are consistent.
---- No negative values were found. 
---- Zero payment_installments were found in 2 credit card payment records.
---- Zero payment_value was found in 9 payment records: 6 vouchers and 3 not_defined.
---- These values were flagged as potentially unusual but retained because
---- their correct values cannot be reliably inferred.
---- High values may be further examined during EDA.

------------------------------------------------------------------------------------------------------------------------
-- table: olist_order_reviews_dataset
-- 1)
-- count of rows:
SELECT
	COUNT(*) AS row_count
FROM bronze.olist_order_reviews_dataset;

-- column names, data types, null setting:
SELECT 
	column_name,
	data_type,
	is_nullable
FROM information_schema.columns
WHERE table_schema = 'bronze' AND table_name = 'olist_order_reviews_dataset';

-- granularity:
SELECT
	COUNT(*) AS row_count,
	COUNT(review_id) AS review_id_count
FROM bronze.olist_order_reviews_dataset;

-- Column review_creation_date have data type VARCHAR and contain information about date - requires change data type to
-- DATE.
-- Column review_answer_timestamp have data type VARCHAR and contain information about date and time - requires change
-- data type to TIMESTAMP.
-- Each row represents one review associated with the order.

-- 2) primary key:
SELECT
	COUNT(*) AS row_count,
	COUNT(DISTINCT review_id) AS distinct_review_id,
	COUNT(DISTINCT order_id) AS distinct_order_id,
	COUNT(CASE WHEN review_id IS NULL THEN 1 END) AS review_id_null_amount,
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_null_amount
FROM bronze.olist_order_reviews_dataset;

SELECT
    review_id,
    order_id
FROM bronze.olist_order_reviews_dataset
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

SELECT *
FROM bronze.olist_order_reviews_dataset
WHERE review_id IN (
    SELECT review_id
    FROM bronze.olist_order_reviews_dataset
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id;

-- Primary key is not set for this table.
-- Neither review_id nor order_id is unique.
-- The combination of review_id and order_id is unique and both columns contain no NULL values.
-- Therefore, review_id and order_id can be used as a composite key for the current dataset.
-- Some review_id values are assigned to different order_id values while the remaining review
-- attributes are identical, indicating a data quality inconsistency.

-- 3) Null and empty values:
SELECT 
	COUNT(CASE WHEN review_id IS NULL THEN 1 END) AS review_id_null_amount,	
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_null_amount,
	COUNT(CASE WHEN review_score IS NULL THEN 1 END) AS review_score_null_amount,
	COUNT(CASE WHEN review_comment_title IS NULL THEN 1 END) AS review_comment_title_null_amount,
	COUNT(CASE WHEN review_comment_message IS NULL THEN 1 END) AS review_comment_message_null_amount,
	COUNT(CASE WHEN review_creation_date IS NULL THEN 1 END) AS review_creation_date_null_amount,
	COUNT(CASE WHEN review_answer_timestamp IS NULL THEN 1 END) AS review_answer_timestamp_null_amount
FROM bronze.olist_order_reviews_dataset;

SELECT 
	COUNT(CASE WHEN TRIM(review_id) = '' THEN 1 END) AS empty_review_id,
	COUNT(CASE WHEN TRIM(order_id) = '' THEN 1 END) AS empty_order_id,
	COUNT(CASE WHEN TRIM(review_comment_title) = '' THEN 1 END) AS empty_review_comment_title,
	COUNT(CASE WHEN TRIM(review_comment_message) = '' THEN 1 END) AS empty_review_comment_message,
	COUNT(CASE WHEN TRIM(review_creation_date) = '' THEN 1 END) AS empty_review_creation_date,
	COUNT(CASE WHEN TRIM(review_answer_timestamp) = '' THEN 1 END) AS empty_review_answer_timestamp
FROM bronze.olist_order_reviews_dataset;
	
-- There are no NULL values.
-- There are empty values only in review_comment_title and review_comment_message. In this situation it is not a
-- problem. It is important that review_score column has no NULL values.

-- 4) duplicates:

-- Individual columns contain repeated values, which is expected given the granularity of the table.
-- The combination of review_id and order_id uniquely identifies each row and creates no duplicates.

-- 5) value validity:
SELECT 
	MIN(review_score) AS min_review_score,
	MAX(review_score) AS max_review_score
FROM bronze.olist_order_reviews_dataset;	

-- The range of review_score values is valid.

-- 6) chronological consistency
SELECT 
	COUNT(review_score)	AS review_count,
	COUNT(CASE WHEN CAST(review_creation_date AS TIMESTAMP) > CAST(review_answer_timestamp AS TIMESTAMP) THEN 1 END) AS answer_before_review
FROM bronze.olist_order_reviews_dataset;

-- No cases were found where review_answer_timestamp precedes review_creation_date.

-- olist_order_reviews_dataset summary:
---- Column review_creation_date have data type VARCHAR and contain information about date - requires change data type to
---- DATE.
---- Column review_answer_timestamp have data type VARCHAR and contain information about date and time - requires change
---- data type to TIMESTAMP.
---- Each row represents one review associated with the order.
---- Primary key is not set for this table.
---- Neither review_id nor order_id is unique.
---- The combination of review_id and order_id is unique and both columns contain no NULL values.
---- Therefore, review_id and order_id can be used as a composite key for the current dataset.
---- Some review_id values are assigned to different order_id values while the remaining review
---- attributes are identical, indicating a data quality inconsistency.
---- There are no NULL values.
---- There are empty values only in review_comment_title and review_comment_message. In this situation it is not a
---- problem. It is important that review_score column has no NULL values.
---- Individual columns contain repeated values, which is expected given the granularity of the table.
---- The combination of review_id and order_id uniquely identifies each row and creates no duplicates.
---- The range of review_score values is valid.
---- No cases were found where review_answer_timestamp precedes review_creation_date.

------------------------------------------------------------------------------------------------------------------------
-- table: olist_products_dataset
-- 1)
-- count of rows:
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_products_dataset;

-- column names, data types, null setting:
SELECT
	column_name,
	data_type,
	is_nullable
FROM information_schema.columns
WHERE table_schema = 'bronze' AND table_name = 'olist_products_dataset';

-- granularity:
SELECT
	COUNT(*) AS row_count,
	COUNT(product_id) AS product_id_count
FROM bronze.olist_products_dataset;

-- Each row represents one product.

-- 2) primary key:
SELECT
	COUNT(*) AS row_count,
	COUNT(DISTINCT product_id) AS product_id_count,
	COUNT(CASE WHEN product_id IS NULL THEN 1 END) AS product_id_null_amount
FROM bronze.olist_products_dataset;

-- Primary key is not set for this table.
-- product_id has no NULL values and COUNT(DISTINCT product_id) = COUNT(*) - therefore, product_id is suitable as a 
-- primary key.

-- 3) NULL and empty values:
SELECT 
	COUNT(CASE WHEN product_id IS NULL THEN 1 END) AS product_id_null_amount,
	COUNT(CASE WHEN product_category_name IS NULL THEN 1 END) AS product_category_name_null_amount,
	COUNT(CASE WHEN product_name_lenght IS NULL THEN 1 END) AS product_name_lenght_null_amount,
	COUNT(CASE WHEN product_description_lenght IS NULL THEN 1 END) AS product_description_lenght_null_amount,
	COUNT(CASE WHEN product_photos_qty IS NULL THEN 1 END) AS product_photos_qty_null_amount,
	COUNT(CASE WHEN product_weight_g  IS NULL THEN 1 END) AS product_weight_g_null_amount,
	COUNT(CASE WHEN product_length_cm  IS NULL THEN 1 END) AS product_length_cm_null_amount,
	COUNT(CASE WHEN product_height_cm  IS NULL THEN 1 END) AS product_height_cm_null_amount,
	COUNT(CASE WHEN product_width_cm  IS NULL THEN 1 END) AS product_width_cm_null_amount
FROM bronze.olist_products_dataset;

SELECT *
FROM bronze.olist_products_dataset
WHERE product_width_cm IS NULL;

SELECT *
FROM bronze.olist_products_dataset
WHERE product_name_lenght IS NULL;

SELECT 
	COUNT(CASE WHEN TRIM(product_id) = '' THEN 1 END) AS empty_product_id,
	COUNT(CASE WHEN TRIM(product_category_name) = '' THEN 1 END) AS empty_product_category_name
FROM bronze.olist_products_dataset;

-- 610 products have an empty product_category_name.
-- These products also have missing product name length,
-- description length and photo quantity information.
-- 2 products have missing weight and dimension information.

-- 4) duplicates:
-- There are no duplicates - COUNT(DISTINCT product_id) = COUNT(*).

-- 5) value validity and category consistency:
SELECT
	product_category_name,
	COUNT(product_id)
FROM bronze.olist_products_dataset
GROUP BY product_category_name
ORDER BY product_category_name;

SELECT 
	MIN(product_name_lenght) AS min_product_name_lenght,
	MAX(product_name_lenght) AS max_product_name_lenght,
	MIN(product_description_lenght) AS min_product_description_lenght,
	MAX(product_description_lenght) AS max_product_description_lenght,
	MIN(product_photos_qty) AS min_product_photos_qty,
	MAX(product_photos_qty) AS max_product_photos_qty,
	MIN(product_weight_g) AS min_product_weight_g,
	MAX(product_weight_g) AS max_product_weight_g,
	MIN(product_length_cm) AS min_product_length_cm,
	MAX(product_length_cm) AS max_product_length_cm,
	MIN(product_height_cm) AS min_product_height_cm,
	MAX(product_height_cm) AS max_product_height_cm,
	MIN(product_width_cm) AS min_product_width_cm,
	MAX(product_width_cm) AS max_product_width_cm
FROM bronze.olist_products_dataset;

SELECT *
FROM bronze.olist_products_dataset
WHERE product_weight_g = 0;

-- 610 products do not have product_category_name (as mentioned above).
-- Some category names are similar (e.g. casa_conforto / casa_conforto_2).
-- They are retained as separate source categories.
-- 4 products have product_weight_g = 0 while their dimensions are filled.
-- Zero is considered an invalid product weight.
-- The correct weight cannot be inferred from the available data. In Silver layer product_weight_g = 0 should be
-- converted to NULL.
-- MAX product_weight_g may represent an outlier and can be further examined during EDA.

-- olist_products_dataset summary:
---- Each row represents one product.
---- Primary key is not set for this table.
---- product_id has no NULL values and COUNT(DISTINCT product_id) = COUNT(*) - therefore, product_id is suitable as a 
---- primary key.
---- 610 products have an empty product_category_name.
---- These products also have missing product name length,
---- description length and photo quantity information.
---- 2 products have missing weight and dimension information.
---- There are no duplicates - COUNT(DISTINCT product_id) = COUNT(*).
---- 4 products have product_weight_g = 0 while their dimensions are filled.
---- Zero is considered an invalid product weight.
---- The correct weight cannot be inferred from the available data. In Silver layer product_weight_g = 0 should be
---- converted to NULL.
---- MAX product_weight_g may represent an outlier and can be further examined during EDA.

------------------------------------------------------------------------------------------------------------------------
-- table: olist_sellers_dataset

-- 1)
-- count of rows:
SELECT
	COUNT(*) AS row_count
FROM bronze.olist_sellers_dataset;

-- column names, data types, null setting:
SELECT
	column_name,
	data_type,
	is_nullable
FROM information_schema.columns 
WHERE table_schema = 'bronze' AND table_name = 'olist_sellers_dataset';

-- granularity:
SELECT 
	COUNT(*) AS row_count,
	COUNT(seller_id) AS seller_id_count
FROM bronze.olist_sellers_dataset;

-- Each row represents one seller.

-- 2) primary key:
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT seller_id) AS distinct_seller_id,
	COUNT(CASE WHEN seller_id IS NULL THEN 1 END) AS seller_id_null_amount
FROM bronze.olist_sellers_dataset;

-- Primary key is not set for this table.
-- seller_id has no NULL values and COUNT(DISTINCT seller_id) = COUNT(*) - therefore, seller_id is suitable as a primary
-- key.

-- 3) NULL and empty values:
SELECT 
	COUNT(CASE WHEN seller_id IS NULL THEN 1 END) AS seller_id_null_amount,
	COUNT(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 END) AS seller_zip_code_prefix_null_amount,
	COUNT(CASE WHEN seller_city IS NULL THEN 1 END) AS seller_city_null_amount,
	COUNT(CASE WHEN seller_state IS NULL THEN 1 END) AS seller_state_null_amount
FROM bronze.olist_sellers_dataset;

SELECT 
	COUNT(CASE WHEN TRIM(seller_id) = '' THEN 1 END) AS empty_seller_id,
	COUNT(CASE WHEN TRIM(seller_zip_code_prefix) = '' THEN 1 END) AS empty_seller_zip_code_prefix,
	COUNT(CASE WHEN TRIM(seller_city) = '' THEN 1 END) AS empty_seller_city,
	COUNT(CASE WHEN TRIM(seller_state) = '' THEN 1 END) AS empty_seller_state
FROM bronze.olist_sellers_dataset;

-- There are no empty or NULL values.

-- 4) duplicates:
-- There are no duplicates - COUNT(DISTINCT seller_id) = COUNT(*).

-- 5) value validity and category consistency:
SELECT
	seller_city,
	COUNT(seller_id) AS seller_id_count
FROM bronze.olist_sellers_dataset
GROUP BY seller_city
ORDER BY seller_city;

SELECT
	seller_state,
	COUNT(seller_id) AS seller_id_count
FROM bronze.olist_sellers_dataset
GROUP BY seller_state
ORDER BY seller_state;

SELECT
	seller_zip_code_prefix,
	STRING_AGG(DISTINCT seller_city, ', ') AS same_zip_code_cities,
	COUNT(DISTINCT seller_city) AS seller_city_count
FROM bronze.olist_sellers_dataset
GROUP BY seller_zip_code_prefix
HAVING COUNT(DISTINCT seller_city) > 1;

-- Values in seller_state column are consistent.
-- Due to high granularity of seller_city column it is complicated to check category consistency - verification done 
-- with seller_zip_code_prefix column.
-- Some zip code prefixes are associated with multiple city names.
-- The result shows some naming inconsistencies - requires further validation before standardization in the Silver layer.

-- olist_sellers_dataset summary:
---- Each row represents one seller.
---- Primary key is not set for this table.
---- seller_id has no NULL values and COUNT(DISTINCT seller_id) = COUNT(*) - therefore, seller_id is suitable as a 
---- primary key.
---- There are no empty or NULL values.
---- There are no duplicates - COUNT(DISTINCT seller_id) = COUNT(*).
---- Values in seller_state column are consistent.
---- Due to high granularity of seller_city column it is complicated to check category consistency - verification done 
---- with seller_zip_code_prefix column.
---- Some zip code prefixes are associated with multiple city names.
---- The result shows some naming inconsistencies - requires further validation before standardization in the Silver 
---- layer.
------------------------------------------------------------------------------------------------------------------------
-- table: olist_geolocation_dataset

-- 1)
-- count of rows:
SELECT
	COUNT(*) AS row_count
FROM bronze.olist_geolocation_dataset;

-- column names, data types, null setting:
SELECT
	column_name,
	data_type,
	is_nullable
FROM information_schema.columns
WHERE table_schema = 'bronze' AND table_name = 'olist_geolocation_dataset';

-- granularity
SELECT
	COUNT(*) AS row_count,
	COUNT(geolocation_lat) AS geolocation_lat_count,
	COUNT(geolocation_lng) AS geolocation_lng_count
FROM bronze.olist_geolocation_dataset;

-- Each row represents one geolocation record associated with a zip code prefix, geographic coordinates, city and state.

-- 2) primary key
SELECT
    geolocation_lat,
    geolocation_lng,
    COUNT(*) AS location_count
FROM bronze.olist_geolocation_dataset
GROUP BY geolocation_lat, geolocation_lng
HAVING COUNT(*) > 1;

SELECT *
FROM bronze.olist_geolocation_dataset
WHERE (geolocation_lat, geolocation_lng) IN (SELECT
    geolocation_lat,
    geolocation_lng
FROM bronze.olist_geolocation_dataset
GROUP BY geolocation_lat, geolocation_lng
HAVING COUNT(*) > 1)
ORDER BY geolocation_lat, geolocation_lng 

-- Primary key is not set for this table.
-- The combination of geolocation_lat and geolocation_lng is not unique.
-- The table does not contain a suitable natural primary key.

-- 3) empty and NULL values:
SELECT 
	COUNT(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 END) AS geolocation_zip_code_prefix_null_amount,
	COUNT(CASE WHEN geolocation_lat IS NULL THEN 1 END) AS geolocation_lat_null_amount,
	COUNT(CASE WHEN geolocation_lng IS NULL THEN 1 END) AS geolocation_lng_null_amount,
	COUNT(CASE WHEN geolocation_city IS NULL THEN 1 END) AS geolocation_city_null_amount,
	COUNT(CASE WHEN geolocation_state IS NULL THEN 1 END) AS geolocation_state_null_amount
FROM bronze.olist_geolocation_dataset;

SELECT 
	COUNT(CASE WHEN TRIM(geolocation_zip_code_prefix) = '' THEN 1 END) AS empty_geolocation_zip_code_prefix,
	COUNT(CASE WHEN TRIM(geolocation_city) = '' THEN 1 END) AS empty_geolocation_city,
	COUNT(CASE WHEN TRIM(geolocation_state) = '' THEN 1 END) AS empty_geolocation_state
FROM bronze.olist_geolocation_dataset;

-- There are no NULL or empty values.

-- 4) duplicates:
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS duplicate_count
FROM bronze.olist_geolocation_dataset
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;

-- The dataset contains fully duplicated rows.
-- These duplicates should be removed in the Silver layer.

-- 5) value validity and category consistency:
SELECT
	geolocation_state,
	COUNT(*) AS row_count
FROM bronze.olist_geolocation_dataset
GROUP BY geolocation_state
ORDER BY geolocation_state;

SELECT
	geolocation_zip_code_prefix,
	STRING_AGG(DISTINCT geolocation_city, ', ') AS same_zip_code_cities,
	COUNT(DISTINCT geolocation_city) AS geolocation_city_count
FROM bronze.olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_city) > 1;

-- Values in geolocation_state are consistent.
-- Due to high granularity of geolocation_city column it is complicated to check category consistency - verification
-- done with geolocation_zip_code_prefix column.
-- Some ZIP code prefixes are associated with multiple city names.
-- The result shows some naming inconsistencies - requires further validation before any standardization in the Silver layer.

-- olist_geolocation_dataset summary:
---- Each row represents one geolocation record associated with a zip code prefix, geographic coordinates, city and 
---- state.
---- Primary key is not set for this table.
---- The combination of geolocation_lat and geolocation_lng is not unique.
---- The table does not contain a suitable natural primary key.
---- The dataset contains fully duplicated rows.
---- These duplicates should be removed in the Silver layer.
---- There are no NULL or empty values.
---- Values in geolocation_state are consistent.
---- Due to high granularity of geolocation_city column it is complicated to check category consistency - verification
---- done with geolocation_zip_code_prefix column.
---- Some ZIP code prefixes are associated with multiple city names.
---- The result shows some naming inconsistencies - requires further validation before any standardization in the Silver 
---- layer.

------------------------------------------------------------------------------------------------------------------------
-- table: product_category_name_translation

-- 1) 
-- count of rows:
SELECT
	COUNT(*) AS row_count
FROM bronze.product_category_name_translation;

-- column names, data types, null setting:
SELECT
	column_name,
	data_type,
	is_nullable
FROM information_schema.columns
WHERE table_schema = 'bronze' AND table_name = 'product_category_name_translation';

-- granularity:
SELECT
	COUNT(*) AS row_count,
	COUNT(product_category_name) AS product_category_name_count
FROM bronze.product_category_name_translation;

-- Each row represents one Portuguese product category and its English translation.

-- 2) primary key:
SELECT
	COUNT(*) AS row_count,
	COUNT(DISTINCT product_category_name) AS product_category_name_count,
	COUNT(CASE WHEN product_category_name IS NULL THEN 1 END) AS product_category_name_null_amount
FROM bronze.product_category_name_translation;

-- Primary key is not set for this table.
-- Column product_category_name has no NULL values and COUNT(DISTINCT product_category_name) = COUNT(*).
-- Therefore, product_category_name is suitable as a primary key.

-- 3) NULL and empty values:
SELECT
	COUNT(CASE WHEN product_category_name IS NULL THEN 1 END) AS product_category_name_null_amount,
	COUNT(CASE WHEN product_category_name_english IS NULL THEN 1 END) AS product_category_name_english_null_amount
FROM bronze.product_category_name_translation;

SELECT
	COUNT(CASE WHEN TRIM(product_category_name) = '' THEN 1 END) AS empty_product_category_name,
	COUNT(CASE WHEN TRIM(product_category_name_english) = '' THEN 1 END) AS empty_product_category_name_english
FROM bronze.product_category_name_translation;

-- No empty or NULL values in columns.

-- 4) duplicates:
-- There are no duplicates - COUNT(DISTINCT product_category_name) = COUNT(*).

-- 5) value validity and category consistency:
SELECT
	COUNT(*) AS row_count, 	
	COUNT(DISTINCT product_category_name_english) AS product_category_name_english_count
FROM bronze.product_category_name_translation;

-- Each Portuguese product category has one English translation.
-- English category names are also unique.

-- product_category_name_translation summary:
---- Each row represents one Portuguese product category and its English translation.
---- Primary key is not set for this table.
---- Column product_category_name has no NULL values and COUNT(DISTINCT product_category_name) = COUNT(*).
---- Therefore, product_category_name is suitable as a primary key.
---- No empty or NULL values in columns.
---- There are no duplicates - COUNT(DISTINCT product_category_name) = COUNT(*).
---- Each product category has one translation.

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- CROSS-TABLE DATA QUALITY CHECKS --

-- 1) orders → customers
-- Relationship over customer_id
SELECT 
	COUNT(*) AS missing_customer_count
FROM bronze.olist_orders_dataset ood
LEFT JOIN bronze.olist_customers_dataset ocd 
	ON ood.customer_id = ocd.customer_id
WHERE ocd.customer_id IS NULL; 

-- All customer_id values in orders have a corresponding record in customers.

-- 2) order_items → orders                 
-- Relationship over order_id

SELECT
	COUNT(*) AS item_without_order_count
FROM bronze.olist_order_items_dataset ooid 
LEFT JOIN bronze.olist_orders_dataset ood 
	ON ooid.order_id = ood.order_id
WHERE ood.order_id IS NULL;

SELECT
	COUNT(*) AS order_without_item_count,
	ood.order_status
FROM bronze.olist_orders_dataset ood 
LEFT JOIN bronze.olist_order_items_dataset ooid 
	ON ood.order_id = ooid.order_id 
WHERE ooid.order_id IS NULL
GROUP BY ood.order_status;

-- All order_id values in order_items have a corresponding record in orders.
-- 775 orders have no corresponding records in order_items.
-- Most of these orders have the status unavailable (603) or canceled (164).
-- A small number have other statuses (created, invoiced or shipped).

-- 3) order_payments → orders               
-- Relationship over order_id
SELECT 
	COUNT(*) AS missing_payment_count
FROM bronze.olist_order_payments_dataset oopd 
LEFT JOIN bronze.olist_orders_dataset ood 
	ON oopd.order_id = ood.order_id 
WHERE ood.order_id IS NULL;

-- All order_id values in order_payments have a corresponding record in orders.

-- 4) order_reviews → orders                
-- Relationship over order_id

SELECT 
	COUNT(*) AS missing_review_count
FROM bronze.olist_order_reviews_dataset oord 
LEFT JOIN bronze.olist_orders_dataset ood 
	ON oord.order_id = ood.order_id 
WHERE ood.order_id IS NULL;

-- All order_id values in order_reviews have a corresponding record in orders.

-- 5) order_items → products                
-- Relationship over product_id
SELECT 
	COUNT(*) AS missing_product_count
FROM bronze.olist_order_items_dataset ooid 
LEFT JOIN bronze.olist_products_dataset opd 
	ON ooid.product_id = opd.product_id
WHERE opd.product_id IS NULL;

-- All product_id values in order_items have a corresponding record in products.

-- 6) order_items → sellers                 
-- Relationship over seller_id
SELECT 
	COUNT(*) AS missing_seller_count
FROM bronze.olist_order_items_dataset ooid 
LEFT JOIN bronze.olist_sellers_dataset osd 
	ON ooid.seller_id = osd.seller_id
WHERE osd.seller_id IS NULL;

-- All seller_id values in order_items have a corresponding record in sellers.

-- 7) products → category_translation       
-- Relationship over product_category_name
SELECT
	COUNT(*) missing_translation_count
FROM bronze.olist_products_dataset opd 
LEFT JOIN bronze.product_category_name_translation pcnt 
	ON opd.product_category_name = pcnt.product_category_name 
WHERE opd.product_category_name IS NOT NULL AND TRIM(opd.product_category_name) != '' AND pcnt.product_category_name IS NULL;

SELECT
    opd.product_category_name,
    COUNT(*) AS product_count
FROM bronze.olist_products_dataset opd
LEFT JOIN bronze.product_category_name_translation pcnt
    ON opd.product_category_name = pcnt.product_category_name
WHERE pcnt.product_category_name IS NULL
GROUP BY opd.product_category_name
ORDER BY product_count DESC;

-- 610 products have an empty product_category_name.
-- 2 non-empty product categories used by 13 products have no corresponding translation.

-- 8) customers → geolocation               
-- Relationship over zip_code_prefix
SELECT
	COUNT(*) AS customers_without_geolocation,
	COUNT(DISTINCT ocd.customer_zip_code_prefix) AS missing_zip_code_prefix_count
FROM bronze.olist_customers_dataset ocd 
LEFT JOIN bronze.olist_geolocation_dataset ogd 
	ON ocd.customer_zip_code_prefix = ogd.geolocation_zip_code_prefix
WHERE ogd.geolocation_zip_code_prefix IS NULL;

SELECT
	COUNT(*) AS customer_count,
	ocd.customer_zip_code_prefix
FROM bronze.olist_customers_dataset ocd 
LEFT JOIN bronze.olist_geolocation_dataset ogd 
	ON ocd.customer_zip_code_prefix = ogd.geolocation_zip_code_prefix
WHERE ogd.geolocation_zip_code_prefix IS NULL
GROUP BY ocd.customer_zip_code_prefix
ORDER BY ocd.customer_zip_code_prefix DESC;

-- 278 customer records have ZIP code prefixes with no corresponding record in geolocation.
-- These records represent 157 distinct ZIP code prefixes.

-- 9) sellers → geolocation                 
-- Relationship over zip_code_prefix

SELECT
	COUNT(*) AS seller_without_geolocation,
	COUNT(DISTINCT osd.seller_zip_code_prefix) AS missing_zip_code_prefix_count 
FROM bronze.olist_sellers_dataset osd 
LEFT JOIN bronze.olist_geolocation_dataset ogd 
	ON osd.seller_zip_code_prefix = ogd.geolocation_zip_code_prefix
WHERE ogd.geolocation_zip_code_prefix IS NULL;

SELECT
	COUNT(*) AS seller_count,
	osd.seller_zip_code_prefix 
FROM bronze.olist_sellers_dataset osd 
LEFT JOIN bronze.olist_geolocation_dataset ogd 
	ON osd.seller_zip_code_prefix = ogd.geolocation_zip_code_prefix
WHERE ogd.geolocation_zip_code_prefix IS NULL
GROUP BY osd.seller_zip_code_prefix
ORDER BY osd.seller_zip_code_prefix DESC;

-- 7 seller records have ZIP code prefixes with no corresponding record in geolocation.
-- These records represent 7 distinct ZIP code prefixes.


