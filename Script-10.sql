#Data_Exploration


# Daataset_preview
SELECT *
FROM stock_prices;

# Basic_table_exploration
SELECT COUNT(*)
FROM stock_prices;

# timeline_and_stocks_check
SELECT EXTRACT (YEAR FROM date) AS Year, COUNT(DISTINCT(symbol))
FROM stock_prices 
GROUP BY Year;

# Volume_check_by_day
SELECT date, SUM(volume) AS sum
FROM stock_prices 
GROUP BY date
ORDER BY date DESC
LIMIT 10;

# Volume_check_by_year
SELECT EXTRACT(YEAR FROM date) AS year, SUM(volume) AS sum
FROM stock_prices 
GROUP BY year
ORDER BY sum DESC
LIMIT 10;

# Openint_check
SELECT sum(openint) AS sum
FROM stock_prices 


# Data_Quality_Audit_&_Integrity


# Logical_test
SELECT * FROM stock_prices 
WHERE low > high 
   OR open <= 0 
   OR close <= 0
ORDER BY date;

# Stagnation_Test
SELECT count(*) 
FROM stock_prices 
WHERE low = high;

# Null_Test
SELECT COUNT(*) 
FROM stock_prices 
WHERE num_nulls(low, high, close, open, date, symbol, openint, volume) > 0;

# Duplicates_Test
SELECT COUNT(*) 
FROM stock_prices 
GROUP BY symbol, date 
HAVING COUNT(*) > 1


# Business Analytics


# Average_by_year
SELECT 
    EXTRACT(YEAR FROM date) AS Year,
    round(avg(open),2) AS open, 
    round(avg(high),2) AS high, 
    round(avg(low),2) AS low, 
    round(avg(close),2) AS close, 
    round(avg(volume),2) AS volume
FROM (
     SELECT *
     FROM stock_prices
     WHERE 
         low <= high AND
         open > 0 AND
         close > 0
     )
GROUP BY Year




# Daily_return
SELECT 
    date,
    open,
    close,
    LAG(close) OVER (ORDER BY date) AS previous_close,
    round(
        ((close - LAG(close) OVER (ORDER BY date)) / 
        LAG(close) OVER (ORDER BY date)) * 100,2) 
    AS daily_return
    
FROM stock_prices
WHERE symbol = 'aapl'
ORDER BY date DESC
LIMIT 100;


# Bullish_days_vs_Bearish_days
WITH base AS (
    SELECT DISTINCT EXTRACT(YEAR FROM date) AS year
    FROM stock_prices
),
bull AS (
    SELECT CAST(EXTRACT(YEAR FROM date) AS INT) AS year, 
           COUNT(*) AS bullish_days
    FROM stock_prices
    WHERE close > open * 1.1 
      AND low > 0.95 * open 
      AND high < 1.05 * close 
      AND open <> 0
    GROUP BY EXTRACT(YEAR FROM date)
),
bear AS (
    SELECT CAST(EXTRACT(YEAR FROM date) AS INT) AS year, 
           COUNT(*) AS bearish_days
    FROM stock_prices
    WHERE close < open * 0.9 
      AND high < 1.05 * open 
      AND low > 0.95 * close 
      AND open <> 0
    GROUP BY EXTRACT(YEAR FROM date)
),
combined AS (
    SELECT b.year,
           COALESCE(bl.bullish_days, 0) AS bullish_days,
           COALESCE(br.bearish_days, 0) AS bearish_days,
           COALESCE(bl.bullish_days, 0) + COALESCE(br.bearish_days, 0) AS Sum
    FROM base b
    LEFT JOIN bull bl ON b.year = bl.year
    LEFT JOIN bear br ON b.year = br.year
)
SELECT 
    year,
    bullish_days,
    bearish_days,
    Sum,
    CASE 
        WHEN bullish_days = 0 AND bearish_days = 0 THEN 'tie'
        WHEN bullish_days > bearish_days THEN 'bulls'
        WHEN bullish_days < bearish_days THEN 'bears'
        ELSE 'tie'
    END AS who_wins,
    CASE
    WHEN bullish_days = 0 AND bearish_days = 0 THEN 0
    WHEN bullish_days = 0 AND bearish_days > 0 THEN ROUND(CAST(bearish_days AS numeric) * 100, 2)
    WHEN bearish_days = 0 AND bullish_days > 0 THEN ROUND(CAST(bullish_days AS numeric) * 100, 2)
    WHEN bullish_days > bearish_days THEN ROUND((CAST(bullish_days AS numeric) / bearish_days)*100 - 100, 2)
    WHEN bullish_days < bearish_days THEN ROUND((CAST(bearish_days AS numeric) / bullish_days)*100 - 100, 2)
    ELSE 0
END AS percentage

FROM combined
ORDER BY Sum DESC;



# SMA_50_and_SMA_200
SELECT 
    symbol,
    date,
    close,

    round(AVG(close) OVER (
        PARTITION BY symbol 
        ORDER BY date 
        ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
    ),2) AS sma_50,
   
    round(AVG(close) OVER (
        PARTITION BY symbol 
        ORDER BY date 
        ROWS BETWEEN 199 PRECEDING AND CURRENT ROW
    ),2) AS sma_200
    
FROM stock_prices
WHERE symbol = 'aapl'
ORDER BY date DESC;




# Volatility_Analysis
WITH daily_stats AS (
    SELECT 
        symbol,
        date,
 
        ((close - LAG(close) OVER (PARTITION BY symbol ORDER BY date)) / 
        NULLIF(LAG(close) OVER (PARTITION BY symbol ORDER BY date), 0)) * 100 AS daily_return
    FROM stock_prices
    WHERE symbol = 'aapl'
)

SELECT 
    symbol,
    date,
    round(daily_return, 2) AS daily_return,
  
    round(
        STDDEV(daily_return) OVER (
            PARTITION BY symbol 
            ORDER BY date 
            ROWS BETWEEN 20 PRECEDING AND CURRENT ROW
        ), 2) AS monthly_volatility
FROM daily_stats
ORDER BY date DESC
LIMIT 100;




# Liquidity_ranking
WITH tab AS (
    SELECT 
        symbol,
        ROUND(AVG(volume),2) AS average_volume
    FROM stock_prices
    WHERE EXTRACT(YEAR FROM date) = '2017'
    GROUP BY symbol
    )

SELECT 
    symbol,
    average_volume,
    NTILE(4) OVER (ORDER BY average_volume DESC) as liquidity_rank
FROM tab;




# Optimization
EXPLAIN ANALYZE 
SELECT * FROM stock_prices 
WHERE symbol = 'AAPL' AND date = '2016-01-04';

CREATE INDEX index_symbol_date ON stock_prices(symbol, date);



