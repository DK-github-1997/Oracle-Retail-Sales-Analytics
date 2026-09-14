-- Monthly revenue and month-over-month growth pattern for Oracle 19c.
-- Replace retail_sales.sale_date and retail_sales.amount with the actual
-- transaction columns when integrating this sample into a physical schema.

WITH monthly_revenue AS (
    SELECT
        TRUNC(sale_date, 'MM') AS sales_month,
        SUM(amount) AS revenue
    FROM retail_sales
    GROUP BY TRUNC(sale_date, 'MM')
),
revenue_with_prior_month AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (ORDER BY sales_month) AS prior_month_revenue
    FROM monthly_revenue
)
SELECT
    sales_month,
    revenue,
    prior_month_revenue,
    revenue - prior_month_revenue AS revenue_change,
    ROUND(
        100 * (revenue - prior_month_revenue)
        / NULLIF(prior_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM revenue_with_prior_month
ORDER BY sales_month;
