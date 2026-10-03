-- Question 1- Which products experienced significant month-over-month 
-- changes in demand, and which regions contributed the most to those changes?
WITH monthly_demand AS(
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        product_id,region,
        SUM(units_sold) AS total_demand
    FROM retail_inventory
    GROUP BY DATE_FORMAT(date, '%Y-%m'),product_id,region
),
previous_month AS(
    SELECT *,
        LAG(total_demand) OVER(
            PARTITION BY product_id, region
            ORDER BY month) AS previous_month_demand
    FROM monthly_demand
)
SELECT
    month,product_id,region,total_demand,previous_month_demand,
    ROUND(
        ((total_demand - previous_month_demand) * 100.0)
        / previous_month_demand,
        2) AS demand_change_pct
FROM previous_month
WHERE previous_month_demand IS NOT NULL
ORDER BY ABS(demand_change_pct) DESC, month asc;

-- Question 2- Which products have consistently recorded poor forecast accuracy over the
--  last 3 months, rather than experiencing only a one-time forecasting error

WITH monthly_accuracy AS
(
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        product_id,
        SUM(units_sold) AS actual_demand,
        Round(SUM(demand_forecast),3) AS forecast_demand,
        ROUND(
            (1 -
                SUM(ABS(demand_forecast - units_sold))
                / SUM(units_sold)
            ) * 100,2) AS forecast_accuracy
    FROM retail_inventory
    GROUP BY DATE_FORMAT(date, '%Y-%m'),product_id
 ),
 last_3_months AS(
    SELECT*,
        ROW_NUMBER() OVER(
            PARTITION BY product_id
            ORDER BY month DESC
        ) AS month_no
FROM monthly_accuracy
)
SELECT
    month,product_id,actual_demand,forecast_demand,forecast_accuracy
FROM last_3_months
WHERE month_no <= 3
ORDER BY product_id,month DESC;

-- Question 3- Which products are consistently being over-forecasted or 
-- under-forecasted, and what is the magnitude of their forecast bias?
WITH monthly_bias AS
(
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        product_id,
        SUM(units_sold) AS actual_demand,
        Round(SUM(demand_forecast),2) AS forecast_demand,
        ROUND(
            SUM(demand_forecast) - SUM(units_sold),2) AS forecast_bias
    FROM retail_inventory
    GROUP BY DATE_FORMAT(date, '%Y-%m'),product_id
)
SELECT
    month,product_id,actual_demand,forecast_demand,forecast_bias,
    CASE
        WHEN forecast_bias > 0 THEN 'Over Forecast'
        WHEN forecast_bias < 0 THEN 'Under Forecast'
        ELSE 'Accurate'
    END AS bias_type
FROM monthly_bias
ORDER BY ABS(forecast_bias) DESC;

Question 4- 
