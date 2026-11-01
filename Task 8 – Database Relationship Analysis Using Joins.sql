USE flipkart_database;

-- ============ 1. COMBINE RELATED TABLES USING JOINS ============

-- 1.1 The foreign keys that connect the tables (the common attributes used in the joins)
SELECT table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.KEY_COLUMN_USAGE
WHERE table_schema = 'flipkart_db'
  AND referenced_table_name IS NOT NULL
  AND table_name IN ('orders', 'payment', 'order_details')
ORDER BY table_name, column_name;

-- 1.2 One query that joins all four tables: Customer, Orders, Product and Payment
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       o.order_id, p.product_name, pay.payment_status
FROM customer c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id    = od.order_id
JOIN product p        ON od.product_id = p.product_id
JOIN payment pay      ON o.order_id    = pay.order_id
ORDER BY o.order_id, p.product_name;

-- ============ 2. INNER JOIN (only rows that match in both tables) ============

-- 2.1 Display customer details along with their orders
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       c.email, c.city,
       o.order_id, o.order_date, o.total_amount, o.order_status
FROM customer c
INNER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- 2.2 Display order details with payment information
SELECT o.order_id, o.order_date, o.total_amount, o.order_status,
       pay.payment_id, pay.payment_mode, pay.payment_status, pay.payment_date, pay.transaction_amount
FROM orders o
INNER JOIN payment pay ON o.order_id = pay.order_id
ORDER BY o.order_id;

-- 2.3 Retrieve products purchased by customers (Cancelled orders are not purchases)
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       p.product_name, od.quantity, od.price, o.order_date
FROM customer c
INNER JOIN orders o         ON c.customer_id = o.customer_id
INNER JOIN order_details od ON o.order_id    = od.order_id
INNER JOIN product p        ON od.product_id = p.product_id
WHERE o.order_status <> 'Cancelled'
ORDER BY c.customer_id, o.order_date, p.product_name;

-- ============ 3. LEFT JOIN (all rows of the left table, matched or not) ============

-- 3.1 Display all customers, including customers who have not placed orders
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       o.order_id, o.order_date, o.order_status
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- 3.2 Find customers without any purchases
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, c.city
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status <> 'Cancelled'
WHERE o.order_id IS NULL;

-- 3.2b Customers who have never placed any order at all (no rows expected)
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 3.3 Display all products, including products with no sales
SELECT p.product_id, p.product_name, p.price,
       COALESCE(SUM(od.quantity), 0) AS quantity_sold
FROM product p
LEFT JOIN (order_details od
           INNER JOIN orders o ON od.order_id = o.order_id AND o.order_status <> 'Cancelled')
       ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name, p.price
ORDER BY quantity_sold DESC, p.product_name;

-- 3.3b Only the products that have no sales
SELECT p.product_id, p.product_name, p.price
FROM product p
LEFT JOIN (order_details od
           INNER JOIN orders o ON od.order_id = o.order_id AND o.order_status <> 'Cancelled')
       ON p.product_id = od.product_id
WHERE od.order_detail_id IS NULL
ORDER BY p.product_id;

-- ============ 4. RIGHT JOIN (all rows of the right table, matched or not) ============

-- 4.1 Display all orders with customer information
SELECT o.order_id, o.order_date, o.total_amount, o.order_status,
       c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, c.city
FROM customer c
RIGHT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY o.order_id;

-- 4.2 Find orders where customer details are missing (no rows expected)
SELECT o.order_id, o.customer_id, o.total_amount
FROM customer c
RIGHT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- 4.3 Display all payment records with order details
SELECT pay.payment_id, pay.payment_mode, pay.payment_status, pay.transaction_amount,
       o.order_id, o.order_date, o.total_amount, o.order_status
FROM orders o
RIGHT JOIN payment pay ON o.order_id = pay.order_id
ORDER BY pay.payment_id;

-- 4.3b Payment records whose order is missing (no rows expected)
SELECT pay.payment_id, pay.order_id
FROM orders o
RIGHT JOIN payment pay ON o.order_id = pay.order_id
WHERE o.order_id IS NULL;

-- ============ 5. COMPLETE ORDER DETAILS ============

SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       o.order_id,
       p.product_name,
       od.quantity,
       o.order_date,
       o.total_amount,
       pay.payment_status
FROM orders o
INNER JOIN customer c       ON o.customer_id = c.customer_id
INNER JOIN order_details od ON o.order_id    = od.order_id
INNER JOIN product p        ON od.product_id = p.product_id
LEFT JOIN  payment pay      ON o.order_id    = pay.order_id
ORDER BY o.order_id, p.product_name;

-- ============ 6. CUSTOMER PURCHASE HISTORY ============

-- 6.1 Display all products purchased by a customer (Arun Kumar)
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       o.order_id, o.order_date, p.product_name, od.quantity, od.price,
       od.quantity * od.price AS line_total
FROM customer c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id    = od.order_id
JOIN product p        ON od.product_id = p.product_id
WHERE c.first_name = 'Arun' AND c.last_name = 'Kumar'
  AND o.order_status <> 'Cancelled'
ORDER BY o.order_date, p.product_name;

-- 6.2 Calculate the total amount spent by each customer
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status <> 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC, c.customer_id;

-- 6.3 Count the number of orders placed by each customer (all statuses)
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       COUNT(o.order_id)                  AS orders_placed,
       COALESCE(SUM(o.order_status = 'Cancelled'), 0) AS cancelled_orders
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY orders_placed DESC, c.customer_id;

-- 6.4 Retrieve the latest purchase details of each customer
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       o.order_id, o.order_date, o.total_amount, o.order_status,
       GROUP_CONCAT(p.product_name ORDER BY p.product_name SEPARATOR ', ') AS products
FROM customer c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id    = od.order_id
JOIN product p        ON od.product_id = p.product_id
WHERE o.order_id = (SELECT o2.order_id
                    FROM orders o2
                    WHERE o2.customer_id = c.customer_id
                      AND o2.order_status <> 'Cancelled'
                    ORDER BY o2.order_date DESC, o2.order_id DESC
                    LIMIT 1)
GROUP BY c.customer_id, c.first_name, c.last_name,
         o.order_id, o.order_date, o.total_amount, o.order_status
ORDER BY c.customer_id;

-- ============ 7. MULTI-TABLE BUSINESS REPORTS ============

-- ---------- Report 1: Customer Order Report ----------
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       o.order_id, o.order_date, o.order_status
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_date, o.order_id;

-- ---------- Report 2: Sales Report ----------
SELECT p.product_name,
       SUM(od.quantity)            AS quantity_sold,
       SUM(od.quantity * od.price) AS total_revenue
FROM product p
JOIN order_details od ON p.product_id = od.product_id
JOIN orders o         ON od.order_id  = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC, p.product_name;

-- Sales totals
SELECT SUM(od.quantity)            AS total_quantity_sold,
       SUM(od.quantity * od.price) AS total_revenue
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
WHERE o.order_status <> 'Cancelled';

-- ---------- Report 3: Payment Analysis Report ----------
SELECT pay.payment_mode,
       COUNT(*)                                          AS total_transactions,
       SUM(pay.payment_status = 'Success')               AS successful_payments,
       SUM(CASE WHEN pay.payment_status = 'Success'
                THEN pay.transaction_amount ELSE 0 END)  AS successful_revenue
FROM payment pay
JOIN orders o ON pay.order_id = o.order_id
GROUP BY pay.payment_mode
ORDER BY total_transactions DESC, CAST(pay.payment_mode AS CHAR);

-- ---------- Report 4: Customer Purchase Analysis ----------
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       SUM(od.quantity)                        AS units_purchased,
       COUNT(DISTINCT o.order_id)              AS orders_placed,
       SUM(od.quantity * od.price)             AS total_spent
FROM customer c
JOIN orders o         ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id    = od.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY units_purchased DESC, total_spent DESC, c.customer_id
LIMIT 5;

-- Customers with the maximum number of orders
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       COUNT(o.order_id) AS total_orders
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) = (SELECT MAX(order_count)
                            FROM (SELECT COUNT(*) AS order_count
                                  FROM orders
                                  WHERE order_status <> 'Cancelled'
                                  GROUP BY customer_id) AS counts);

-- Customers with the highest spending (top 3)
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       SUM(o.total_amount) AS total_spent
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status <> 'Cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 3;