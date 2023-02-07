USE pos;
-- Create a list of customer names, sorted by last name then first name. Call the lastName column 
-- “LN” and the firstName column “FN”. Name this view v_CustomerNames

CREATE OR REPLACE VIEW v_CustomerNames AS 
SELECT lastName "LN", firstName "FN" 
FROM customer 
ORDER BY lastName, firstName ASC;

-- Create a list of customers with the full address. Include the ID but call it “customer_number”, 
-- include the first name but call it “first_name”, include the last name but call it “last_name”, 
-- include address1 but call it “street1”, include address2 but call it “street2”, include city, state, 
-- and zip but call zip “zip_code”, and include email address. Call your view v_Customers 

create or replace view v_Customers as
SELECT c.ID "customer_number", c.firstName "first_name", c.lastName "last_name", 
c.address1 "street1", c.address2 "street2", a.city, a.state, a.zip "zip_code", c.email
FROM customer AS c
LEFT JOIN city AS a ON c.zip = a.zip;

-- Create a list of all customers that bought each particular product.
-- Include the product’s ID  (call it  productID) and name (call it productName),
-- as well as the customer’s ID, first, and last name, 
-- each element separated by a single space, and then use a comma to separate the individual 
-- customers (call it “customers”). Do not add an additional space between the comma and the 
-- next customer’s ID. Include each customer only once, and sort them by ID. Be sure your view 
-- will include all products, even those without customers. Call your view v_ProductBuyers 

CREATE OR REPLACE VIEW v_ProductBuyers as
SELECT prod.id "productID", prod.`name` "productName", 
GROUP_CONCAT(Distinct c.ID," ",c.firstName," ",c.lastName order BY c.ID) "customers"
FROM product AS prod
Left JOIN orderLine AS ol ON prod.id = ol.productID
LEFT JOIN `order` AS o ON ol.orderID = o.ID
LEFT JOIN customer AS c ON o.customerID = c.ID
GROUP BY prod.id; 

-- Create a list of all products that each buyer has purchased. Include each customer’s ID, 
-- firstName, and lastName, as well as a list of products called “products” with the ID, a space, and 
-- the name of the product. Separate each product with the pipe character, ‘|’, instead of the 
-- default space. Show all customers, even any that may not have yet bought any products. List 
-- each product once, and only once, and sort them by the product ID. Call your view 
-- v_CustomerPurchases 

CREATE OR REPLACE VIEW v_CustomerPurchases as
SELECT c.ID, c.firstName, c.lastName, 
GROUP_CONCAT(Distinct prod.id," ",prod.`name` order BY prod.id SEPARATOR '|') "products"
FROM customer AS c
LEFT JOIN `order` AS o ON c.ID = o.customerID
LEFT JOIN orderLine AS ol ON o.ID = ol.orderID
LEFT JOIN product AS prod ON ol.productID = prod.ID
GROUP BY c.ID;

-- Create a materialized view of the v_ProductBuyers and v_CustomerPurchases, and call them 
-- mv_ProductBuyers and mv_CustomerPurchases. You do not need them to automatically refresh 
-- at this point, though this functionality will be added in later milestones. Use the same column 
-- names and descriptions from above.

CREATE TABLE mv_ProductBuyers ENGINE=INNODB AS
SELECT * FROM v_ProductBuyers;

CREATE TABLE mv_CustomerPurchases ENGINE=INNODB AS
SELECT * FROM v_CustomerPurchases;

-- Create a new index called “idx_CustomerEmail” that allows for faster searching of customers BY 
-- their email address.
CREATE INDEX idx_CustomerEmail ON 
customer (email);

-- Create a new index called “idx_ProductName” that allows for faster searching for products by 
-- their NAME.
CREATE INDEX idx_ProductName ON 
product (`name`);

