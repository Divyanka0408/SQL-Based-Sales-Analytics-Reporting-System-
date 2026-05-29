USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'D:\Advanced Data Analytics Project\sql-data-analytics-project-main\datasets\csv-files\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'D:\Advanced Data Analytics Project\sql-data-analytics-project-main\datasets\csv-files\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'D:\Advanced Data Analytics Project\sql-data-analytics-project-main\datasets\csv-files\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO



-- Change by time : [Measure] by Date Dimension


SELECT YEAR(order_date) AS order_year,
       SUM (sales_amount) AS total_sales, 
	   COUNT(DISTINCT customer_key) AS total_customers,
	   SUM (quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)


SELECT MONTH(order_date) AS order_month,
       SUM (sales_amount) AS total_sales, 
	   COUNT(DISTINCT customer_key) AS total_customers,
	   SUM (quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)


SELECT YEAR(order_date) AS order_year,
       MONTH(order_date) AS order_month,
       SUM (sales_amount) AS total_sales, 
	   COUNT(DISTINCT customer_key) AS total_customers,
	   SUM (quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY  YEAR(order_date), MONTH(order_date)
ORDER BY  YEAR(order_date), MONTH(order_date)


SELECT DATETRUNC(month, order_date) AS order_date,
       SUM (sales_amount) AS total_sales, 
	   COUNT(DISTINCT customer_key) AS total_customers,
	   SUM (quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY  DATETRUNC(month, order_date)
ORDER BY  DATETRUNC(month, order_date) 


SELECT DATETRUNC(year, order_date) AS order_date,
       SUM (sales_amount) AS total_sales, 
	   COUNT(DISTINCT customer_key) AS total_customers,
	   SUM (quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY  DATETRUNC(year, order_date)
ORDER BY  DATETRUNC(year, order_date) 


SELECT FORMAT(order_date, 'yyyy-MMM') AS order_date,
       SUM (sales_amount) AS total_sales, 
	   COUNT(DISTINCT customer_key) AS total_customers,
	   SUM (quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')


-- How many new customers were added each year:


SELECT DATETRUNC(year, create_date) AS create_year, 
       COUNT (customer_key) AS total_customer
FROM gold.dim_customers
GROUP BY  DATETRUNC(year, create_date)
ORDER BY  DATETRUNC(year, create_date)


-- CUMULATIVE ANALYSIS

-- Total sales per month and running total of sales over time:


SELECT DATETRUNC(month, order_date) AS order_date, 
       SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT  NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)


-- Running sales of one year together without adding from previous year:


SELECT order_date, 
       total_sales,
SUM (total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales
FROM 
(
SELECT DATETRUNC(month, order_date) AS order_date, 
       SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT  NULL
GROUP BY DATETRUNC(month, order_date)
) t
 

 -- Total sales per year and running total of sales over time:


SELECT order_date, 
       total_sales,
SUM (total_sales) OVER (ORDER BY order_date) AS running_total_sales
FROM 
(
SELECT DATETRUNC(year, order_date) AS order_date, 
       SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT  NULL
GROUP BY DATETRUNC(year, order_date)
) t


-- Total sales per year and running total of sales over time, along with moving average of price:


SELECT order_date, 
       total_sales,
SUM (total_sales) OVER (ORDER BY order_date) AS running_total_sales,
AVG (avg_price) OVER (ORDER BY order_date) AS moving_average_price
FROM 
(
SELECT DATETRUNC(year, order_date) AS order_date, 
       SUM(sales_amount) AS total_sales,
	   AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT  NULL
GROUP BY DATETRUNC(year, order_date)
) t