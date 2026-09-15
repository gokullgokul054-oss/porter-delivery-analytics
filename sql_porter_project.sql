CREATE DATABASE porter_delivery_analysis;

USE porter_delivery_analysis;

CREATE TABLE porter_orders (
    market_id INT,
    created_at_date DATE,
    created_at_time TIME,
    actual_delivery_date DATE,
    actual_delivery_time TIME,
    store_primary_category INT,
    order_protocol INT,
    total_items INT,
    subtotal INT,
    num_distinct_items INT,
    min_item_price INT,
    max_item_price INT,
    total_onshift_dashers INT,
    total_busy_dashers INT,
    total_outstanding_orders INT,
    estimated_store_to_consumer_driving_duration INT
);
### Check data
SELECT *
FROM porter_delivey_db
LIMIT 10;

SELECT COUNT(*) AS total_records
FROM porter_delivey_db;

DESCRIBE porter_delivey_db;


#### Check NULL values

SELECT
    SUM(market_id IS NULL) AS null_market_id,
    SUM(created_at_date IS NULL) AS null_created_date,
    SUM(created_at_time IS NULL) AS null_created_time,
    SUM(actual_delivery_date IS NULL) AS null_delivery_date,
    SUM(actual_delivery_time IS NULL) AS null_delivery_time,
    SUM(store_primary_category IS NULL) AS null_category,
    SUM(order_protocol IS NULL) AS null_protocol,
    SUM(total_items IS NULL) AS null_total_items,
    SUM(subtotal IS NULL) AS null_subtotal,
    SUM(num_distinct_items IS NULL) AS null_distinct_items,
    SUM(min_item_price IS NULL) AS null_min_price,
    SUM(max_item_price IS NULL) AS null_max_price,
    SUM(total_onshift_dashers IS NULL) AS null_onshift,
    SUM(total_busy_dashers IS NULL) AS null_busy,
    SUM(total_outstanding_orders IS NULL) AS null_outstanding,
    SUM(estimated_store_to_consumer_driving_duration IS NULL) 
        AS null_delivery_duration
FROM porter_delivey_db;

### Check duplicates
SELECT
    market_id,created_at_date,created_at_time,actual_delivery_date,actual_delivery_time,store_primary_category,
    order_protocol,total_items,subtotal,
    COUNT(*) AS duplicate_count
FROM porter_delivey_db
GROUP BY market_id,created_at_date,created_at_time,actual_delivery_date,actual_delivery_time,store_primary_category,
order_protocol,total_items,subtotal
HAVING COUNT(*) > 1;

#### Check negative values

SELECT *
FROM porter_delivey_db
WHERE total_items < 0
   OR subtotal < 0
   OR num_distinct_items < 0
   OR min_item_price < 0
   OR max_item_price < 0
   OR total_onshift_dashers < 0
   OR total_busy_dashers < 0
   OR total_outstanding_orders < 0
   OR estimated_store_to_consumer_driving_duration < 0;
   
   ### Basic analysis
   
  ## Total orders
SELECT COUNT(*) AS total_orders
FROM porter_delivey_db;


##Total items
SELECT SUM(total_items) AS total_items
FROM porter_delivey_db;


##Total sales
SELECT SUM(subtotal) AS total_revenue
FROM porter_delivey_db;


##Average order value
SELECT ROUND(AVG(subtotal), 2) AS average_order_value
FROM porter_delivey_db;


##Average items per order
SELECT ROUND(AVG(total_items), 2) AS avg_items_per_order
FROM porter_delivey_db;


## Maximum order value
SELECT MAX(subtotal) AS maximum_order_value
FROM porter_delivey_db;


## Minimum order value
SELECT MIN(subtotal) AS minimum_order_value
FROM porter_delivey_db;

###Category analysis
### Top categories by revenue
SELECT
    store_primary_category,
    COUNT(*) AS total_orders,
    SUM(total_items) AS total_items,
    SUM(subtotal) AS revenue,
    ROUND(AVG(subtotal), 2) AS avg_order_value
FROM porter_delivey_db
GROUP BY store_primary_category
ORDER BY revenue DESC;

###Top categories by orders

SELECT
    store_primary_category,
    COUNT(*) AS total_orders
FROM porter_delivey_db
GROUP BY store_primary_category
ORDER BY total_orders DESC;

###Order protocol analysis
SELECT
    order_protocol,
    COUNT(*) AS total_orders,
    SUM(subtotal) AS revenue,
    ROUND(AVG(subtotal), 2) AS avg_order_value
FROM porter_delivey_db
GROUP BY order_protocol
ORDER BY total_orders DESC;

###Market analysis
SELECT
    market_id,
    COUNT(*) AS total_orders,
    SUM(subtotal) AS revenue,
    ROUND(AVG(subtotal), 2) AS avg_order_value
FROM porter_delivey_db
GROUP BY market_id
ORDER BY revenue DESC;


###Delivery-duration analysis
SELECT
    ROUND(AVG(estimated_store_to_consumer_driving_duration), 2)
        AS avg_delivery_duration
FROM porter_delivey_db;

SELECT
    MIN(estimated_store_to_consumer_driving_duration) AS minimum_duration,
    MAX(estimated_store_to_consumer_driving_duration) AS maximum_duration,
    ROUND(AVG(estimated_store_to_consumer_driving_duration), 2) AS average_duration
FROM porter_delivey_db;

### Duration by category
SELECT
    store_primary_category,
    COUNT(*) AS total_orders,
    ROUND(AVG(estimated_store_to_consumer_driving_duration), 2)
        AS avg_delivery_duration
FROM porter_delivey_db
GROUP BY store_primary_category
ORDER BY avg_delivery_duration DESC;

### Dasher analysis
SELECT
    ROUND(AVG(total_onshift_dashers), 2) AS avg_onshift_dashers,
    ROUND(AVG(total_busy_dashers), 2) AS avg_busy_dashers,
    ROUND(AVG(total_outstanding_orders), 2) AS avg_outstanding_orders
FROM porter_delivey_db;

#### Busy dashers percentage
SELECT
    ROUND(
        SUM(total_busy_dashers) /
        NULLIF(SUM(total_onshift_dashers), 0) * 100,
        2
    ) AS busy_dasher_percentage
FROM porter_delivey_db;

###Orders by date
SELECT
    created_at_date,
    COUNT(*) AS total_orders,
    SUM(subtotal) AS revenue
FROM porter_delivey_db
GROUP BY created_at_date
ORDER BY created_at_date;

###Orders by month
SELECT
    YEAR(created_at_date) AS year,
    MONTH(created_at_date) AS month,
    COUNT(*) AS total_orders,
    SUM(subtotal) AS revenue
FROM porter_delivey_db
GROUP BY
    YEAR(created_at_date),
    MONTH(created_at_date)
ORDER BY year, month;

###Monthly growth
WITH monthly_sales AS (
    SELECT
        YEAR(created_at_date) AS year,
        MONTH(created_at_date) AS month,
        SUM(subtotal) AS revenue
    FROM porter_delivey_db
    GROUP BY
        YEAR(created_at_date),
        MONTH(created_at_date)
)

SELECT
    year,
    month,
    revenue,
    LAG(revenue) OVER (
        ORDER BY year, month
    ) AS previous_month_revenue,
    ROUND(
        (
            revenue -
            LAG(revenue) OVER (
                ORDER BY year, month
            )
        )
        /
        NULLIF(
            LAG(revenue) OVER (
                ORDER BY year, month
            ), 0
        ) * 100,
        2
    ) AS mom_growth_percentage
FROM monthly_sales
ORDER BY year, month;

### Top 10 highest-value orders
SELECT * FROM porter_delivey_db
ORDER BY subtotal DESC
LIMIT 10;

### Top categories using RANK
WITH category_sales AS (
    SELECT
        store_primary_category,
        SUM(subtotal) AS revenue
    FROM  porter_delivey_db
    GROUP BY store_primary_category
)

SELECT
    store_primary_category,
    revenue,
    RANK() OVER (
        ORDER BY revenue DESC
    ) AS category_rank
FROM category_sales
ORDER BY category_rank;

#### Order-value groups
SELECT
    CASE
        WHEN subtotal < 200
            THEN 'Low Value'
        WHEN subtotal < 500
            THEN 'Medium Value'
        WHEN subtotal < 1000
            THEN 'High Value'
        ELSE 'Very High Value'
    END AS order_value_group,
    COUNT(*) AS total_orders,
    SUM(subtotal) AS revenue
FROM porter_delivey_db
GROUP BY order_value_group
ORDER BY revenue DESC;


### Outstanding-order analysis
SELECT
    ROUND(AVG(total_outstanding_orders), 2)
        AS avg_outstanding_orders,
    MAX(total_outstanding_orders)
        AS maximum_outstanding_orders
FROM porter_delivey_db;

####Outstanding orders by market
SELECT
    market_id,
    ROUND(AVG(total_outstanding_orders), 2)
        AS avg_outstanding_orders,
    MAX(total_outstanding_orders)
        AS max_outstanding_orders
FROM porter_delivey_db
GROUP BY market_id
ORDER BY avg_outstanding_orders DESC;


####Relationship between dashers and outstanding orders
SELECT
    ROUND(AVG(total_onshift_dashers), 2) AS avg_onshift_dashers,
    ROUND(AVG(total_busy_dashers), 2) AS avg_busy_dashers,
    ROUND(AVG(total_outstanding_orders), 2) AS avg_outstanding_orders
FROM porter_delivey_db;

####CREATE VIEW porter_cleaned AS
SELECT
    market_id,
    created_at_date,
    created_at_time,
    actual_delivery_date,
    actual_delivery_time,
    store_primary_category,
    order_protocol,
    total_items,
    subtotal,
    num_distinct_items,
    min_item_price,
    max_item_price,
    total_onshift_dashers,
    total_busy_dashers,
    total_outstanding_orders,
    estimated_store_to_consumer_driving_duration
FROM porter_delivey_db
WHERE subtotal >= 0
  AND total_items >= 0
  AND estimated_store_to_consumer_driving_duration >= 0;