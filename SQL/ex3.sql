USE portfolio_app;


INSERT INTO ImportRow (import_id, raw_data, normalized_security_id, status, error_message)
VALUES (
    (
        SELECT i.import_id
        FROM Import AS i
        ORDER BY i.created_at DESC
        LIMIT 1
    ),
    JSON_OBJECT(
        'date',      '2025-01-01',
        'price',     '123.45',
        'quantity',  '10',
        'raw_ticker','STK9999'
    ),
    NULL,                 -- not normalized yet
    'Pending',
    NULL
);

SELECT * FROM ImportRow
ORDER BY import_row_id DESC
LIMIT 5;


INSERT INTO Portfolio (name, user_id, base_currency, creation_date)
SELECT
    CONCAT('Auto Portfolio for ', u.username) AS name,
    u.user_id,
    'USD'                                     AS base_currency,
    NOW()                                     AS creation_date
FROM `User` AS u
JOIN Portfolio AS p
    ON p.user_id = u.user_id
GROUP BY
    u.user_id,
    u.username
ORDER BY
    COUNT(*) DESC
LIMIT 1;

SELECT * FROM Portfolio
ORDER BY portfolio_id DESC
LIMIT 5;


INSERT INTO Dividend (security_id, ex_date, pay_date, amount_per_share, dividend_currency)
SELECT
    pd.security_id,
    '2025-01-16'       AS ex_date,
    '2025-02-01'       AS pay_date,
    1.23450000         AS amount_per_share,
    s.currency         AS dividend_currency
FROM PriceDaily AS pd
JOIN Security  AS s
    ON s.security_id = pd.security_id
ORDER BY
    pd.close_price DESC
LIMIT 1;

SELECT * FROM Dividend
ORDER BY dividend_id DESC
LIMIT 5;