USE portfolio_app;


-- VIEW 1: USD-only trades

DROP VIEW IF EXISTS vw_usd_trades;

CREATE VIEW vw_usd_trades AS
SELECT
    trade_id,
    portfolio_id,
    security_id,
    side,
    quantity,
    price,
    settlement_currency,
    fees,
    trade_time,
    source,
    note
FROM Trade
WHERE settlement_currency = 'USD';

SELECT
    trade_id,
    portfolio_id,
    security_id,
    side,
    quantity,
    price,
    fees,
    trade_time
FROM vw_usd_trades
ORDER BY trade_time DESC
LIMIT 10;


-- View 2: Import statistics per import

DROP VIEW IF EXISTS vw_import_stats;

CREATE VIEW vw_import_stats AS
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
GROUP BY
    i.import_id,
    i.filename,
    i.status;

SELECT
    import_id,
    filename,
    import_status,
    total_rows,
    num_processed,
    num_failed,
    num_pending
FROM vw_import_stats
ORDER BY num_failed DESC, total_rows DESC
LIMIT 10;