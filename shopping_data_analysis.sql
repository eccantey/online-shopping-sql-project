use Shopping;

-- create a temp table with the totals of each order to be used throughout this query

SELECT order_id,
       SUM(quantity * unit_price_usd) AS order_total
  INTO #total
  FROM OrderDetails
 GROUP BY order_id;

 -- get top 100 customers with the most delivered orders

  WITH cust_totals AS (
       SELECT o.customer_id,
              COUNT(*) AS num_orders,
              SUM(t.order_total) AS total
         FROM Orders o
              JOIN #total t
              ON t.order_id = o.order_id
        WHERE order_status = 'Delivered'
        GROUP BY customer_id
       )
SELECT CONCAT(c.first_name, ' ', c.last_name) AS cust_name,
       c.city,
       c.state_province,
       c.country,
       ct.num_orders,
       ct.total
  FROM Customers c
       JOIN cust_totals ct
       ON ct.customer_id = c.customer_id
 ORDER BY ct.total DESC;
       
-- create monthly sales summary with number of delivered or active orders and total sales by month

SELECT YEAR(o.order_date) AS year,
       MONTH(o.order_date) AS month,
       COUNT(o.order_id) AS num_orders,
       SUM(t.order_total) AS sales_total
  FROM Orders o
       JOIN #total t
       ON o.order_id = t.order_id
 WHERE o.order_status != 'Canceled'
 GROUP BY MONTH(o.order_date), YEAR(o.order_date)
 ORDER BY year DESC, month DESC;

-- same report but quarterly

SELECT YEAR(o.order_date) as year,
       DATEPART(QUARTER, o.order_date) as qtr,
       COUNT(o.order_id) AS num_orders,
       SUM(t.order_total) AS sales_total
  FROM Orders o
       JOIN #total t
       ON o.order_id = t.order_id
 WHERE o.order_status != 'Canceled'
 GROUP BY YEAR(o.order_date), DATEPART(QUARTER, o.order_date)
 ORDER BY year DESC, qtr DESC;

-- get the number of packages delivered late by month, both as a raw count and as a percentage

SELECT YEAR(o.order_date) AS year,
       MONTH(o.order_date) AS month,
       COUNT(CASE WHEN o.delivery_date > o.exp_delivery_date THEN 1 END) AS late_deliveries,
       COUNT(o.order_id) AS num_deliveries,
       CAST(100.0 * COUNT(CASE WHEN o.delivery_date > o.exp_delivery_date THEN 1 END) / 
       COUNT(o.order_id) AS DECIMAL(10,2)) AS late_pct
  FROM Orders o
 WHERE order_status = 'Delivered'
 GROUP BY MONTH(o.order_date), YEAR(o.order_date)
 ORDER BY year DESC, month DESC;

-- get each month's largest order

  WITH top_orders AS (
       SELECT YEAR(o.order_date) AS order_year,
              MONTH(o.order_date) AS order_month,
              o.order_id, SUM(t.order_total) as order_total,
              RANK() OVER (
                PARTITION BY MONTH(o.order_date), YEAR(o.order_date)
                ORDER BY SUM(t.order_total) DESC
              ) AS rnk
         FROM Orders o
              JOIN #total t
              ON o.order_id = t.order_id
        GROUP BY o.order_id, o.order_date
       )
SELECT order_year, order_month, order_id as largest_order_id, order_total
  FROM top_orders
 WHERE rnk = 1
 ORDER BY order_year DESC, order_month DESC;

-- top-selling products from each category and their overall rank

SELECT product_name, supplier_name, category, num_sold, overall_rnk
  FROM (
        SELECT p.product_id, p.product_name, supplier_name,
               p.category, SUM(od.quantity) AS num_sold,
               RANK() OVER (PARTITION BY p.category ORDER BY SUM(od.quantity) DESC) AS category_rnk,
               RANK() OVER (ORDER BY SUM(od.quantity) DESC) AS overall_rnk
          FROM Products p
               JOIN OrderDetails od
               ON od.product_id = p.product_id
               JOIN Suppliers s
               ON s.supplier_id = p.supplier_id
         GROUP BY p.product_id, product_name, s.supplier_name, p.category
       ) AS ProductCtgyRnk
 WHERE category_rnk = 1
 ORDER BY overall_rnk;

/*
Show each customer's orders and the days in between each order, with first orders indicated
by a prev_order_date value of 'First Order'
*/

  WITH order_interval AS (
       SELECT customer_id,
              order_date,
              COALESCE(CAST(LAG(order_date, 1) OVER (
                PARTITION BY customer_id
                ORDER BY order_date
              ) AS VARCHAR(100)), 'First Order') AS prev_order_date
         FROM orders
       )
SELECT *,
       CASE
         WHEN prev_order_date = 'First Order' THEN 0
         ELSE COALESCE(DATEDIFF(DAY, CAST(prev_order_date AS DATE), order_date), 0)
       END AS days_between
  FROM order_interval
 ORDER BY customer_id, order_date DESC;

/* 
Get information of customers who have either signed up or placed an order in 2026,
ordered descending by later of registration date or most recent order date 
*/

  WITH order_seq AS (
       SELECT customer_id,
              order_date,
              ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS most_recent
         FROM orders
       )
SELECT CONCAT(c.first_name, ' ', c.last_name) AS cust_name,
       c.city,
       c.state_province,
       c.country,
       FORMAT(c.registration_date, 'dd MMM yyyy') AS registration_date,
       COALESCE(FORMAT(os.order_date, 'dd MMM yyyy'), 'No orders placed') AS most_recent_order
  FROM customers c
       LEFT JOIN (SELECT * FROM order_seq WHERE most_recent = 1) os
       ON os.customer_id = c.customer_id
 WHERE c.registration_date > '2025-12-31'
       OR os.order_date > '2025-12-31'
 ORDER BY COALESCE(GREATEST(registration_date, order_date), registration_date) DESC;

-- create a day-to-day sales report with 7-day and 30-day rolling totals going back to the first registration

  WITH dates AS (
       SELECT MIN(registration_date) AS date
         FROM customers
        UNION ALL
       SELECT DATEADD(DAY, 1, date)
         FROM dates
        WHERE date < '2026-06-14'
       ),
       orders_by_date AS (
       SELECT o.order_date, 
              COUNT(o.order_id) AS num_orders,
              SUM(t.order_total) AS sales_total
         FROM orders o
              JOIN #total t
              ON t.order_id = o.order_id
        WHERE o.order_status != 'Canceled'
        GROUP BY order_date
       )
SELECT d.date,
       ISNULL(obd.num_orders, 0) AS num_orders,
       ISNULL(obd.sales_total, 0) AS sales_total,
       COALESCE(SUM(obd.num_orders) OVER (
         ORDER BY d.date
         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ), 0) AS rolling_7_day_total_orders,
       COALESCE(SUM(obd.sales_total) OVER (
         ORDER BY d.date
         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ), 0) AS rolling_7_day_total_sales,
       COALESCE(SUM(obd.num_orders) OVER (
         ORDER BY d.date
         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
       ), 0) AS rolling_30_day_total_orders,
       COALESCE(SUM(obd.sales_total) OVER (
         ORDER BY d.date
         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
       ), 0) AS rolling_30_day_total_sales      
  FROM dates d
       LEFT JOIN orders_by_date obd
       ON d.date = obd.order_date
 ORDER BY d.date DESC
OPTION (maxrecursion 1000);

-- find out when every product was most recently ordered

  WITH most_recent AS (
       SELECT od.product_id,
              MAX(o.order_date) AS order_date
         FROM OrderDetails od
              JOIN orders o
              ON o.order_id = od.order_id
        GROUP BY od.product_id
       )
SELECT p.product_name, s.supplier_name, p.category, FORMAT(mr.order_date, 'dd MMM yyyy') AS most_recently_ordered
  FROM products p
       JOIN Suppliers s
       ON s.supplier_id = p.supplier_id
       JOIN most_recent mr
       ON mr.product_id = p.product_id
 ORDER BY mr.order_date DESC;

 -- most ordered products of 2025

  with last_year as (
       select od.product_id,
              sum(od.quantity) as num_sold
         from OrderDetails od
              join Orders o
              on o.order_id = od.order_id
        where o.order_date between '2025-01-01' and '2025-12-31'
        group by od.product_id
       )
select p.product_name, s.supplier_name, p.category, ly.num_sold
  from Products p
       join Suppliers s
       on s.supplier_id = p.supplier_id
       join last_year ly
       on ly.product_id = p.product_id
 order by num_sold desc;

-- get three top-selling categories for each month
SELECT *
  FROM (
       SELECT YEAR(o.order_date) AS year,
              MONTH(o.order_date) AS month,
              p.category, SUM(od.quantity) AS qty_sold,
              RANK() OVER (
                PARTITION BY YEAR(o.order_date), MONTH(o.order_date)
                ORDER BY SUM(od.quantity) DESC
              ) AS rnk
         FROM products p
              JOIN OrderDetails od 
              ON od.product_id = p.product_id 
              JOIN Orders o 
              ON o.order_id = od.order_id
        GROUP BY YEAR(o.order_date), MONTH(o.order_date), category
       ) AS ctgy_by_month
 WHERE rnk < 4
 ORDER BY year DESC, month DESC, rnk