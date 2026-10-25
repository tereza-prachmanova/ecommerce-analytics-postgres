-- STANDARDIZATION AND CREATION OF VIEWS --
------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_customers_dataset -> silver.customers

-- Bronze conclusion:
-- Some ZIP code prefixes are associated with multiple city names.
-- The result shows naming inconsistencies - requires further validation before standardization in the Silver layer.

-- cities with the same zip code prefix
SELECT
    customer_zip_code_prefix,
    STRING_AGG(DISTINCT customer_city, ', ') AS same_zip_code_cities,
    COUNT(DISTINCT customer_city) AS customer_city_count
FROM bronze.olist_customers_dataset
GROUP BY customer_zip_code_prefix
HAVING COUNT(DISTINCT customer_city) > 1;

-- unification of cities
WITH CTE_customer_city AS 
(SELECT
	customer_city AS original_city,	
	CASE 
		WHEN customer_city = 'embu' THEN 'embu das artes'
		WHEN customer_city = 'santa barbara d oeste' THEN 'santa barbara d''oeste'
		WHEN customer_city = 'mogi-mirim' THEN 'mogi mirim'
		WHEN customer_city = 'estrela d oeste' THEN 'estrela d''oeste'
		WHEN customer_city = 'parati' THEN 'paraty'
		WHEN customer_city = 'brasopolis' THEN 'brazopolis'
		WHEN customer_city = 'piumhii' THEN 'piumhi'
		WHEN customer_city = 'dias d avila' THEN 'dias d''avila'
		WHEN customer_city = 'itapage' THEN 'itapaje'
		WHEN customer_city = 'bataipora' THEN 'bataypora'
		WHEN customer_city = 'sao jorge do oeste' THEN 'sao jorge d''oeste'
		WHEN customer_city = 'picarras' THEN 'balneario picarras'
		WHEN customer_city = 'palmeira d oeste' THEN 'palmeira d''oeste'
		WHEN customer_city = 'arraial d ajuda' THEN 'arraial d''ajuda'
		ELSE customer_city
	END AS customer_city
FROM bronze.olist_customers_dataset);

-- checking the city transformation
SELECT *
FROM CTE_customer_city
WHERE original_city != customer_city;

-- creating silver.customers view
CREATE VIEW silver.customers AS
SELECT 
	customer_id,
	customer_unique_id,
	customer_zip_code_prefix,
	CASE 
		WHEN customer_city = 'embu' THEN 'embu das artes'
		WHEN customer_city = 'santa barbara d oeste' THEN 'santa barbara d''oeste'
		WHEN customer_city = 'mogi-mirim' THEN 'mogi mirim'
		WHEN customer_city = 'estrela d oeste' THEN 'estrela d''oeste'
		WHEN customer_city = 'parati' THEN 'paraty'
		WHEN customer_city = 'brasopolis' THEN 'brazopolis'
		WHEN customer_city = 'piumhii' THEN 'piumhi'
		WHEN customer_city = 'dias d avila' THEN 'dias d''avila'
		WHEN customer_city = 'itapage' THEN 'itapaje'
		WHEN customer_city = 'bataipora' THEN 'bataypora'
		WHEN customer_city = 'sao jorge do oeste' THEN 'sao jorge d''oeste'
		WHEN customer_city = 'picarras' THEN 'balneario picarras'
		WHEN customer_city = 'palmeira d oeste' THEN 'palmeira d''oeste'
		WHEN customer_city = 'arraial d ajuda' THEN 'arraial d''ajuda'
		ELSE customer_city
	END AS customer_city,
	customer_state
FROM bronze.olist_customers_dataset;

-- checking whether all rows get to silver.customers
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_customers_dataset; 

SELECT 
	COUNT(*) AS row_count
FROM silver.customers;

-- checking whether the transformation was done correctly
SELECT
	ocd.customer_city AS bronze_customer_city, 	
	c.customer_city AS silver_customer_city
FROM silver.customers c
INNER JOIN bronze.olist_customers_dataset ocd 
	ON c.customer_id = ocd.customer_id
WHERE c.customer_city != ocd.customer_city
GROUP BY c.customer_city, ocd.customer_city;

SELECT
    customer_zip_code_prefix,
    STRING_AGG(DISTINCT customer_city, ', ') AS same_zip_code_cities,
    COUNT(DISTINCT customer_city) AS customer_city_count
FROM silver.customers
GROUP BY customer_zip_code_prefix
HAVING COUNT(DISTINCT customer_city) > 1;

------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_orders_dataset -> silver.orders

-- Bronze conclusion:
-- Column order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date and 
-- order_estimated_delivery_date have data type VARCHAR and contain information about date and time - requires change 
-- data type to TIMESTAMP.
-- In columns order_approved_at, order_delivered_carrier_date and order_delivered_customer_date are empty values.
-- Missing timestamp values are stored as empty - they should be converted to NULL in Silver layer.

CREATE VIEW silver.orders AS
SELECT 
	order_id,
	customer_id,
	order_status,
	CAST(order_purchase_timestamp AS TIMESTAMP) AS order_purchase_timestamp, 
	CAST(NULLIF(order_approved_at, '') AS TIMESTAMP) AS order_approved_at, 
	CAST(NULLIF(order_delivered_carrier_date, '') AS TIMESTAMP) AS order_delivered_carrier_date, 
	CAST(NULLIF(order_delivered_customer_date, '') AS TIMESTAMP) AS order_delivered_customer_date,
	CAST(order_estimated_delivery_date AS TIMESTAMP) AS order_estimated_delivery_date
FROM bronze.olist_orders_dataset;

-- checking whether all rows get to silver.orders
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_orders_dataset;

SELECT 
	COUNT(*) AS row_count
FROM silver.orders;

-- checking whether the transformation was done correctly
SELECT
	column_name,
	data_type
FROM information_schema.columns
WHERE table_schema = 'silver' AND table_name = 'orders';

SELECT COUNT(*)
FROM bronze.olist_orders_dataset
WHERE order_approved_at = '';

SELECT
    COUNT(*) AS transformed_rows
FROM silver.orders o
INNER JOIN bronze.olist_orders_dataset ood
    ON o.order_id = ood.order_id
WHERE ood.order_approved_at = '' AND o.order_approved_at IS NULL;

SELECT COUNT(*)
FROM bronze.olist_orders_dataset
WHERE order_delivered_carrier_date = '';

SELECT
	COUNT(*) AS transformed_rows
FROM silver.orders o
INNER JOIN bronze.olist_orders_dataset ood 
	ON o.order_id = ood.order_id
WHERE ood.order_delivered_carrier_date = '' AND o.order_delivered_carrier_date IS NULL;

SELECT COUNT(*)
FROM bronze.olist_orders_dataset
WHERE order_delivered_customer_date = '';

SELECT
	COUNT(*) AS transformed_rows
FROM silver.orders o
INNER JOIN bronze.olist_orders_dataset ood 
	ON o.order_id = ood.order_id
WHERE ood.order_delivered_customer_date = '' AND o.order_delivered_customer_date IS NULL;

------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_order_items_dataset -> silver.order_items

-- Bronze conclusion:
-- Column shipping_limit_date contains date and time information and should be converted to TIMESTAMP.

CREATE VIEW silver.order_items AS 
SELECT
	order_id,
	order_item_id,
	product_id,
	seller_id,
	CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_date,
	price,
	freight_value
FROM bronze.olist_order_items_dataset;

-- checking whether all rows get to silver.order_items
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_order_items_dataset;

SELECT 
	COUNT(*) AS row_count
FROM silver.order_items;

-- checking whether the transformation was done correctly
SELECT
	column_name,
	data_type
FROM information_schema.COLUMNS
WHERE table_schema = 'silver' AND table_name = 'order_items';

------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_order_payments_dataset -> silver.order_payments

CREATE VIEW silver.order_payments AS 
SELECT 
	order_id,
	payment_sequential,
	payment_type,
	payment_installments,
	payment_value
FROM bronze.olist_order_payments_dataset;

-- checking whether all rows get to silver.order_payments
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_order_payments_dataset;

SELECT 
	COUNT(*) AS row_count
FROM silver.order_payments;

------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_order_reviews_dataset -> silver.order_reviews

-- Bronze conclusion:
-- Column review_creation_date has data type VARCHAR and contain information about date - requires changing data type to
-- DATE.
-- Column review_answer_timestamp has data type VARCHAR and contain information about date and time - requires changing
-- data type to TIMESTAMP.

CREATE VIEW silver.order_reviews AS 
SELECT
	review_id,
	order_id,
	review_score,
	review_comment_title,
	review_comment_message,
	CAST(review_creation_date AS DATE) AS review_creation_date,
	CAST(review_answer_timestamp AS TIMESTAMP) AS review_answer_timestamp 
FROM bronze.olist_order_reviews_dataset;

-- checking whether all rows get to silver.order_reviews
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_order_reviews_dataset;

SELECT 
	COUNT(*) AS row_count
FROM silver.order_reviews;

-- checking whether the transformation was done correctly
SELECT
	column_name,
	data_type
FROM information_schema.COLUMNS
WHERE table_schema = 'silver' AND table_name = 'order_reviews';
------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_products_dataset -> silver.products

-- Bronze conclusion:
-- 610 products have an empty product_category_name.
-- These products also have missing product name length, description length and photo quantity information.
-- 2 products have missing weight and dimension information.
-- Some category names are similar (e.g. casa_conforto / casa_conforto_2).
-- They are retained as separate source categories.
-- 4 products have product_weight_g = 0 while their dimensions are filled. Zero is considered an invalid product weight.
-- The correct weight cannot be inferred from the available data. In Silver layer product_weight_g = 0 should be
-- converted to NULL.

CREATE VIEW silver.products AS 
SELECT 
	product_id,
	NULLIF(product_category_name, '') AS product_category_name,
	product_name_lenght AS product_name_length,
	product_description_lenght AS product_description_length,
	product_photos_qty,
	NULLIF(product_weight_g, 0) AS product_weight_g,
	product_length_cm,
	product_height_cm, 
	product_width_cm 
FROM bronze.olist_products_dataset;

-- checking whether all rows get to silver.products
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_products_dataset;

SELECT 
	COUNT(*) AS row_count
FROM silver.products;

-- checking whether the transformation was done correctly
SELECT
	product_category_name
FROM silver.products
WHERE product_category_name = '';

SELECT
	product_weight_g 
FROM silver.products
WHERE product_weight_g = 0;
------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_sellers_dataset -> silver.sellers

-- Bronze conclusion:
-- Some zip code prefixes are associated with multiple city names.
-- The result shows some naming inconsistencies - requires further validation before standardization in the Silver layer.

-- cities with the same zip code prefix
SELECT
	seller_zip_code_prefix,
	STRING_AGG(DISTINCT seller_city, ', ') AS same_zip_code_cities,
	COUNT(DISTINCT seller_city) AS seller_city_count
FROM bronze.olist_sellers_dataset
GROUP BY seller_zip_code_prefix
HAVING COUNT(DISTINCT seller_city) > 1;

-- creating silver.sellers view
CREATE VIEW silver.sellers AS 
SELECT
	seller_id,
	seller_zip_code_prefix,
	CASE 
		WHEN seller_city = 'sao paulo sp' THEN 'sao paulo'
		WHEN seller_city = 'garulhos' THEN 'guarulhos'
		WHEN seller_city = 'mogi das cruses' THEN 'mogi das cruzes'
		WHEN seller_city = 'sando andre' THEN 'santo andre'
		WHEN seller_city = 'santo andre/sao paulo' THEN 'santo andre'
		WHEN seller_city = 'maua/sao paulo' THEN 'maua'
		WHEN seller_city = 'sao bernardo do capo' THEN 'sao bernardo do campo'
		WHEN seller_city = 'santa barbara d oeste' THEN 'santa barbara d''oeste'
		WHEN seller_city = 'portoferreira' THEN 'porto ferreira'
		WHEN seller_city = 'scao jose do rio pardo' THEN 'sao jose do rio pardo'
		WHEN seller_city = 'robeirao preto' THEN 'ribeirao preto'
		WHEN seller_city = 'riberao preto' THEN 'ribeirao preto'
		WHEN seller_city = 'ribeirao preto / sao paulo' THEN 'ribeirao preto'
		WHEN seller_city = 'auriflama/sp' THEN 'auriflama'
		WHEN seller_city = 'belo horizont' THEN 'belo horizonte'
		WHEN seller_city = 'cascavael' THEN 'cascavel'
		WHEN seller_city = 'floranopolis' THEN 'florianopolis'
		WHEN seller_city = 'balenario camboriu' THEN 'balneario camboriu'
		WHEN seller_city = 'lages - sc' THEN 'lages'
		WHEN seller_city = 'sao miguel d''oeste' THEN 'sao miguel do oeste'
		WHEN seller_city = 'rio de janeiro, rio de janeiro, brasil' THEN 'rio de janeiro'
		WHEN seller_city = '04482255' THEN NULL
		WHEN seller_city = 'vendas@creditparts.com.br' THEN NULL
		ELSE seller_city		
	END AS seller_city,
	seller_state 
FROM bronze.olist_sellers_dataset;

-- checking whether all rows get to silver.sellers
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_sellers_dataset; 

SELECT 
	COUNT(*) AS row_count
FROM silver.sellers;

-- checking whether the transformation was done correctly
SELECT
	osd.seller_city AS bronze_seller_city, 	
	s.seller_city AS silver_seller_city
FROM silver.sellers s
INNER JOIN bronze.olist_sellers_dataset osd 
	ON s.seller_id = osd.seller_id
WHERE s.seller_city != osd.seller_city
GROUP BY s.seller_city, osd.seller_city;

SELECT
    osd.seller_city AS bronze_seller_city,
    s.seller_city AS silver_seller_city
FROM silver.sellers s
INNER JOIN bronze.olist_sellers_dataset osd
    ON s.seller_id = osd.seller_id
WHERE s.seller_city IS NULL;

SELECT
    seller_zip_code_prefix,
    STRING_AGG(DISTINCT seller_city, ' | ') AS same_zip_code_cities,
    COUNT(DISTINCT seller_city) AS seller_city_count
FROM silver.sellers
GROUP BY seller_zip_code_prefix
HAVING COUNT(DISTINCT seller_city) > 1;

------------------------------------------------------------------------------------------------------------------------
-- bronze.olist_geolocation_dataset -> silver.geolocation

-- Bronze conclusion:
-- The dataset contains fully duplicated rows.
-- These duplicates should be removed in the Silver layer.
-- Some ZIP code prefixes are associated with multiple city names.
-- The result shows some naming inconsistencies - requires further validation before any standardization in the Silver 
-- layer.

-- cities with the same zip code prefix
SELECT
	geolocation_zip_code_prefix,
	STRING_AGG(DISTINCT geolocation_city, ', ') AS same_zip_code_cities,
	COUNT(DISTINCT geolocation_city) AS geolocation_city_count
FROM bronze.olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_city) > 1;

SELECT DISTINCT geolocation_city
FROM bronze.olist_geolocation_dataset
ORDER BY geolocation_city;

-- creating silver.geolocation view
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE VIEW silver.geolocation AS 
SELECT DISTINCT 
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	CASE 
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = '* cidade' THEN NULL 
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = '...arraial do cabo' THEN 'arraial do cabo'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = '´teresopolis' THEN 'teresopolis'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = '4o. centenario' THEN '4º centenario'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = 'alta floresta d''oeste' THEN 'alta floresta do oeste'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = 'alta floresta doeste' THEN 'alta floresta do oeste'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = 'aparecida d oeste' THEN 'aparecida d''oeste'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = 'aparecida doeste' THEN 'aparecida d''oeste'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = 'arraial d ajuda' THEN 'arraial d''ajuda'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = 'armacao de buzios' THEN 'armacao dos buzios'
		WHEN TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g')) = 'balneario de picarras' THEN 'balneario picarras'
		ELSE TRIM(REGEXP_REPLACE(REPLACE(unaccent(geolocation_city), '-', ' '), ' +', ' ', 'g'))
	END AS geolocation_city,
	geolocation_state 
FROM bronze.olist_geolocation_dataset;


-- comparing row counts before and after duplicate removal and normalization
SELECT 
	COUNT(*) AS row_count
FROM bronze.olist_geolocation_dataset; 

SELECT 
	COUNT(*) AS row_count
FROM silver.geolocation;

-- checking whether the transformation was done correctly (duplicate removal and remaining city-name inconsistencies)
SELECT
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	geolocation_city,
	geolocation_state
FROM silver.geolocation
GROUP BY geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	geolocation_city,
	geolocation_state
HAVING COUNT(*) > 1;

SELECT
	geolocation_zip_code_prefix,
	STRING_AGG(DISTINCT geolocation_city, ', ') AS same_zip_code_cities,
	COUNT(DISTINCT geolocation_city) AS geolocation_city_count
FROM silver.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_city) > 1;

SELECT
	DISTINCT geolocation_city
FROM silver.geolocation
ORDER BY geolocation_city;

-- Silver conclusion:
-- Exact duplicate rows were removed.
-- City names were normalized for diacritics, hyphens and whitespace.
-- Selected unambiguous naming inconsistencies were corrected manually.
-- Additional likely spelling errors and naming variants were identified, but extensive manual standardization was not
-- applied without a reliable geographic reference, to keep the transformation consistent and avoid incorrect mappings.

------------------------------------------------------------------------------------------------------------------------
-- bronze.product_category_name_translation -> silver.category_translation

CREATE VIEW silver.category_translation AS 
SELECT 
	product_category_name,
	product_category_name_english 
FROM bronze.product_category_name_translation;

-- checking whether all rows get to silver.category_translation
SELECT 
	COUNT(*) AS row_count
FROM bronze.product_category_name_translation; 

SELECT 
	COUNT(*) AS row_count
FROM silver.category_translation;

------------------------------------------------------------------------------------------------------------------------
-- Silver layer summary --

-- checking all views created in the Silver layer
SELECT 
	DISTINCT table_name
FROM information_schema.columns
WHERE table_schema = 'silver';

-- Silver layer is complete and ready for EDA.
-- It contains 9 cleaned views. Data types and text values were standardized where needed.
-- Exact duplicates in geolocation were removed, while ambiguous source anomalies were preserved rather than estimated.



