USE amex_customer_analytics;

SELECT COUNT(*) AS total_rows
FROM credit_card_transactions;

Select top 5 *
FROM credit_card_transactions;

Alter table credit_card_transactions
DROP COLUMN Unnamed_0;

/*Customer Dimension Table*/

SELECT DISTINCT
    cc_num,
    first       AS first_name,
    last        AS last_name,
    gender,
    dob,
    job,
    city,
    state,
    city_pop
INTO customers
FROM credit_card_transactions;

/*Transaction FAct Table*/

SELECT
    trans_num,
    CAST(trans_date_trans_time AS DATETIME) AS transaction_datetime,
    cc_num,
    amt        AS amount,
    category,
    merchant,
    lat,
    long,
    merch_lat,
    merch_long
INTO transactions
FROM credit_card_transactions;

/*Primary Key*/

ALTER TABLE customers
ADD CONSTRAINT pk_customers PRIMARY KEY (cc_num);

ALTER TABLE transactions
ADD CONSTRAINT pk_transactions PRIMARY KEY (trans_num);

/* Foreign Key*/

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_customers
FOREIGN KEY (cc_num)
REFERENCES customers (cc_num);

/*Model Check*/

SELECT 
    t.trans_num,
    t.amount,
    t.category,
    c.first_name,
    c.state
FROM transactions t
JOIN customers c
    ON t.cc_num = c.cc_num;

/*Baseline Metrics (Basic Analysis)*/
/*How big is dataset?*/

SELECT 
    COUNT(*)        AS total_transactions,
    COUNT(DISTINCT cc_num) AS total_customers,
    SUM(amount)     AS total_spend,
    AVG(amount)     AS avg_transaction_value
FROM transactions;

/*How much does an average customer spend?*/

SELECT 
    AVG(customer_spend) AS avg_spend_per_customer
FROM (
    SELECT 
        cc_num,
        SUM(amount) AS customer_spend
    FROM transactions
    GROUP BY cc_num
) t;

/*Who are our most valuable customers?*/

SELECT TOP 10
    c.cc_num,
    c.first_name,
    c.last_name,
    SUM(t.amount) AS total_spent
FROM transactions t
JOIN customers c
    ON t.cc_num = c.cc_num
GROUP BY 
    c.cc_num, c.first_name, c.last_name
ORDER BY total_spent DESC;

/*How often do customers transact? (Transaction Frequenct per Customer)*/

SELECT 
    cc_num,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY cc_num
ORDER BY transaction_count DESC;

/*Where are customers spending money?*/

SELECT 
    category,
    SUM(amount) AS total_spend,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY category
ORDER BY total_spend DESC;

/*Average Transaction Value by Category*/

SELECT 
    category,
    AVG(amount) AS avg_transaction_value
FROM transactions
GROUP BY category
ORDER BY avg_transaction_value DESC;

/*Is customer spending increasing or declining over time? (Transactions Over Time (Monthly Trend))*/

SELECT 
    YEAR(transaction_datetime)  AS year,
    MONTH(transaction_datetime) AS month,
    COUNT(*)                    AS total_transactions,
    SUM(amount)                 AS total_spend
FROM transactions
GROUP BY 
    YEAR(transaction_datetime),
    MONTH(transaction_datetime)
ORDER BY year, month;

/*How long do customers stay active?(First vs Last Transaction Date (Engagement Window))*/

SELECT 
    cc_num,
    MIN(transaction_datetime) AS first_transaction,
    MAX(transaction_datetime) AS last_transaction,
    DATEDIFF(day, 
        MIN(transaction_datetime), 
        MAX(transaction_datetime)
    ) AS active_days
FROM transactions
GROUP BY cc_num
ORDER BY active_days DESC;

/*Which customers have stopped transacting recently?(Identify Inactive Customers (Early Churn Signal))*/
/*Assuming "inactive" as no transactions in last 90 days)*/

SELECT 
    cc_num,
    MAX(transaction_datetime) AS last_transaction
FROM transactions
GROUP BY cc_num
HAVING MAX(transaction_datetime) < DATEADD(day, -90, GETDATE());

/* How many customers are repeat users? (Repeat vs One-Time Customers)*/

SELECT 
    customer_type,
    COUNT(*) AS customer_count
FROM (
    SELECT 
        cc_num,
        CASE 
            WHEN COUNT(*) = 1 THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type
    FROM transactions
    GROUP BY cc_num
) t
GROUP BY customer_type;

/*Average Days Between Transactions (Engagement Frequency)*/

SELECT
    cc_num,
    AVG(days_between_transactions) AS avg_days_between_transactions
FROM (
    SELECT
        cc_num,
        DATEDIFF(
            day,
            LAG(transaction_datetime) OVER (
                PARTITION BY cc_num
                ORDER BY transaction_datetime
            ),
            transaction_datetime
        ) AS days_between_transactions
    FROM transactions
) t
WHERE days_between_transactions IS NOT NULL
GROUP BY cc_num;

/* Which categories drive repeat engagement? Retention by Category (Behavioral Insight)*/

SELECT 
    category,
    COUNT(DISTINCT cc_num) AS active_customers,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY category
ORDER BY active_customers DESC;


/*How much revenue has each customer generated? Customer Lifetime Value (CLV – Spend Based)*/

SELECT 
    cc_num,
    SUM(amount)   AS total_spend,
    COUNT(*)      AS total_transactions,
    AVG(amount)   AS avg_transaction_value
FROM transactions
GROUP BY cc_num
ORDER BY total_spend desc,
		 total_transactions desc;

/*Label Customers*/

SELECT
    cc_num,
    total_spend,
    CASE 
        WHEN value_tier = 1 THEN 'High Value'
        WHEN value_tier = 2 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM (
    SELECT
        cc_num,
        total_spend,
        NTILE(3) OVER (ORDER BY total_spend DESC) AS value_tier
    FROM (
        SELECT 
            cc_num,
            SUM(amount) AS total_spend
        FROM transactions
        GROUP BY cc_num
    ) s
) t;

/*Value Segmentation Using NTILE*/

SELECT
    cc_num,
    total_spend,
    value_tier,
    CASE 
        WHEN value_tier = 1 THEN 'High Value'
        WHEN value_tier = 2 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM (
    SELECT
        cc_num,
        SUM(amount) AS total_spend,
        NTILE(3) OVER (ORDER BY SUM(amount) DESC) AS value_tier
    FROM transactions
    GROUP BY cc_num
) t
ORDER BY 
    value_tier ASC, 
    total_spend DESC;

/* Who contributes the most revenue? Segment Size & Revenue Contribution*/

SELECT
    customer_segment,
    COUNT(*)       AS customer_count,
    SUM(total_spend) AS segment_revenue
FROM (
    SELECT
        cc_num,
        total_spend,
        CASE 
            WHEN NTILE(3) OVER (ORDER BY total_spend DESC) = 1 THEN 'High Value'
            WHEN NTILE(3) OVER (ORDER BY total_spend DESC) = 2 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM (
        SELECT 
            cc_num,
            SUM(amount) AS total_spend
        FROM transactions
        GROUP BY cc_num
    ) s
) t
GROUP BY customer_segment;

/*Which high-value customers are becoming inactive? High-Value Customers at Churn Risk*/
--High value with no transaction in last 60 days

SELECT 
    hv.cc_num,
    hv.total_spend,
    COUNT(t.trans_num) AS total_transactions,
    MAX(t.transaction_datetime) AS last_transaction
FROM (
    SELECT
        cc_num,
        SUM(amount) AS total_spend
    FROM transactions
    GROUP BY cc_num
) hv
JOIN transactions t 
    ON hv.cc_num = t.cc_num
GROUP BY 
    hv.cc_num, 
    hv.total_spend
HAVING 
    MAX(t.transaction_datetime) < DATEADD(day, -60, GETDATE())
ORDER BY hv.total_spend DESC;

/*Count of high churn risk customers.*/

SELECT 
    COUNT(*) AS high_churn_risk_customers
FROM (
    SELECT 
        hv.cc_num
    FROM (
        SELECT
            cc_num,
            SUM(amount) AS total_spend
        FROM transactions
        GROUP BY cc_num
    ) hv
    JOIN transactions t 
        ON hv.cc_num = t.cc_num
    GROUP BY hv.cc_num, hv.total_spend
    HAVING 
        MAX(t.transaction_datetime) < DATEADD(day, -60, GETDATE())
) churn_customers;



-- Purpose: Calculate overall fraud rate to understand baseline fraud prevalence

SELECT
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    CAST(SUM(is_fraud) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS fraud_rate_percentage
FROM credit_card_transactions;

-- Purpose: Compare transaction count and transaction value between fraud and non-fraud cases

SELECT
    t.is_fraud,
    COUNT(*) AS transaction_count,
    AVG(t.amt) AS avg_transaction_amount,
    MAX(t.amt) AS max_transaction_amount
FROM dbo.credit_card_transactions AS t
GROUP BY t.is_fraud;

-- Purpose: Identify fraud concentration across transaction amount ranges

SELECT
    CASE 
        WHEN amt < 100 THEN '< 100'
        WHEN amt BETWEEN 100 AND 500 THEN '100–500'
        WHEN amt BETWEEN 500 AND 1000 THEN '500–1000'
        ELSE '> 1000'
    END AS amount_bucket,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions
FROM dbo.credit_card_transactions
GROUP BY 
    CASE 
        WHEN amt < 100 THEN '< 100'
        WHEN amt BETWEEN 100 AND 500 THEN '100–500'
        WHEN amt BETWEEN 500 AND 1000 THEN '500–1000'
        ELSE '> 1000'
    END
ORDER BY fraud_transactions DESC;

-- Purpose: Identify merchant categories with elevated fraud risk

SELECT
    t.category,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    CAST(
        SUM(t.is_fraud) * 100.0 / COUNT(*) 
        AS DECIMAL(5,2)
    ) AS fraud_rate_percentage
FROM dbo.credit_card_transactions AS t
GROUP BY t.category
HAVING COUNT(*) > 500
ORDER BY fraud_rate_percentage DESC;

-- Purpose: Identify high-risk states based on fraud rate

SELECT
    t.state,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    CAST(
        SUM(t.is_fraud) * 100.0 / COUNT(*) 
        AS DECIMAL(5,2)
    ) AS fraud_rate_percentage
FROM dbo.credit_card_transactions AS t
GROUP BY t.state
HAVING COUNT(*) > 1000
--ORDER BY fraud_rate_percentage DESC	
ORDER BY fraud_transactions DESC;

-- Purpose: Identify fraud patterns by hour of day

SELECT
    DATEPART(HOUR, t.trans_date_trans_time) AS transaction_hour,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    CAST(
        SUM(t.is_fraud) * 100.0 / COUNT(*) 
        AS DECIMAL(5,2)
    ) AS fraud_rate_percentage
FROM dbo.credit_card_transactions AS t
GROUP BY DATEPART(HOUR, t.trans_date_trans_time)
ORDER BY fraud_rate_percentage DESC;

-- Purpose: Identify fraud patterns by day of week

SELECT
    DATENAME(WEEKDAY, t.trans_date_trans_time) AS day_of_week,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    CAST(
        SUM(t.is_fraud) * 100.0 / COUNT(*) 
        AS DECIMAL(5,2)
    ) AS fraud_rate_percentage
FROM dbo.credit_card_transactions AS t
GROUP BY DATENAME(WEEKDAY, t.trans_date_trans_time)
ORDER BY fraud_rate_percentage DESC;




-- Purpose: Build customer-level transaction and fraud summary

SELECT
    t.cc_num,
    COUNT(*) AS total_transactions,
    SUM(t.is_fraud) AS fraud_transactions,
    SUM(t.amt) AS total_amount_spent,
    SUM(CASE WHEN t.is_fraud = 1 THEN t.amt ELSE 0 END) AS fraud_amount,
    AVG(t.amt) AS avg_transaction_amount
FROM dbo.credit_card_transactions AS t
GROUP BY t.cc_num;

-- Purpose: Calculate customer-level fraud risk score

WITH customer_summary AS (
    SELECT
        t.cc_num,
        COUNT(*) AS total_transactions,
        SUM(t.is_fraud) AS fraud_transactions,
        SUM(t.amt) AS total_amount_spent,
        SUM(CASE WHEN t.is_fraud = 1 THEN t.amt ELSE 0 END) AS fraud_amount
    FROM dbo.credit_card_transactions AS t
    GROUP BY t.cc_num
)
SELECT
    cs.cc_num,
    cs.total_transactions,
    cs.fraud_transactions,
    cs.total_amount_spent,
    cs.fraud_amount,

    -- Fraud frequency rate
    CAST(
        cs.fraud_transactions * 1.0 / cs.total_transactions
        AS DECIMAL(6,4)
    ) AS fraud_frequency_rate,

    -- Fraud exposure ratio
    CAST(
        CASE 
            WHEN cs.total_amount_spent = 0 THEN 0
            ELSE cs.fraud_amount * 1.0 / cs.total_amount_spent
        END
        AS DECIMAL(6,4)
    ) AS fraud_amount_ratio,

    -- Composite fraud risk score
    CAST(
        (
            (cs.fraud_transactions * 1.0 / cs.total_transactions) * 0.6 +
            (CASE 
                WHEN cs.total_amount_spent = 0 THEN 0
                ELSE cs.fraud_amount * 1.0 / cs.total_amount_spent
             END) * 0.4
        )
        AS DECIMAL(6,4)
    ) AS fraud_risk_score
FROM customer_summary AS cs;

-- Purpose: Segment customers into fraud risk categories

WITH risk_scores AS (
    SELECT
        t.cc_num,
        COUNT(*) AS total_transactions,
        SUM(t.is_fraud) AS fraud_transactions,
        SUM(t.amt) AS total_amount_spent,
        SUM(CASE WHEN t.is_fraud = 1 THEN t.amt ELSE 0 END) AS fraud_amount,

        (
            (SUM(t.is_fraud) * 1.0 / COUNT(*)) * 0.6 +
            (CASE 
                WHEN SUM(t.amt) = 0 THEN 0
                ELSE SUM(CASE WHEN t.is_fraud = 1 THEN t.amt ELSE 0 END) * 1.0 / SUM(t.amt)
             END) * 0.4
        ) AS fraud_risk_score
    FROM dbo.credit_card_transactions AS t
    GROUP BY t.cc_num
),
ranked_customers AS (
    SELECT
        *,
        NTILE(3) OVER (ORDER BY fraud_risk_score DESC) AS risk_bucket
    FROM risk_scores
)
SELECT
    cc_num,
    total_transactions,
    fraud_transactions,
    total_amount_spent,
    fraud_amount,
    CAST(fraud_risk_score AS DECIMAL(6,4)) AS fraud_risk_score,
    CASE 
        WHEN risk_bucket = 1 THEN 'High Risk'
        WHEN risk_bucket = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM ranked_customers
ORDER BY fraud_risk_score DESC;


--For PowerBI Ignore.

--Fraud Summary (Executive KPIs)

CREATE VIEW vw_fraud_overview AS
SELECT
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    SUM(is_fraud) * 100.0 / COUNT(*) AS fraud_rate_percentage,
    SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END) AS total_fraud_amount,
    AVG(CASE WHEN is_fraud = 1 THEN amt END) AS avg_fraud_amount
FROM dbo.credit_card_transactions;

--Fraud Patterns

CREATE VIEW vw_fraud_patterns AS
SELECT
    category,
    state,
    DATEPART(HOUR, trans_date_trans_time) AS transaction_hour,
    DATENAME(WEEKDAY, trans_date_trans_time) AS transaction_day,
    is_fraud,
    amt
FROM dbo.credit_card_transactions;

--Customer Fraud Risk

CREATE VIEW vw_customer_fraud_risk AS
WITH risk_scores AS (
    SELECT
        cc_num,
        COUNT(*) AS total_transactions,
        SUM(is_fraud) AS fraud_transactions,
        SUM(amt) AS total_amount_spent,
        SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END) AS fraud_amount,
        (
            (SUM(is_fraud) * 1.0 / COUNT(*)) * 0.6 +
            (SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END) * 1.0 / SUM(amt)) * 0.4
        ) AS fraud_risk_score
    FROM dbo.credit_card_transactions
    GROUP BY cc_num
)
SELECT
    *,
    CASE 
        WHEN NTILE(3) OVER (ORDER BY fraud_risk_score DESC) = 1 THEN 'High Risk'
        WHEN NTILE(3) OVER (ORDER BY fraud_risk_score DESC) = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM risk_scores;

