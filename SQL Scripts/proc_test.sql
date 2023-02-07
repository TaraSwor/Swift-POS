-- ALTER the orderLine table to add a 
-- column called unitPrice of type DECIMAL(6,2) 
ALTER TABLE orderLine ADD unitPrice DECIMAL(6,2);
-- ALTER the orderLine table to add a column called 
-- lineTotal of type DECIMAL(7,2) that is a virtual 
-- generated column, made up of quantity * unitPrice 
ALTER TABLE orderLine ADD COLUMN lineTotal DECIMAL(7,2) 
GENERATED ALWAYS AS (unitPrice * quantity) VIRTUAL;
-- ALTER the order table to add a column called 
-- orderTotal that is of type DECIMAL(8,2) 
ALTER TABLE `order` ADD orderTotal DECIMAL(8,2);
-- ALTER the customer table to get rid of the phone column 
ALTER TABLE customer DROP phone; 

-- DROP the status table and ALTER the order table to get rid of 
-- status, both as a column and as a foreign key
ALTER TABLE `order` DROP FOREIGN KEY order_ibfk_1;
ALTER TABLE `order` DROP FOREIGN KEY order_ibfk_2;
DROP TABLE `status`;
ALTER TABLE `order` ADD FOREIGN KEY (customerID) REFERENCES customer(ID);
ALTER TABLE `order` DROP `status`;

-- Create a procedure called proc_FillUnitPrice that will replace 
-- all blank unitPrice entries in orderLine with currentPrice 
-- from product. It will NOT replace existing unitPrice entries with 
-- anything
delimiter $$
CREATE or replace PROCEDURE proc_FillUnitPrice() 
BEGIN 
UPDATE orderLine AS ol
inner JOIN product p ON 
ol.productID = p.ID
SET ol.unitPrice = p.currentPrice
WHERE ol.unitPrice is Null;
END
$$
delimiter ; 

-- Create a procedure called proc_FillOrderTotal in order with the 
-- sum of all of the lineTotal from 
-- all orderLine entries tied to a particular order 
delimiter $$
CREATE or replace PROCEDURE proc_FillOrderTotal() 
BEGIN 
UPDATE `order`
JOIN (SELECT ol.orderID,sum(ol.lineTotal) total FROM orderLine AS ol
GROUP BY ol.orderID) tt
ON `order`.ID = tt.orderID
SET orderTotal = tt.total
WHERE 1=1;
END
$$
delimiter ; 

-- delimiter $$
-- CREATE or replace PROCEDURE proc_FillOrderTotal() 
-- BEGIN 
-- UPDATE `order`
-- SET orderTotal = (SELECT sum(ol.lineTotal) total FROM orderLine AS ol
-- GROUP BY ol.orderID);
-- END
-- $$
-- delimiter ; 
-- Create a procedure called proc_FillMVCustomerPurchases that will 
-- refresh the contents of the 
-- materialized view called mv_CustomerPurchases 
delimiter $$
CREATE OR REPLACE PROCEDURE proc_FillMVCustomerPurchases()
BEGIN
DELETE FROM mv_CustomerPurchases;
INSERT INTO mv_CustomerPurchases
SELECT * FROM v_CustomerPurchases;
END
$$
delimiter ;
