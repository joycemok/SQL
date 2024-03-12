-- Mutate and Clean Table -- 

-- drop empty columns --
ALTER TABLE coffee_sales.orders
DROP `Customer Name`,
DROP `Email`,
DROP `Country`,
DROP `Coffee Type`,
DROP `Roast Type`,
DROP `Size`,
DROP `Unit Price`,
DROP `Sales`;

-- change dates to datetime type --
UPDATE coffee_sales.orders
SET `Order Date` = STR_TO_DATE(`Order Date`, '%m/%d/%Y');

-- rename coffee bean types to full name -- 
UPDATE coffee_sales.products
SET `Coffee Type` = REPLACE(`Coffee Type`, 'Ara', 'Arabica');

UPDATE coffee_sales.products
SET `Coffee Type` = REPLACE(`Coffee Type`, 'Rob', 'Robusta');

UPDATE coffee_sales.products
SET `Coffee Type` = REPLACE(`Coffee Type`, 'Lib', 'Liberica');

UPDATE coffee_sales.products
SET `Coffee Type` = REPLACE(`Coffee Type`, 'Exc', 'Excelsa');


-- SQL Queries --
Use coffee_sales;

-- Learning About Customers --

-- Top 10 Customers by sales and are they loyalty members -- 
SELECT orders.`Customer ID`, customers.`Customer Name`,  customers.`Loyalty Card`, SUM(Quantity) AS quantity_purchased, ROUND(SUM((orders.Quantity * products.`Unit Price`)), 2) AS money_spent
FROM orders
LEFT JOIN customers ON orders.`Customer ID` = customers.`Customer ID`
LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
GROUP BY orders.`Customer ID`, customers.`Customer Name`, customers.`Loyalty Card`
ORDER BY money_spent DESC
LIMIT 10;

-- Number of people who have loyalty cards -- 
SELECT `Loyalty Card`, COUNT(`Loyalty Card`) AS Count 
FROM customers
GROUP BY `Loyalty Card`;

-- Learning About Products -- 

-- Item with most and least profit --
SELECT *
FROM products
WHERE Profit = (SELECT Max(Profit) FROM products) OR Profit = (SELECT Min(Profit) FROM products);

-- Types of coffee that makes most revenue --  
SELECT products.`Coffee Type`, ROUND(SUM(orders.Quantity * products.`Unit Price`), 2) AS Revenue
From orders
LEFT JOIN customers ON orders.`Customer ID` = customers.`Customer ID`
LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
GROUP BY products.`Coffee Type`
ORDER BY Revenue DESC;

-- Profit and revenue of each type of coffee and size --
SELECT orders.`Product ID`, products.`Coffee Type`, products.`Roast Type`, products.Size, ROUND(SUM((orders.Quantity * products.`Unit Price`)), 2) AS Revenue, ROUND(SUM(orders.Quantity * products.Profit), 2) AS Profit
FROM orders
LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
GROUP BY orders.`Product ID`, products.`Coffee Type`, products.`Roast Type`, products.Size
ORDER BY Profit DESC;


-- Products By Country --

-- Quantity and Number of Orders By Country --
SELECT customers.Country, SUM(orders.Quantity) AS quantity_sold, COUNT(DISTINCT orders.`Customer ID`) AS orders
FROM orders
LEFT JOIN customers ON customers.`Customer ID` = orders.`Customer ID`
GROUP BY customers.Country
ORDER BY quantity_sold DESC;

-- Profit and Revenue Per Country --
SELECT customers.Country, ROUND(SUM((orders.Quantity * products.`Unit Price`)), 2) AS Revenue, ROUND(SUM(orders.Quantity * products.Profit), 2) AS Profit
FROM orders
LEFT JOIN customers ON customers.`Customer ID` = orders.`Customer ID`
LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
GROUP BY customers.Country;

--  Most popular product by country --
WITH coffee_type AS (
	SELECT customers.Country, products.`Coffee Type`, products.`Roast Type`, products.Size, SUM(Quantity) AS `Quantity Sold`
	FROM orders
	LEFT JOIN customers ON orders.`Customer ID` = customers.`Customer ID`
	LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
	GROUP BY customers.Country, products.`Coffee Type`, products.`Roast Type`, products.Size
),
quant_rank AS (
	SELECT *, DENSE_RANK() OVER(PARTITION BY Country ORDER BY `Quantity Sold` DESC) AS q_rank
    FROM coffee_type
)
SELECT Country, `Coffee Type`, `Roast Type`, Size, `Quantity Sold` 
FROM quant_rank
WHERE q_rank = 1
ORDER BY `Quantity Sold` DESC;

-- Top 3 cities for each country --
WITH by_country AS (
	SELECT customers.City, customers.Country, SUM(orders.Quantity) as Quantity_Sold, ROUND(SUM(orders.Quantity * products.`Unit Price`), 2) AS Sales
	FROM orders
	LEFT JOIN customers ON orders.`Customer ID` = customers.`Customer ID`
	LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
	GROUP BY customers.Country, customers.City
	ORDER BY Sales DESC
),
sold_rank AS (
	SELECT *, DENSE_RANK() OVER(PARTITION BY Country ORDER BY Sales DESC) AS ranking
    FROM by_country
)
SELECT City, Country, Quantity_Sold, Sales
FROM sold_rank
WHERE ranking IN (1,2,3);

-- Top 5 U.S. Cities by Coffee Bean Sales --
SELECT customers.City, customers.Country, SUM(orders.Quantity) as Quantity_Sold, ROUND(SUM(orders.Quantity * products.`Unit Price`), 2) AS Sales
FROM orders
LEFT JOIN customers ON orders.`Customer ID` = customers.`Customer ID`
LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
WHERE customers.Country = 'United States'
GROUP BY customers.Country, customers.City
ORDER BY Sales DESC
LIMIT 5;

-- Sales Trends -- 

-- Revenue By Year -- 
SELECT YEAR(orders.`Order Date`) AS Years, ROUND(SUM(orders.Quantity * products.`Unit Price`), 2) AS Revenue
From orders
LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
GROUP BY Years
ORDER BY Years ASC;

-- Revenue Per Month Each Year --
SELECT YEAR(orders.`Order Date`)AS order_year, MONTHNAME(orders.`Order Date`) AS order_month, ROUND(SUM(orders.Quantity * products.`Unit Price`), 2) AS Sales 
FROM orders
LEFT JOIN products ON orders.`Product ID` = products.`Product ID`
GROUP BY order_year, order_month
ORDER BY Sales DESC;
