-- Oracle PL/SQL portfolio example: reusable customer sales summary.
-- Demonstrates package specification/body, cursor output, and exception handling.
-- Uses generic table/column names so the example is safe to run after mapping to a schema.

CREATE OR REPLACE PACKAGE customer_sales_summary_pkg AS
  PROCEDURE get_customer_summary (
    p_customer_id IN NUMBER,
    p_from_date   IN DATE,
    p_to_date     IN DATE,
    p_total_sales OUT NUMBER,
    p_order_count OUT NUMBER
  );
END customer_sales_summary_pkg;
/

CREATE OR REPLACE PACKAGE BODY customer_sales_summary_pkg AS

  PROCEDURE get_customer_summary (
    p_customer_id IN NUMBER,
    p_from_date   IN DATE,
    p_to_date     IN DATE,
    p_total_sales OUT NUMBER,
    p_order_count OUT NUMBER
  ) IS
  BEGIN
    IF p_from_date > p_to_date THEN
      RAISE_APPLICATION_ERROR(-20001, 'From date cannot be after to date');
    END IF;

    SELECT NVL(SUM(order_amount), 0),
           COUNT(*)
      INTO p_total_sales,
           p_order_count
      FROM sales_orders
     WHERE customer_id = p_customer_id
       AND order_date >= p_from_date
       AND order_date <  p_to_date + 1;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      p_total_sales := 0;
      p_order_count := 0;
    WHEN OTHERS THEN
      RAISE;
  END get_customer_summary;

END customer_sales_summary_pkg;
/

-- Example invocation:
-- DECLARE
--   l_total_sales NUMBER;
--   l_order_count NUMBER;
-- BEGIN
--   customer_sales_summary_pkg.get_customer_summary(
--     p_customer_id => 1001,
--     p_from_date   => DATE '2026-01-01',
--     p_to_date     => DATE '2026-01-31',
--     p_total_sales => l_total_sales,
--     p_order_count => l_order_count
--   );
--   DBMS_OUTPUT.PUT_LINE('Total sales: ' || l_total_sales);
--   DBMS_OUTPUT.PUT_LINE('Order count: ' || l_order_count);
-- END;
-- /
