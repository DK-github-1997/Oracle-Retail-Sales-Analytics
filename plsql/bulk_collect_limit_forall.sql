-- Oracle PL/SQL portfolio example: BULK COLLECT LIMIT + FORALL SAVE EXCEPTIONS.
-- Business use case: mark eligible pending orders as READY in bounded batches.
-- Map the example table/columns to your schema before execution.
-- This procedure intentionally does not COMMIT; transaction ownership stays with caller.

CREATE OR REPLACE PROCEDURE mark_pending_orders_ready AS
  CURSOR c_pending_orders IS
    SELECT order_id
      FROM sales_orders
     WHERE processing_status = 'PENDING'
     ORDER BY order_id;

  TYPE t_order_ids IS TABLE OF sales_orders.order_id%TYPE;
  l_order_ids   t_order_ids;
  c_batch_size  CONSTANT PLS_INTEGER := 500;

  e_bulk_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_dml_errors, -24381);
BEGIN
  OPEN c_pending_orders;

  LOOP
    FETCH c_pending_orders
      BULK COLLECT INTO l_order_ids
      LIMIT c_batch_size;

    EXIT WHEN l_order_ids.COUNT = 0;

    BEGIN
      FORALL i IN 1 .. l_order_ids.COUNT SAVE EXCEPTIONS
        UPDATE sales_orders
           SET processing_status = 'READY'
         WHERE order_id = l_order_ids(i)
           AND processing_status = 'PENDING';

    EXCEPTION
      WHEN e_bulk_dml_errors THEN
        -- Successful iterations in this batch are retained; failed iterations
        -- are reported individually. Replace DBMS_OUTPUT with approved logging
        -- if this pattern is used in a production job.
        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
          DBMS_OUTPUT.PUT_LINE(
            'Order ID ' ||
            l_order_ids(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX) ||
            ' failed with Oracle error ' ||
            SQL%BULK_EXCEPTIONS(i).ERROR_CODE
          );
        END LOOP;
    END;
  END LOOP;

  CLOSE c_pending_orders;
EXCEPTION
  WHEN OTHERS THEN
    IF c_pending_orders%ISOPEN THEN
      CLOSE c_pending_orders;
    END IF;
    RAISE;
END mark_pending_orders_ready;
/

-- Operational notes:
-- 1. BULK COLLECT LIMIT bounds collection memory for large result sets.
-- 2. FORALL reduces PL/SQL-to-SQL context switching for batch DML.
-- 3. SAVE EXCEPTIONS allows remaining DML iterations to run when some fail.
-- 4. Review retry/idempotency, concurrent workers, locking, and transaction
--    boundaries before adapting this sample to a production workload.
