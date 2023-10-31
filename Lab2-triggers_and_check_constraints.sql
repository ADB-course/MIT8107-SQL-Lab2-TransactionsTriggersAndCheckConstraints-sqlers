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
--create a products_undo table which will be used with the trigger
--two columns added change_type and date_of_change

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
