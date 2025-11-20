-- Q1: Simple query on a single relation
SELECT
    security_id,
    ticker,
    exchange,
    currency
FROM Security
WHERE currency = 'CAD'
  AND exchange = 'TSX'
LIMIT 10;

-- Q2: Aggregate over a join of three tables
SELECT
    u.user_id,
    u.username,
    COUNT(DISTINCT p.portfolio_id) AS num_portfolios,
    COUNT(t.trade_id)              AS num_trades
FROM `User` AS u
LEFT JOIN Portfolio AS p
    ON p.user_id = u.user_id
LEFT JOIN Trade AS t
    ON t.portfolio_id = p.portfolio_id
WHERE u.user_id BETWEEN 1 AND 60   -- keeps the "SELECT-FROM-WHERE" form
GROUP BY
    u.user_id,
    u.username
ORDER BY
    num_trades DESC,
    num_portfolios DESC
LIMIT 20;

-- Q3: Join Position, PriceDaily, Portfolio, Security and compute market value
SELECT
    pos.portfolio_id,
    pf.name           AS portfolio_name,
    pos.security_id,
    s.ticker,
    pos.as_of_date,
    pos.quantity,
    pos.avg_cost,
    pd.close_price,
    pos.quantity * pd.close_price AS market_value
FROM Position AS pos
JOIN PriceDaily AS pd
    ON pd.security_id = pos.security_id
   AND pd.price_date  = pos.as_of_date
JOIN Portfolio AS pf
    ON pf.portfolio_id = pos.portfolio_id
JOIN Security AS s
    ON s.security_id = pos.security_id
WHERE pos.as_of_date >= '2023-01-01'
ORDER BY
    market_value DESC
LIMIT 20;

-- Q4: Correlated subquery to get latest close price per security
SELECT
    s.security_id,
    s.ticker,
    s.exchange,
    SUM(d.amount_per_share) AS total_div_2023,
    MAX(d.ex_date)          AS last_ex_date,
    (
        SELECT pd.close_price
        FROM PriceDaily AS pd
        WHERE pd.security_id = s.security_id
        ORDER BY pd.price_date DESC
        LIMIT 1
    ) AS latest_close_price
FROM Security AS s
JOIN Dividend AS d
    ON d.security_id = s.security_id
WHERE d.ex_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    s.security_id,
    s.ticker,
    s.exchange
HAVING total_div_2023 > 0
ORDER BY
    total_div_2023 DESC
LIMIT 10;

-- Q5: Using EXISTS and NOT EXISTS on correlated subqueries
SELECT
    p.portfolio_id,
    p.name,
    p.base_currency
FROM Portfolio AS p
WHERE EXISTS (
        SELECT 1
        FROM PortfolioNAV AS n
        WHERE n.portfolio_id = p.portfolio_id
          AND n.nav_date BETWEEN '2024-01-01' AND '2024-12-31'
      )
  AND NOT EXISTS (
        SELECT 1
        FROM Import AS i
        WHERE i.portfolio_id = p.portfolio_id
          AND i.status = 'Completed'
      )
ORDER BY
    p.portfolio_id
LIMIT 20;

-- Q6: Aggregate statistics on daily returns per portfolio
SELECT
    pr.portfolio_id,
    p.name AS portfolio_name,
    COUNT(*)              AS num_days,
    AVG(pr.daily_return)  AS avg_daily_return,
    MIN(pr.daily_return)  AS min_daily_return,
    MAX(pr.daily_return)  AS max_daily_return
FROM PortfolioReturn AS pr
JOIN Portfolio AS p
    ON p.portfolio_id = pr.portfolio_id
WHERE pr.date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    pr.portfolio_id,
    p.name
HAVING COUNT(*) >= 5      -- ensure enough data points
ORDER BY
    avg_daily_return DESC
LIMIT 10;

-- Q7: Aggregation with CASE expressions over Import and ImportRow
SELECT
    i.import_id,
    i.filename,
    i.status AS import_status,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN ir.status = 'Processed' THEN 1 ELSE 0 END) AS num_processed,
    SUM(CASE WHEN ir.status = 'Failed'    THEN 1 ELSE 0 END) AS num_failed,
    SUM(CASE WHEN ir.status = 'Pending'   THEN 1 ELSE 0 END) AS num_pending
FROM Import AS i
JOIN ImportRow AS ir
    ON ir.import_id = i.import_id
WHERE i.created_at BETWEEN '2022-01-01' AND '2024-12-31'
GROUP BY
    i.import_id,
    i.filename,
    i.status
HAVING num_failed > 0
ORDER BY
    num_failed DESC,
    total_rows DESC
LIMIT 10;
