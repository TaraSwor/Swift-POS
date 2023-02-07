DROP DATABASE if EXISTS pos;
CREATE DATABASE pos;
USE pos;

create table `city` (
`zip` decimal(5,0) unsigned zerofill not null,
`city` varchar(32) default null,
`state` varchar(4) default null,
primary key (`zip`)
) engine=innoDB default charset=latin1;

create table `status` (
`status` tinyint not null,
`description` VARCHAR(12) default null,
primary key (`status`)
) engine=innoDB default charset=latin1; 

create table `customer` (
`ID` int not null,
`firstName` VARCHAR(64) default null,
`lastName` VARCHAR(32) default NULL,
`email` VARCHAR(128),
`address1` VARCHAR(128),
`address2` VARCHAR(128) default NULL,
`phone` VARCHAR(32) default NULL,
`birthDate` Date default NULL,
`zip` DECIMAL(5,0) unsigned zerofill,
primary key (`ID`),
FOREIGN KEY (`zip`) REFERENCES `city`(`zip`)
) engine=innoDB default charset=LATIN1; 

create table `product` (
`ID` int not null,
`name` VARCHAR(128) default null,
`currentPrice` decimal(6,2) default NULL,
`qtyOnHand` INT,
primary key (`id`)
) engine=innoDB default charset=latin1; 

create table `order` (
`ID` int not NULL PRIMARY key,
`datePlaced` date,
`dateShipped` date,
`status` TINYINT,
`customerID` INT,
FOREIGN KEY (`status`) REFERENCES `status`(`status`),
FOREIGN KEY (`customerID`) REFERENCES `customer`(`ID`)
) engine=innoDB default charset=LATIN1;

CREATE TABLE `orderLine` (
`orderID` INT REFERENCES `order`(`ID`),
`productID` INT REFERENCES `product`(`ID`),
`quantity` INT,
PRIMARY KEY(`orderID`,`productID`)
) ENGINE=INNODB DEFAULT CHARSET=LATIN1;

SELECT TABLE_NAME,COLUMN_NAME,REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_SCHEMA = 'pos';
DESCRIBE customer;

create table `tempcustomer` (
`ID` int not null,
`firstName` VARCHAR(64) default null,
`lastName` VARCHAR(32) default NULL,
`email` VARCHAR(128),
`address1` VARCHAR(128),
`address2` VARCHAR(128) default NULL,
`phone` VARCHAR(32) default NULL,
`birthDate` Date default NULL,
`city` VARCHAR(32) DEFAULT NULL,
`st` VARCHAR(4) DEFAULT NULL,
`zip` DECIMAL(5,0) unsigned zerofill,
primary key (`ID`)
) engine=innoDB default charset=LATIN1; 

create table `tempprod` (
`ID` int not null,
`name` VARCHAR(128) default null,
`currentPrice` decimal(6,2) default NULL,
`qtyOnHand` INT,
primary key (`id`)
) engine=innoDB default charset=latin1; 


Load DATA local INFILE 'products.csv'
into table tempprod
fields terminated by ','
enclosed by '"'
lines terminated BY '\n'
ignore 1 rows
(ID,`name`,@currentPrice,qtyOnHand)
SET tempprod.currentPrice = REPLACE(Replace(@currentPrice,'$',''),",",""); 

Load DATA local INFILE 'customers.csv'
into table tempcustomer
fields terminated by ','
enclosed by '"'
lines terminated BY '\n'
ignore 1 ROWS
(ID,`firstName`,`lastName`,`city`,st,zip,address1,address2,email,@dob)
SET birthDate = STR_TO_DATE(@dob, '%m/%d/%Y'); 

UPDATE tempcustomer SET address2 = NULL WHERE address2 = '';

UPDATE tempcustomer SET birthDate = NULL WHERE birthDate = '0000-00-00';

INSERT INTO city(`zip`,`city`,`state`)
SELECT zip, city, st
FROM tempcustomer
GROUP BY zip;

INSERT into customer (ID, firstName, lastName, email, address1, address2, phone, birthDate,zip)
SELECT ID, firstName, lastName, email, address1, address2, phone, birthDate, zip
FROM tempcustomer;

DROP TABLE if EXISTS temporderLine;

CREATE TABLE `temporderLine` (
`orderID` INT,
`productID` INT
) ENGINE=INNODB;


Load DATA LOCAL INFILE 'orderlines.csv'
into TABLE `temporderLine`
fields terminated by ','
enclosed by '"'
lines terminated BY '\n'
ignore 1 rows
(orderID,productID); 

INSERT INTO product
SELECT * FROM tempprod;

Load data local INFILE 'orders.csv'
into TABLE `order`
fields terminated by ','
enclosed by '"'
lines terminated BY '\n'
ignore 1 rows
(ID,customerID); 

INSERT INTO orderLine (orderID,productID,quantity)
SELECT orderID, productID, COUNT(productID)
FROM temporderLine
GROUP BY orderID, productID;

DROP TABLE if exists temporderLine ;
DROP TABLE if exists tempcustomer;
DROP TABLE if exists tempprod;