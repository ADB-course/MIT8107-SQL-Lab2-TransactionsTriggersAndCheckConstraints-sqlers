-- Create a table that will record the old values of the product table before changes took place.
-- date_change will record the time and date that the data manipulation took place.
-- type_of _change records the type of data manipulation done
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

