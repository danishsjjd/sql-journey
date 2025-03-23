BEGIN;
WITH new_order AS (
    INSERT INTO sql_store.orders (customer_id, order_date, status)
    VALUES (1, '2019-01-01', 1)
    RETURNING order_id
)
-- try disconnect from server it should never insert the order
INSERT INTO sql_store.order_items
VALUES (
        (
            SELECT order_id
            FROM new_order
        ),
        1,
        1,
        1
    );
-- ROLLBACK; -- to manually rollback changes
COMMIT;
--

-- Execute line-by-line in both connections
BEGIN;
UPDATE sql_store.customers c
SET points = points + 10
WHERE customer_id = 1;
COMMIT;

SELECT * from sql_store.customers
where customer_id = 1;

