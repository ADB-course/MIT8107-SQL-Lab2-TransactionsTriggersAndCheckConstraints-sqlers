--1. Create a database transaction that fires a trigger if the transaction attempts to manipulate data incorrectly.
-- switch to the current database
USE 75855_lab2_triggers;

-- STEP 1: Transaction

-- turn of autocommit option
SET autocommit = OFF;

-- set isolation level
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;

-- create the new column in orders table to record the orderTotal amount
ALTER TABLE orders
ADD orderTotal decimal(10,2);

-- create the new column in payments table to record the ordorderNumber
ALTER TABLE payments
ADD orderNumber int NOT NULL;

-- Create Triggers

-- Trigger 1: check if the customerNumber is valid
DELIMITER //
CREATE TRIGGER order_customer_check
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN 
    -- Check if the customerNumber exists in the customers table
    SELECT COUNT(*) INTO @customer_exists
    FROM customers
    WHERE customerNumber = NEW.customerNumber;
    
    IF @customer_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid customerNumber';
    END IF;  
   
END;
//
DELIMITER ;

-- Trigger 2: Check if a payment is made when an order is inserted
DROP TRIGGER IF EXISTS order_payment_check;

-- Recreate the trigger with new logic
DELIMITER //
CREATE TRIGGER order_payment_check
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE order_amount DECIMAL(10, 2);
    
    -- Get the total amount of the corresponding order
    SELECT orderTotal INTO order_amount
    FROM orders
    WHERE orderNumber = NEW.orderNumber;

    -- Check if the payment amount is less than the order amount
    IF NEW.amount < order_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment amount is less than the order amount';
    END IF;
END;
//
DELIMITER ;

-- Create a save point before an order is made
SAVEPOINT order_savepoint;

-- Insert a new order
SELECT @orderNumber := MAX(orderNumber)+1 FROM orders;
INSERT INTO orders (orderNumber,orderDate, requiredDate, shippedDate, status, comments, customerNumber, orderTotal)
VALUES (@orderNumber,DATE(NOW()), DATE(DATE_ADD(NOW(), INTERVAL 3 DAY)), NULL, 'Processing', 'New order', 103, 1500);

select * from orders order by orderNumber desc;

select * from payments order by customerNumber asc;

-- Create a save point before a payment is made
SAVEPOINT payment_savepoint;

-- Record a payment for the order
INSERT INTO payments (customerNumber, checkNumber, paymentDate, amount, orderNumber)
VALUES (103, 'CHK123456', DATE(NOW()), 1200, @orderNumber);


-- Create a table that will record the old values of the product table before changes took place.
-- date_change will record the time and date that the data manipulation took place.
-- type_of _change records the type of data manipulation done
SAVEPOINT payment_savepoint;

CREATE TABLE `products_undo`
(
`date_changed` timestamp(2) NOT NULL DEFAULT CURRENT_TIMESTAMP(2),
`productCode` varchar(15) NOT NULL,
`productName` varchar(70) DEFAULT NULL,
`productLine` varchar(50) DEFAULT NULL,
`productScale` varchar(10) DEFAULT NULL,
`productVendor` varchar(50) DEFAULT NULL,
`productDescription` text DEFAULT NULL,
`quantityInStock` smallint DEFAULT NULL,
`buyPrice` decimal(10,2) NOT NULL,
`MSRP` decimal(10,2) NOT NULL,
`type_of_change` varchar(50) NOT NULL,
PRIMARY KEY (`date_changed`),
UNIQUE KEY `date_changed_UNIQUE` (`date_changed`)
) ENGINE= InnoDB;
=======

DELIMITER //
CREATE TRIGGER TRG_BEFORE_UPDATE_ON_products BEFORE UPDATE ON products FOR EACH ROW
BEGIN
    IF NEW.price < 0 THEN
        INSERT INTO products_undo (productCode, productName, buyPrice, type_of_change) 
        VALUES (OLD.productCode, OLD.productName, OLD.buyPrice, 'Incorrect Update');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid price value. Negative prices are not allowed.';
    END IF;
END//
DELIMITER ;

-- Check constraint for correct data manipulation
ALTER TABLE products
ADD CONSTRAINT chk_positive_price CHECK (price >= 0);
Check constraint in the offices table to ensure that the values added under phone are the correct format
-- The constraint enforces that the phone starts with a symbol (+)

ALTER TABLE offices
ADD CONSTRAINT chk_format CHECK (phone LIKE '+%');

-- trigger set to fire before an insertion into order details table

DELIMITER //

CREATE TRIGGER trg_check_quantityOrdered
BEFORE INSERT ON orderdetails
FOR EACH ROW
BEGIN
-- declare a local variable named quantity_in_stock which is an integer 
-- to store the value that is retrieved from quantityInStock in the products table
-- NOTE: not the same as the one in the products table

    DECLARE quantity_in_stock INT;
    
-- fetch the value to temporarily store into the new quantity ins tock
    SELECT quantityInStock INTO quantity_in_stock
    FROM products

-- corresponds to the products in stock

    WHERE productCode = NEW.productCode;

    IF NEW.quantityOrdered > quantity_in_stock THEN

-- SIGNAL SQLSTATE '45000'- unhandled user-defined exception

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'QuantityOrdered cannot exceed QuantityInStock';
    END IF;
END;
//

DELIMITER ;
-- test trigger trg_check_quantityOrdered
SELECT @orderNumber := MAX(orderNumber)+1 FROM orders;
INSERT INTO orders (orderNumber,orderDate, requiredDate, shippedDate, status, comments, customerNumber, orderTotal)
VALUES (@orderNumber,DATE(NOW()), DATE(DATE_ADD(NOW(), INTERVAL 3 DAY)), NULL, 'Processing', 'New order', 103, 1500);

select * from orders order by orderNumber desc;
-- the error message defined should be displayed


COMMIT;

SET autocommit = ON;
