-- What is the total number of customers in each state?
SELECT state
	 , Count(distinct customer_id) 'Total Customers'
FROM customers
GROUP BY state
ORDER BY 'Total Customers' desc;
-- Find the most recent order date of each customer.
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(o.order_date) AS most_recent_order_date
FROM 
    customers c
JOIN 
    orders o ON c.customer_id = o.customer_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name;
-- How much revenue did each store contribute to the total sales, 
-- and what percentage of the total sales does that represent?
WITH StoreRevenue AS (
    SELECT 
        s.store_id,
        s.store_name,
        SUM(oi.quantity * (oi.list_price - oi.discount)) AS store_revenue
    FROM 
        stores s
    JOIN 
        orders o ON s.store_id = o.store_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        s.store_id, s.store_name
),
TotalRevenue AS (
    SELECT 
        SUM(store_revenue) AS total_revenue
    FROM 
        StoreRevenue
)
SELECT 
    sr.store_id,
    sr.store_name,
    sr.store_revenue,
    ROUND((sr.store_revenue / tr.total_revenue) * 100, 2) AS revenue_percentage
FROM 
    StoreRevenue sr
CROSS JOIN 
    TotalRevenue tr
ORDER BY 
    sr.store_revenue DESC;
-- Which product has been sold the most across all stores?
SELECT TOP 1
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM 
    products p
JOIN 
    order_items oi ON p.product_id = oi.product_id
GROUP BY 
    p.product_id, p.product_name
ORDER BY 
    total_quantity_sold DESC;
-- Find the top 3 products by revenue for each store.
WITH Store1 AS (
    SELECT TOP 3 With ties
        S.store_name,
        P.product_name,
        ROUND(SUM(OI.quantity * OI.list_price * (1 - OI.discount)), 2) AS [Total revenue each product]
    FROM 
	stores S
    JOIN 
	orders O ON S.store_ID = O.store_ID
    JOIN 
	order_items OI ON O.order_id = OI.order_id
    JOIN 
	products P ON OI.product_id = P.product_id
    WHERE 
	S.store_name = 'Baldwin Bikes'
    GROUP BY 
	S.store_name, P.product_name
    ORDER BY 
	[Total revenue each product] DESC),
Store2 AS (
    SELECT TOP 3 WITH ties
        S.store_name,
        P.product_name,
        ROUND(SUM(OI.quantity * OI.list_price * (1 - OI.discount)), 2) AS [Total revenue each product]
    FROM 
	stores S
    JOIN 
	orders O ON S.store_ID = O.store_ID
    JOIN 
	order_items OI ON O.order_id = OI.order_id
    JOIN 
	products P ON OI.product_id = P.product_id
    WHERE 
	S.store_name = 'Santa Cruz Bikes'
    GROUP BY 
	S.store_name, P.product_name
    ORDER BY 
	[Total revenue each product] DESC),
Store3 AS (
    SELECT TOP 3 With ties
        S.store_name,
        P.product_name,
        ROUND(SUM(OI.quantity * OI.list_price * (1 - OI.discount)), 2) AS [Total revenue each product]
    FROM 
	stores S
    JOIN 
	orders O ON S.store_ID = O.store_ID
    JOIN 
	order_items OI ON O.order_id = OI.order_id
    JOIN 
	products P ON OI.product_id = P.product_id
    WHERE 
	S.store_name = 'Rowlett Bikes'
    GROUP BY 
	S.store_name, P.product_name
    ORDER BY 
	[Total revenue each product] DESC)
SELECT * 
FROM 
	Store1
UNION ALL
SELECT * 
FROM 
	Store2
UNION ALL
SELECT * 
FROM 
	Store3;
-- Which products are currently out of stock?
SELECT 
    p.product_id,
    p.product_name
FROM 
    products p
LEFT JOIN 
    stocks s ON s.product_id = p.product_id
WHERE 
    s.quantity = 0;
-- What is the total value of inventory in each store?
SELECT 
    s.store_id,
    s.store_name,
    ROUND(SUM(oi.quantity * oi.list_price),2) AS total_inventory_value
FROM 
    stores s
JOIN 
    orders o ON s.store_id = o.store_id
JOIN 
    order_items oi ON o.order_id = oi.order_id
GROUP BY 
    s.store_id, s.store_name;
-- Rank categories based on the highest average order value
WITH CategoryAverageOrderValue AS (
    SELECT 
        p.category_id,
        c.category_name,
        ROUND(AVG(oi.quantity * oi.list_price),2) AS average_order_value
    FROM 
        order_items oi
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        p.category_id, c.category_name
)
SELECT 
    category_id,
    category_name,
    average_order_value,
    RANK() OVER (ORDER BY average_order_value DESC) AS rank
FROM 
    CategoryAverageOrderValue
ORDER BY 
    rank;
-- Which brand has the highest sales in the past year?
SELECT TOP 1
    p.brand_id,
    b.brand_name,
    SUM(oi.quantity * oi.list_price) AS total_sales
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    brands b ON p.brand_id = b.brand_id
JOIN 
    orders o ON oi.order_id = o.order_id
WHERE 
    o.order_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY 
    p.brand_id, b.brand_name
ORDER BY 
    total_sales DESC;
-- Rank staff members based on the total order value they generated.
WITH StaffSales AS (
    SELECT 
        s.staff_id,
        s.first_name,
        s.last_name,
        SUM(oi.quantity * oi.list_price) AS total_sales
    FROM 
        staffs s
    JOIN 
        orders o ON s.staff_id = o.staff_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        s.staff_id, s.first_name, s.last_name
)
SELECT 
    staff_id,
    first_name,
    last_name,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS rank
FROM 
    StaffSales
ORDER BY 
    rank;
