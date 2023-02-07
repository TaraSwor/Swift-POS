-- View to add product name in orderline
CREATE OR REPLACE VIEW v_productinorderline
AS
SELECT ol.orderID, ol.productID, ol.lineTotal, ol.quantity, ol.unitPrice, p.`name` 'productname'
FROM orderline ol join product p ON ol.productID = p.ID
order BY orderID, productID;

-- Test codes
Select JSON_OBJECT('Name', concat(firstName,' ', lastName),'orders',
json_arrayagg(JSON_OBJECT('orderID',`order`.id, "OrderTotal",`order`.orderTotal, "products", 
( select json_arrayagg(JSON_OBJECT('product name',productname, 'LineTotal', lineTotal)) 
FROM v_productinorderline WHERE orderID = `order`.ID)))) 
from customer JOIN `order` 
on customer.id = `order`.customerid 
 WHERE customer.id = 1 
INTO OUTFILE 'testing.json';
-- 
-- Select JSON_OBJECT("Name", concat(first_name," ", last_name), "Address:",
--  concat(street1, ",", coalesce(street2,"N/A"), ",", city, ",", state, "-", zip_code), "Email", email, "Orders",
-- json_arrayagg(JSON_OBJECT("OrderID",`order`.id, "OrderTotal",`order`.orderTotal, "OrderDate", `order`.datePlaced, "Products", 
-- ( select json_arrayagg(JSON_OBJECT("ProductName",productname, "Quantity", quantity, "UnitPrice", unitPrice)) 
-- FROM v_productinorderline WHERE orderID = `order`.ID)))) 
-- from v_customers JOIN `order` 
-- on v_customers.customer_number = `order`.customerid 
-- WHERE v_customers.customer_number = 1;

-- Procedure to run select query into new outfile 
delimiter //
CREATE or replace PROCEDURE generate_json(id_num INT)
begin
SET @SQL = CONCAT( 'Select JSON_OBJECT("Name", concat(first_name," ", last_name), "Address:",
 concat(street1, ",", coalesce(street2,"N/A"), ",", city, ",",state, "-", zip_code), "Email", email, "Orders",
json_arrayagg(JSON_OBJECT("OrderID",`order`.id, "OrderTotal",`order`.orderTotal, "OrderDate", `order`.datePlaced, "Products", 
( select json_arrayagg(JSON_OBJECT("ProductName",productname, "Quantity", quantity, "UnitPrice", unitPrice)) 
FROM v_productinorderline WHERE orderID = `order`.ID)))) 
from v_customers JOIN `order` 
on v_customers.customer_number = `order`.customerid 
WHERE v_customers.customer_number = ', id_num, ' 
INTO OUTFILE "customer_',id_num,'.json"');
PREPARE stmt1 FROM @SQL;
EXECUTE stmt1;
DEALLOCATE prepare stmt1;
END //
delimiter ;

-- Procedure to generate json files for all customers
delimiter //
CREATE OR REPLACE PROCEDURE proc_runcustomers()
BEGIN
DECLARE n INT DEFAULT 0;
DECLARE i INT DEFAULT 0;
SELECT COUNT(*) FROM customer INTO n;
SET i = 0;
while i<n do
CALL generate_json(i);
SET i = i + 1;
END while;
END //
delimiter ;

-- call procedure
CALL proc_runcustomers();

-- Command to import multiple files into mongodb in windows from cmd prompt
-- for %i in (C:\Users\Anshita\JSONCustomers\*) do mongoimport --file %i --type json --db pos --collection Customers