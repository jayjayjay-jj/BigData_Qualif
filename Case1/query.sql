--a. 
SELECT MAX(TotalPrice.AfterDiscountedPrice) AS MostProfitablePrice, 
    TotalPrice.productcategoryname AS CategoryName
    FROM (
        SELECT ((PS.product_price * (quantity - COALESCE(is_cancelled, 0))) - (PS.product_price * (quantity - COALESCE(is_cancelled, 0)) * PS.discount)) AS AfterDiscountedPrice,
            PC.productcategoryname
        FROM sales_detail SD
        JOIN sales SL
            ON SD.sales_id = SL.sales_id
        JOIN products PS
            ON PS.product_id = SD.product_id
        JOIN msproductcategory PC
            ON PS.product_category_id = PC.productcategoryid
        WHERE YEAR(sales_date) = 2019
    ) AS TotalPrice
GROUP BY TotalPrice.productcategoryname, TotalPrice.AfterDiscountedPrice
ORDER BY MostProfitablePrice DESC
LIMIT 1


--b.
SELECT MAX(salestotal.SalesCount) AS TotalSalesCount,
    salestotal.provincename,
    salestotal.cityname
FROM (
        SELECT COUNT(SS.sales_id) AS SalesCount, 
            YEAR(SS.sales_date) AS SalesYear,
            ML.provincename,
            ML.cityname
    FROM sales SS     
    JOIN mslocation ML 
        ON ML.locationid = SS.location_id
    GROUP BY YEAR(SS.sales_date), ML.provincename, ML.cityname
) AS salestotal
GROUP BY salestotal.provincename, salestotal.cityname
ORDER BY TotalSalesCount DESC
LIMIT 1


--c.
SELECT MAX(Prices.AfterDiscountedPrice) AS ProductPrice,
    Prices.product_name AS ProductName
FROM (
    SELECT ((PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount)) AS AfterDiscountedPrice,
            PS.product_name
    FROM sales_detail SD
    JOIN products PS
        ON PS.product_id = SD.product_id
) AS Prices
GROUP BY Prices.product_name
ORDER BY ProductPrice DESC
LIMIT 1


--d.
SELECT COUNT(SS.sales_id) AS TotalTransaction, 
    CT.customer_id AS CustomerID,
    CT.customer_name AS CustomerName, 
    CT.customer_dob AS CustomerDOB, 
    CT.customer_email AS CustomerEmail, 
    CT.customer_phone AS CustomerPhone
FROM sales SS         
JOIN customer CT 
    ON SS.customer_id = CT.customer_id,
(
    SELECT AVG(TransactionGrouping.TransactionCount) AS Average
    FROM (
        SELECT COUNT(SS.sales_id) AS TransactionCount, 
            CT.customer_id AS CustomerID
        FROM sales SS          
        JOIN customer CT
            ON SS.customer_id = CT.customer_id
        GROUP BY CT.customer_id
    ) AS TransactionGrouping
    GROUP BY TransactionGrouping.CustomerID
) AS AverageGrouping
GROUP BY CT.customer_id, CT.customer_name, CT.customer_dob, CT.customer_email, CT.customer_phone, AverageGrouping.Average
HAVING TotalTransaction > AverageGrouping.Average


--e.
SELECT SUM((PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount)) AS AfterDiscountedPrice,
    CT.customer_id AS CustomerID,
    CT.customer_name AS CustomerName, 
    CT.customer_dob AS CustomerDOB, 
    CT.customer_email AS CustomerEmail, 
    CT.customer_phone AS CustomerPhone,
    CASE 
        WHEN ((PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount)) >= 10000000 AND ((PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount)) <= 24999999 THEN '1000000'
        WHEN ((PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount)) >= 25000000 AND ((PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount)) <= 49999999 THEN '5000000'
        WHEN ((PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount)) >= 50000000 THEN '10000000'
    END AS Voucher
FROM sales_detail SD 
JOIN products PS
    ON PS.product_id = SD.product_id
JOIN sales SS      
    ON SD.sales_id = SS.sales_id
JOIN customer CT 
    ON CT.customer_id = SS.customer_id
WHERE YEAR(SS.sales_date) = 2019 AND MONTH(SS.sales_date) = 12 AND (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0))) - (PS.product_price * (SD.quantity - COALESCE(SD.is_cancelled, 0)) * PS.discount) >= 1000000
GROUP BY CT.customer_id, CT.customer_name, CT.customer_dob, CT.customer_email, CT.customer_phone, PS.product_price, SD.quantity, SD.is_cancelled, PS.discount
