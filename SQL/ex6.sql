USE portfolio_app;

/* COMMAND 1 */
UPDATE importrow AS ir
JOIN import AS i
  ON ir.import_id = i.import_id
SET ir.status        = 'Failed',
    ir.error_message = 'Auto-fail: parent import not completed'
WHERE i.status <> 'Completed';



/* COMMAND 2 */
UPDATE trade AS t
SET t.fees = ROUND(
              CASE
                WHEN t.source = 'Manual' THEN t.fees * 0.90   -- 10% discount
                ELSE                      t.fees * 1.05       -- 5% markup for API trades
              END,
              2
            )
WHERE t.trade_time >= '2024-01-01';
  
/* COMMAND 3 */
SET SQL_SAFE_UPDATES = 0;

DELETE FROM portfolionav
WHERE nav_date >= '2022-01-01'
  AND nav_date <  '2023-01-01'
  AND portfolio_id <= 10;

SET SQL_SAFE_UPDATES = 1;
