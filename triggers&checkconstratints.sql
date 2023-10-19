-- listing the databases
SHOW DATABASES;
-- specify db to use
USE 113610_lab2_triggers;
-- STEP 1. Create a relation that will store the employees’ historical data
SHOW CREATE TABLE employees;
-- new fields in employee duplicate are change_type and 
CREATE TABLE employees_undo (
date_of_change timestamp(2) NOT NULL DEFAULT CURRENT_TIMESTAMP(2)
COMMENT 'Records the date and time when the data was manipulated. This will
help to keep track of the changes made. The assumption is that no 2 users
will change the exact same record at the same time (with a precision of a
hundredth of a second, e.g., 4.26 seconds).',
employeeNumber int NOT NULL,
lastName varchar(50) DEFAULT NULL,
firstName varchar(50) DEFAULT NULL,
extension varchar(10) DEFAULT NULL,
email varchar(100) DEFAULT NULL,
officeCode varchar(10) DEFAULT NULL,
reportsTo int DEFAULT NULL,
jobTitle varchar(50) DEFAULT NULL,
change_type varchar(50) NOT NULL COMMENT 'Records the type of data
manipulation that was done, for example an insertion, an update, or a
deletion.',
PRIMARY KEY (date_of_change),
UNIQUE KEY date_of_change_UNIQUE (date_of_change)
) ENGINE=InnoDB;
-- STEP 2. Create a trigger that is fired before updating an employee’s data
CREATE
TRIGGER TRG_BEFORE_UPDATE_ON_employees
BEFORE UPDATE ON employees FOR EACH ROW
INSERT INTO employees_undo SET
date_of_change = CURRENT_TIMESTAMP(2),
employeeNumber = OLD.employeeNumber ,
lastName = OLD.lastName ,
firstName = OLD.firstName ,
extension = OLD.extension ,
email = OLD.email ,
officeCode = OLD.officeCode ,
reportsTo = OLD.reportsTo ,
jobTitle = OLD.jobTitle ,
change_type = 'An update DML operation was executed';

-- step 3:show triggers
SHOW TRIGGERS;

-- STEP 4. Confirm that the trigger is fired when an update is performed on the
-- “employees” relatioemployeesemployees`employees-undo`n

UPDATE employees
SET
lastName = 'Muiruri'
WHERE
employeeNumber = '1056';

UPDATE employees
SET
email = 'mmuiruri@classicmodelcars.com'
WHERE
employeeNumber = '1056';

SELECT * FROM employees_undo;

-- STEP 5. Create a table to store reminders
CREATE TABLE customers_data_reminders (
customerNumber int NOT NULL COMMENT 'Identifies the customer whose data
is partly missing',
customers_data_reminders_timestamp timestamp(2) NOT NULL DEFAULT
CURRENT_TIMESTAMP(2) COMMENT 'Records the time when the missing data was
detected',
customers_data_reminders_message varchar(100) NOT NULL COMMENT 'Records
a message that helps the customer service personnel to know what data is
missing from the customer\'s record',
customers_data_reminders_status tinyint NOT NULL DEFAULT '0' COMMENT
'Used to record the status of a reminder (0 if it has not yet been
addressed and 1 if it has been addressed)',
PRIMARY KEY
(customerNumber,customers_data_reminders_timestamp,`customers_data_reminders_message`,customers_data_reminders_status),
CONSTRAINT FK_1_customers_TO_M_customers_data_reminders FOREIGN KEY
(customerNumber) REFERENCES customers (customerNumber)
ON DELETE CASCADE
ON UPDATE CASCADE
) 
ENGINE=InnoDB COMMENT='Used to remind the customer service personnel
about a client\'s missing data. This enables them to ask the client to
provide the data during the next interaction with the client.'

-- STEP6 
DELIMITER $$
CREATE TRIGGER TRG_AFTER_INSERT_ON_customers
AFTER INSERT ON customers FOR EACH ROW
BEGIN
 IF NEW.postalCode IS NULL THEN
 INSERT INTO `customers_data_reminders`
 (`customerNumber`, `customers_data_reminders_timestamp`,`customers_data_reminders_message`)
 VALUES (NEW.customerNumber, CURRENT_TIMESTAMP(2), 'Please rememberto record the client\'s postal code');
 END IF;
 IF NEW.salesRepEmployeeNumber IS NULL THEN
 INSERT INTO `customers_data_reminders`
 (`customerNumber`, `customers_data_reminders_timestamp`,`customers_data_reminders_message`)
 VALUES (NEW.customerNumber, CURRENT_TIMESTAMP(2), 'Please remember to assign a sales representative to the client');
 END IF;
 IF NEW.creditLimit IS NULL THEN
 INSERT INTO `customers_data_reminders`
 (`customerNumber`, `customers_data_reminders_timestamp`, `customers_data_reminders_message`)
 VALUES (NEW.customerNumber, CURRENT_TIMESTAMP(2), 'Please remember to set the client\'s credit limit');
 END IF;
END$$
DELIMITER ;

-- STEP 7
INSERT INTO `customers`
(`customerNumber`, `customerName`, `contactLastName`, `contactFirstName`, `phone`, `addressLine1`, `city`, `country`)
VALUES
('497', 'House of Leather', 'Wambua', 'Gabriel', '+254 720 123 456', '9Agha Khan Walk', 'Nairobi', 'Kenya');

SELECT
 *
FROM
 customers_data_reminders;

DELETE FROM `customers` WHERE `customerNumber` = '497';

INSERT INTO `customers`
(`customerNumber`, `customerName`, `contactLastName`, `contactFirstName`,`phone`, `addressLine1`, `city`, `country`, `salesRepEmployeeNumber`)
VALUES
('497', 'House of Leather', 'Wambua', 'Gabriel', '+254 720 123 456', '9Agha Khan Walk', 'Nairobi', 'Kenya', 1401);
UPDATE `customers` SET `postalCode` = '00100' WHERE `customerNumber` =
'497';
SELECT
 *
FROM
 customers_data_reminders;
 

-- step 8
CREATE TABLE part (
 part_no VARCHAR(18) PRIMARY KEY,
 part_description VARCHAR(255),
 part_supplier_tax_PIN VARCHAR (11) CHECK (part_supplier_tax_PIN REGEXP '^[A-Z]{1}[0-9]{9}[A-Z]{1}$'),
 part_supplier_email VARCHAR (55),
 part_buyingprice DECIMAL(10,2 ) NOT NULL CHECK (part_buyingprice >= 0),
 part_sellingprice DECIMAL(10,2) NOT NULL,
 CONSTRAINT CHK_part_sellingprice_GT_buyingprice CHECK
(part_sellingprice >= part_buyingprice),
 CONSTRAINT CHK_part_valid_supplier_email CHECK (part_supplier_email REGEXP '^[a-zA-Z0-9]{3,}@[a-zA-Z0-9]{1,}\\.[a-zA-Z0-9.]{1,}$')
);

-- step 9 
DELIMITER //
CREATE TRIGGER TRG_BEFORE_UPDATE_ON_part
BEFORE UPDATE ON part FOR EACH ROW
BEGIN
 DECLARE errorMessage VARCHAR(255);
 DECLARE EXIT HANDLER FOR SQLSTATE '45000'
 BEGIN
 RESIGNAL SET MESSAGE_TEXT = errorMessage;
 END;

 SET errorMessage = CONCAT('The new selling price of ',
NEW.part_sellingprice, ' cannot be 2 times greater than the current selling
price of ', OLD.part_sellingprice);
 IF NEW.part_sellingprice > OLD.part_sellingprice * 2 THEN
 SIGNAL SQLSTATE '45000';
 END IF;
END//
DELIMITER ;
-- STEP 10
INSERT INTO `part` (`part_no`, `part_description`, `part_supplier_tax_PIN`,
`part_supplier_email`, `part_buyingprice`, `part_sellingprice`)
VALUES ('001', 'The tyres of a 1958 Chevy Corvette Limited Edition',
'P05120157U', 'toysRus@gmail', '100', '50');

INSERT INTO `part` (`part_no`, `part_description`, `part_supplier_tax_PIN`,
`part_supplier_email`, `part_buyingprice`, `part_sellingprice`)
VALUES ('001', 'The tyres of a 1958 Chevy Corvette Limited Edition',
'P051201576U', 'toysRus@gmail', '100', '100');

INSERT INTO `part` (`part_no`, `part_description`, `part_supplier_tax_PIN`,
`part_supplier_email`, `part_buyingprice`, `part_sellingprice`)
VALUES ('001', 'The tyres of a 1958 Chevy Corvette Limited Edition',
'P051201576U', 'toysRus@gmail.com', '100', '100');
UPDATE `part` SET `part_sellingprice` = '250.00' WHERE (`part_no` = '001');


SHOW TRIGGERS;


