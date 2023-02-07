USE pos;

-- calling stored Procedures
CALL proc_FillUnitPrice();
CALL proc_FillOrderTotal();
CALL proc_FillMVCustomerPurchases();

-- create table priceChangeLog
CREATE OR replace TABLE `priceChangeLog` (
`ID` int unsigned auto_increment PRIMARY key,
`oldPrice` DECIMAL(6,2),
`newPrice` decimal(6,2),
`changeTimestamp` TIMESTAMP,
`productid` INT REFERENCES `product`(ID) 
) engine=innoDB default charset=latin1;

-- SP for update mvproductbuyers 
delimiter $$
CREATE OR REPLACE PROCEDURE proc_updateMVProductBuyers(prodid INT) 
BEGIN
DELETE FROM mv_ProductBuyers WHERE productID = prodid;
INSERT INTO mv_ProductBuyers
SELECT * FROM v_ProductBuyers
WHERE productID = prodid; 
END $$
delimiter ; 

-- SP to update MVcustomerPurchases
delimiter $$
CREATE OR REPLACE PROCEDURE proc_updateMVCustomerPurchases(custid INT) 
BEGIN
DELETE FROM mv_CustomerPurchases WHERE ID = custid;
INSERT INTO mv_CustomerPurchases
SELECT * FROM v_CustomerPurchases
WHERE ID = custid; 
END $$
delimiter ; 

-- SP to subtract qtyOnHand from product
delimiter $$
CREATE OR REPLACE PROCEDURE proc_subtractQtyProduct(pid INT,qty INT) 
BEGIN 
SET @quan =( SELECT qtyOnHand FROM product WHERE ID = pid); 
SET @finalqtyOnHand = @quan - qty;
if @finalqtyOnHand < 0 
THEN 
SIGNAL SQLSTATE '45000' SET message_text = 'Not enough quantity'; 
ELSE
UPDATE product 
SET qtyOnHand = @finalqtyOnHand
WHERE ID = pid; 
END if; 
END $$
delimiter ; 

-- SP to add qtyOnHand from product
delimiter $$
CREATE OR REPLACE PROCEDURE proc_addQtyProduct(pid INT,qty INT) 
BEGIN 
SET @quan =( SELECT qtyOnHand FROM product WHERE ID = pid);
UPDATE product 
SET qtyOnHand = @quan + qty
WHERE ID = pid; 
END $$
delimiter ; 

-- after update pricelog table from product
delimiter $$
CREATE OR REPLACE TRIGGER tr_after_update_on_product_pricelog 
AFTER UPDATE 
ON `product` 
FOR EACH ROW 
BEGIN
if NEW.`currentPrice` != OLD.`currentPrice` 
THEN
INSERT INTO priceChangeLog(`oldPrice`,`newPrice`,`productid`) 
VALUES (OLD.currentPrice,NEW.currentPrice,OLD.ID); 
END if; 
CALL proc_updateMVProductBuyers(NEW.ID); 
END $$
delimiter ;

-- before update on orderline
delimiter $$
CREATE OR REPLACE TRIGGER tr_before_update_on_orderLine_unitprice 
BEFORE UPDATE 
ON `orderLine` 
FOR EACH ROW 
BEGIN 
DECLARE price DECIMAL(6,2);
SELECT currentPrice INTO price
FROM product
WHERE ID = NEW.productID; 
SET NEW.unitPrice = price;
if new.quantity IS NULL 
THEN 
SET new.quantity = 1; 
END if; 
END $$
delimiter ;

-- before insert on orderline
delimiter $$
CREATE OR REPLACE TRIGGER tr_before_insert_on_orderLine_unitprice_insert 
BEFORE INSERT 
ON `orderLine` 
FOR EACH ROW 
BEGIN 
DECLARE price DECIMAL(6,2);
SELECT currentPrice INTO price
FROM product
WHERE ID = NEW.productID; 
SET NEW.unitPrice = price;
if new.quantity IS NULL 
THEN 
SET new.quantity = 1; 
END if; 
END $$
delimiter ;

-- after update on orderline
delimiter $$
CREATE OR REPLACE TRIGGER tr_after_update_on_orderLine_ordertotal 
AFTER UPDATE ON `orderLine` 
FOR EACH ROW 
BEGIN 
DECLARE total DECIMAL(7,2);
SELECT SUM(lineTotal) INTO total
FROM orderLine
WHERE orderID = NEW.orderID;
UPDATE `order` 
SET orderTotal = total
WHERE `order`.ID = NEW.orderID;
if NEW.quantity > OLD.quantity 
THEN 
SET @netQuantity = NEW.quantity - OLD.quantity;
CALL proc_subtractQtyProduct(NEW.productID,@netQuantity); 
ELSE 
SET @netQuantity = OLD.quantity - NEW.quantity;
CALL proc_addQtyProduct(NEW.productID,@netQuantity); 
END if; 
CALL proc_updateMVProductBuyers(NEW.productID); 
CALL proc_updateMVProductBuyers(OLD.productID); 
END $$
delimiter ;

-- after insert on orderline
delimiter $$
CREATE OR REPLACE TRIGGER tr_after_insert_on_orderLine_ordertotal 
AFTER INSERT ON `orderLine` 
FOR EACH ROW 
BEGIN 
DECLARE total DECIMAL(7,2);
SELECT SUM(lineTotal) INTO total
FROM `orderLine`
WHERE orderID = NEW.orderID;
UPDATE `order` 
SET orderTotal = total
WHERE `order`.ID = NEW.orderID; 
CALL proc_updateMVProductBuyers(NEW.productID); 
SET @custid = (SELECT customerID FROM `order` WHERE `order`.ID = NEW.orderID); 
CALL proc_updateMVCustomerPurchases(@custid); 
CALL proc_subtractQtyProduct(NEW.productID,NEW.quantity); 
END $$
delimiter ;

-- after delete on orderline
delimiter $$
CREATE OR REPLACE TRIGGER tr_after_delete_orderline_mv 
AFTER DELETE 
ON `orderLine` 
FOR EACH ROW 
BEGIN 
DECLARE total DECIMAL(7,2);
SELECT SUM(lineTotal) INTO total
FROM orderLine
WHERE orderID = old.orderID;
UPDATE `order` 
SET orderTotal = total
WHERE `order`.ID = old.orderID; 
CALL proc_updateMVProductBuyers(OLD.productID); 
SET @custid = ( SELECT customerID FROM `order` WHERE `order`.ID = old.orderID); 
CALL proc_updateMVCustomerPurchases(@custid); 
CALL proc_addQtyProduct(old.productID,old.quantity); 
END $$
delimiter ;


