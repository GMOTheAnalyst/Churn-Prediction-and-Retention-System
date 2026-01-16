   Metrics & Feature Engineering Layer
   Customer Churn & Retention Intelligence System
   ==================================================

	1.
 	#Last Purchase Date per Customer------------ */

This metric drives churn logic.

->	Latest order date

->	Days since last purchase

Once this exists, churn becomes trivial to classify.


CREATE OR REPLACE VIEW vw_last_purchase AS
SELECT
    c.customer_id,
    c.full_name,
    MAX(o.order_date) AS last_purchase_date
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name;

	#Days Since Last Purchase 

CREATE OR REPLACE VIEW vw_days_since_last_purchase AS
SELECT
    customer_id,
    full_name,
    last_purchase_date,
    DATEDIFF(CURRENT_DATE, last_purchase_date) AS days_since_last_purchase
FROM vw_last_purchase;


	2. Customer Lifetime Revenue (LTV) --------------- */
This answers who matters most financially.
	->	Total revenue per customer
	->	Number of purchases
	->	Average order value
Without this, “high value” is just a guess.

SELECT
    c.customer_id,
    c.full_name,
    COUNT(p.payment_id) AS total_purchases,
    SUM(p.payment_amount) AS lifetime_value,
    AVG(p.payment_amount) AS avg_order_value
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
LEFT JOIN payments p
    ON o.order_id = p.order_id
    AND p.payment_status = 'successful'
GROUP BY c.customer_id, c.full_name;


	3. Monthly Customer Activity --------- */

	-> Active customers per month

SELECT
    customer_id,
    DATE_FORMAT(order_date, '%Y-%m') AS activity_month,
    COUNT(order_id) AS orders_in_month,
    SUM(order_amount) AS revenue_in_month
FROM orders
WHERE order_status = 'completed'
GROUP BY customer_id, DATE_FORMAT(order_date, '%Y-%m');


	->Customer First and Last Activity Month

SELECT
    customer_id,
    MIN(DATE_FORMAT(order_date, '%Y-%m')) AS first_active_month,
    MAX(DATE_FORMAT(order_date, '%Y-%m')) AS last_active_month
FROM orders
WHERE order_status = 'completed'
GROUP BY customer_id;


	4. Unified Customer Metrics View --------------- */

SELECT
    c.customer_id,
    c.full_name,
    c.signup_date,
    lp.last_purchase_date,
    dslp.days_since_last_purchase,
    ltv.total_purchases,
    ltv.lifetime_value,
    ltv.avg_order_value
FROM customers c
LEFT J OIN vw_last_purchase lp
    ON c.customer_id = lp.customer_id
LEFT JOIN vw_days_since_last_purchase dslp
    ON c.customer_id = dslp.customer_id
LEFT JOIN vw_customer_ltv ltv
    ON c.customer_id = ltv.customer_id;


====== Conceptually we statements sort achieve: =======

This layer converts raw data into decision ready signals.

	When did this customer last buy

	How long have they been inactive

	How much revenue have they generated

	How active are they month by month

