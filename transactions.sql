SELECT current_setting('transaction_isolation');
BEGIN;
WITH new_order AS (
    INSERT INTO sql_store.orders (customer_id, order_date, status)
    VALUES (1, '2019-01-01', 1)
    RETURNING order_id
) -- Disconnect from server to test transaction rollback
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
-- ROLLBACK; -- Manual rollback
COMMIT;
--

-- Lost Update Problem
update sql_store.customers c
set points = 100
where c.customer_id = 1;
-- Step 1: Connection 1 reads points
BEGIN;
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- Returns: 100
-- Application calculates new point (100 + 10 = 110)
-- Time passes...
-- Step 2: Connection 2 reads the same point
BEGIN;
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- Returns: 100
-- Application calculates new point (100 + 20 = 120)
-- Step 3: Connection 1 updates the point (adding 100)
UPDATE sql_store.customers c
SET points = 110
WHERE c.customer_id = 1;
-- Step 4: Connection 2 overwrites Connection 1's update
UPDATE sql_store.customers c
SET points = 120
WHERE c.customer_id = 1;
-- Step 5: Connection 1 commits
COMMIT;
-- Step 6: Connection 2 commits
COMMIT;
--
SELECT points FROM sql_store.customers c WHERE c.customer_id = 1;
-- Returns: 120
-- Solutions:
-- 1. Calculate points at database level: SET points = points + 20
-- 2. Use SELECT FOR UPDATE to lock rows
-- 3. Use REPEATABLE READ or SERIALIZABLE isolation
-- 
--
-- Testing with REPEATABLE READ
update sql_store.customers c
set points = 100
where c.customer_id = 1;
-- Step 1: Connection 1 reads points
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- Returns: 100
-- Calculate new points (100 + 10 = 110)
-- Step 2: Connection 2 reads points
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- Returns: 100
-- Calculate new points (100 + 20 = 120)
-- Step 3: Connection 1 updates points
UPDATE sql_store.customers c
SET points = 110
WHERE c.customer_id = 1;
-- Waits for Connection 1 to commit/rollback
-- On commit: Throws serialization error
-- On rollback: Updates row
UPDATE sql_store.customers c
SET points = 120
WHERE c.customer_id = 1;
-- Step 5: Connection 1 commits
COMMIT;
-- Step 6: Connection 2 commits
COMMIT;
--
SELECT points FROM sql_store.customers c WHERE c.customer_id = 1;
-- 
-- 
-- Non-repeatable Reads Demo:
update sql_store.customers c
set points = 100
where c.customer_id = 1;
-- Step 1: Connection 1 reads points
BEGIN;
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- Step 2: Connection 2 updates points
BEGIN;
UPDATE sql_store.customers c
SET points = 110
WHERE c.customer_id = 1;
COMMIT;
-- Step 3: Connection 1 reads different value
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
COMMIT;
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- 
-- Solving with REPEATABLE READ:
update sql_store.customers c
set points = 100
where c.customer_id = 1;
-- Step 1: Connection 1 reads points
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- Step 2: Connection 2 updates points
BEGIN;
UPDATE sql_store.customers c
SET points = 110
WHERE c.customer_id = 1;
COMMIT;
-- Step 3: Connection 1 still sees original value
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
COMMIT;
--
--
SELECT points
FROM sql_store.customers c
WHERE c.customer_id = 1;
-- REPEATABLE READ solves this issue but introduces phantom reads
-- Use SERIALIZABLE isolation level to prevent phantom reads

-- Dead locks
-- Step 1: 1st connection
begin;
update sql_store.customers set state = 'VA' where customer_id = 1;
-- Step 2: 2nd connection
begin;
update sql_store.orders set status = 1 where order_id = 1;
-- Step 3: 1st connection
update sql_store.orders set status = 1 where order_id = 1;
-- Step 4: 2nd connection
update sql_store.customers set state = 'VA' where customer_id = 1;

-- Deadlocks are rare but should still be handled properly
-- If deadlocks occur frequently between two transactions, review their code and consider reordering the update statements
-- Write application code to automatically retry transactions that get rolled back due to deadlocks
-- Keep transactions small and short in duration
-- For long-running transactions, consider scheduling them during off-peak hours
-- Provide appropriate error handling and user feedback when transactions fail