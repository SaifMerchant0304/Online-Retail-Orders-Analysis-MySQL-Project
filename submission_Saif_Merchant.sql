	
/*---------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/

-- QUESTIONS RELATED TO CUSTOMERS
USE new_wheels_new;
SHOW tables;

/*------------------------------------------------------------------------------------------------------------------------------------*/

-- [Q1] What is the distribution of customers across states?
-- Hint: For each state, count the number of customers.

-- Select the 'state' column and count the number of 'customer_id' values in each state.
SELECT state, COUNT(customer_id) AS number_of_customers
-- From the 'customer_t' table.
FROM customer_t
-- Group the results by the 'state' column to count customers in each state.
GROUP BY state;
-- -------------------------------------------------------------------------------------------------------------------------------------

-- [Q2] What is the average rating in each quarter?
-- Hint: Use a common table expression (CTE) to assign numbers to different customer ratings and then calculate the average feedback for each quarter.

-- Create a CTE named RATING_CTE.
WITH RATING_CTE AS
(
    -- Select the 'customer_feedback' and 'quarter_number' columns and assign numeric values to different customer ratings.
    SELECT customer_feedback, quarter_number,
        CASE customer_feedback
            WHEN 'Very Bad' THEN 1
            WHEN 'Bad' THEN 2
            WHEN 'Okay' THEN 3
            WHEN 'Good' THEN 4
            WHEN 'Very Good' THEN 5
        END AS rating
    FROM order_t
)

-- Select the 'quarter_number' and calculate the rounded average rating for each quarter.
SELECT quarter_number, ROUND(AVG(rating), 1) AS average_rating
-- From the RATING_CTE.
FROM RATING_CTE
-- Group the results by 'quarter_number' to calculate the average for each quarter.
GROUP BY quarter_number;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- [Q3] Are customers getting more dissatisfied over time?
-- Hint: Calculate the percentage of different types of customer feedback in each quarter to see the trend in customer satisfaction over time.

-- Create a Common Table Expression (CTE) named FEEDBACK_CTE.
WITH FEEDBACK_CTE AS
(
    -- Select the 'quarter_number' and count the number of different types of customer feedback for each quarter.
    SELECT 
        quarter_number,
        SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS VeryGood_Feedback,
        SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) AS Good_Feedback,
        SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS Okay_Feedback,
        SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS Bad_Feedback,
        SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) AS VeryBad_Feedback,
        COUNT(*) AS Total_Feedback
    FROM order_t
    -- Group the results by 'quarter_number' to calculate feedback for each quarter.
    GROUP BY quarter_number
)

-- Select and display the results.
SELECT 
    quarter_number,
    VeryGood_Feedback,
    Good_Feedback,
    Okay_Feedback,
    Bad_Feedback,
    VeryBad_Feedback,
    Total_Feedback,
    -- Calculate the percentage of each type of feedback for each quarter.
    (VeryGood_Feedback / Total_Feedback) * 100 AS Percentage_VeryGood,
    (Good_Feedback / Total_Feedback) * 100 AS Percentage_Good,
    (Okay_Feedback / Total_Feedback) * 100 AS Percentage_Okay,
    (Bad_Feedback / Total_Feedback) * 100 AS Percentage_Bad,
    (VeryBad_Feedback / Total_Feedback) * 100 AS Percentage_VeryBad
-- From the FEEDBACK_CTE
FROM FEEDBACK_CTE
-- Order the results by 'quarter_number' to see the trend over time.
ORDER BY quarter_number;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- [Q4] Which are the top 5 vehicle makers preferred by the customer?
-- Hint: Count the number of customers for each vehicle maker and identify the top 5.

-- Select the 'VEHICLE_MAKER' column from the 'product_t' table and count the number of customers for each vehicle maker.
SELECT p.VEHICLE_MAKER, COUNT(o.CUSTOMER_ID) AS customer_count
-- Join the 'order_t' table with the 'product_t' table on the 'PRODUCT_ID' column to link orders with vehicle details.
FROM order_t o
JOIN product_t p ON o.PRODUCT_ID = p.PRODUCT_ID
-- Group the results by 'VEHICLE_MAKER' to calculate customer counts for each vehicle maker.
GROUP BY p.VEHICLE_MAKER
-- Order the results in descending order of customer counts to find the top 5.
ORDER BY customer_count DESC
-- Limit the results to the top 5 preferred vehicle makers.
LIMIT 5;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- [Q5] What is the most preferred vehicle make in each state?
-- Hint: Rank vehicle makers based on the count of customers for each state and select the maker with rank 1.

-- Select the 'state', 'vehicle_maker', and 'ranks' columns from the result set.
SELECT state, vehicle_maker, ranks
-- Create a subquery to calculate rankings.
FROM (
  -- Select 'state', 'vehicle_maker', and rank the vehicle makers within each state based on customer counts.
  SELECT state, vehicle_maker, rank() OVER(PARTITION BY state ORDER BY customer_count DESC) AS ranks
  -- Create another subquery to calculate customer counts for each state and vehicle maker.
  FROM (
    -- Select 'state', 'vehicle_maker', and count the number of customers for each combination.
    SELECT c.state, p.vehicle_maker, COUNT(o.customer_id) AS customer_count
    -- Join the necessary tables to link orders, products, and customers.
    FROM order_t o
    JOIN product_t p ON o.product_id = p.product_id
    JOIN customer_t c ON o.customer_id = c.customer_id
    -- Group the results by 'state' and 'vehicle_maker'.
    GROUP BY c.state, p.vehicle_maker
  ) AS t
) AS ranked_data
-- Filter the results to only include rows where the rank is 1, representing the most preferred vehicle maker.
WHERE ranks = 1;
----------------------------------------------------------------------------------------------------------------------------


/*QUESTIONS RELATED TO REVENUE and ORDERS 
*/


-----------------------------------------------------------------------------------------------------------------------------------

-- [Q6] What is the trend of the number of orders by quarters?
-- Hint: Count the number of orders for each quarter to observe the order trend over time.

-- Select the 'quarter_number' and count the number of 'order_id' values for each quarter.
SELECT quarter_number, COUNT(order_id) AS order_count
-- From the 'order_t' table.
FROM order_t
-- Group the results by 'quarter_number' to count orders for each quarter.
GROUP BY quarter_number
-- Order the results by 'quarter_number' in ascending order to see the trend over time.
ORDER BY quarter_number ASC;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- [Q7] What is the quarter-over-quarter % change in revenue?
-- Hint: Calculate the percentage change in revenue from one quarter to the next quarter using a Common Table Expression (CTE) and the LAG function.

-- Create a CTE named 'revenue_by_quarter' to calculate revenue for each quarter.
WITH revenue_by_quarter AS (
  -- Select 'quarter_number' and calculate the sum of revenue (vehicle_price - discount) for each quarter.
  SELECT quarter_number, ROUND(SUM(quantity * (vehicle_price - ((discount/100)*vehicle_price))), 0) AS revenue
  FROM order_t
  -- Group the results by 'quarter_number' to calculate revenue for each quarter.
  GROUP BY quarter_number
  -- Order the results in ascending order of 'quarter_number'.
  ORDER BY quarter_number ASC
)

-- Select 'quarter_number', 'revenue', and calculate the quarter-over-quarter revenue change in percentage.
SELECT
  quarter_number, revenue,
  ROUND(LAG(revenue) OVER(ORDER BY quarter_number), 0) AS previous_revenue,
  ROUND((revenue - LAG(revenue) OVER(ORDER BY quarter_number))/(LAG(revenue) OVER(ORDER BY quarter_number)) * 100, 2) AS qoq_change
-- From the 'revenue_by_quarter' CTE.
FROM revenue_by_quarter;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- [Q8] What is the trend of revenue and orders by quarters?
-- Hint: Calculate the total revenue and count the number of orders for each quarter to observe the revenue and order trend over time.

-- Select the 'quarter_number' and calculate the sum of revenue (vehicle_price - discount) for each quarter.
-- Also, count the number of 'ORDER_ID' values for each quarter.

SELECT
    quarter_number, -- Select the quarter number.
    ROUND(SUM(quantity * (vehicle_price - (discount/100) * vehicle_price))) AS total_revenue, -- Calculate total revenue by summing the revenue for each quarter.
    COUNT(DISTINCT order_id) AS total_orders -- Count the total number of orders for each quarter.
FROM order_t -- Select data from the 'order_t' table.
GROUP BY quarter_number -- Group the results by quarter_number to calculate revenue and orders for each quarter.
ORDER BY quarter_number; -- Order the results by quarter_number to see the trend over time.
-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING*/

 -- ---------------------------------------------------------------------------------------------------------------------------------

-- [Q9] What is the average discount offered for different types of credit cards?
-- Hint: Calculate the average discount for each credit card type.

-- Select 'credit_card_type' and calculate the average discount for each type.
SELECT credit_card_type, AVG(discount) AS avg_discount
-- Join the 'customer_t' and 'order_t' tables on 'CUSTOMER_ID' to associate credit card types with orders.
FROM customer_t
INNER JOIN order_t ON customer_t.CUSTOMER_ID = order_t.CUSTOMER_ID
-- Group the results by 'credit_card_type' to calculate the average discount for each type.
GROUP BY credit_card_type
-- Order the results in descending order of average discount to see the highest to lowest discounts.
ORDER BY avg_discount DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

-- [Q10] What is the average time taken to ship placed orders for each quarter?
-- Hint: Calculate the average shipping time in days by finding the difference between the ship date and the order date.

-- Select 'quarter_number' and calculate the average shipping time in days.
SELECT quarter_number, round(AVG(DATEDIFF(ship_date, order_date))) AS avg_shipping_time_in_days
-- From the 'order_t' table.
FROM order_t
-- Filter out rows where either 'order_date' or 'ship_date' is NULL to ensure accurate calculations.
WHERE order_date IS NOT NULL AND ship_date IS NOT NULL
-- Group the results by 'quarter_number' to calculate the average shipping time for each quarter.
GROUP BY quarter_number
-- Order the results by 'quarter_number' in ascending order to see the trend over quarters.
ORDER BY quarter_number ASC;
-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------