CREATE TABLE Product (
                         PID varchar(100) PRIMARY KEY,
                         Pname varchar(100) NOT NULL,
                         Brand varchar(100),
                         SupplierID int,
                         CostPrice decimal(5,2),
                         UnitPrice decimal(5,2),
                         MinimumStockLevel int,
                         FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

CREATE TABLE Warehouse (
                           WID int PRIMARY KEY,
                           WName varchar(100) NOT NULL,
                           WAddress varchar(255) NOT NULL
);

-- Create Supplier table (optional)
CREATE TABLE Supplier (
                          SupplierID int PRIMARY KEY NOT NULL,
                          SupplierName varchar(100) NOT NULL,
                          SupplierContact varchar(255),
                          SupplierAddress varchar(255)
);

-- Improved Inventory table (separated from Warehouse)
CREATE TABLE Product_Warehouse (
                                   WID int ,
                                   PID varchar(100) ,
                                   Quantity int NOT NULL,
                                   LastUpdatedDate VARCHAR(200),
                                   LastUpdatedTime VARCHAR(200),
                                   Status varchar(100) ,
                                   FOREIGN KEY(WID) REFERENCES Warehouse(WID),
                                   FOREIGN KEY(PID) REFERENCES Product(PID),
                                   PRIMARY KEY (WID, PID)
);


-- Create Order table
CREATE TABLE Product_Order (
                               OrderID int PRIMARY KEY,
                               WID int ,
                               PID varchar(100) ,
                               SupplierID int ,
                               FOREIGN KEY(WID) REFERENCES Warehouse(WID),
                               FOREIGN KEY(PID) REFERENCES Product(PID),
                               FOREIGN KEY(SupplierID) REFERENCES Supplier(SupplierID) ,
                               OrderDate date NOT NULL,
                               OrderQuantity int
);

CREATE TABLE Type (
                      TID int,
                      TName varchar (100),
                      PRIMARY KEY (TID)
);

-- Improved Product_category table (reduced redundancy)
CREATE TABLE Product_Category (
                                  PID varchar(100) ,
                                  TID int ,
                                  FOREIGN KEY(PID) REFERENCES Product(PID),
                                  FOREIGN KEY (TID) REFERENCES Type(TID),
                                  PRIMARY KEY (PID, TID)
);

-- Improved In_transition table (renamed, uses separate source and destination)
CREATE TABLE Product_Transfer (  -- Renamed for clarity
                                  SourceWID int,
                                  DestinationWID int ,
                                  PID varchar(100) ,
                                  TransferDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  TransferQuantity int NOT NULL,
                                  FOREIGN KEY(SourceWID) REFERENCES Warehouse(WID),
                                  FOREIGN KEY(DestinationWID) REFERENCES Warehouse(WID),
                                  FOREIGN KEY(PID) REFERENCES Product(PID),
                                  PRIMARY KEY (SourceWID, DestinationWID, PID, TransferDate)  -- Composite key
);

CREATE TABLE Export(
                       WID int,
                       PID varchar(100),
                       EID varchar(100),
                       ExportQuantity int,
                       ExportDate date,
                       PRIMARY KEY(EID),
                       FOREIGN KEY(PID) REFERENCES Product(PID),
                       FOREIGN KEY (WID) REFERENCES Warehouse(WID)
);

-- CREATE TRIGGER TO UPDATE THE CurrentQuantity in table Product_Warehouse
CREATE OR REPLACE FUNCTION update_product_warehouse_quantity_when_re_order()
    RETURNS trigger AS $$
DECLARE Old_Quantity int;
    DECLARE Sold_Quantity int;
BEGIN
    IF tg_op = 'UPDATE' THEN
BEGIN
SELECT quantity INTO Old_Quantity FROM Product_Warehouse WHERE PID = NEW.PID AND WID = NEW.WID;
EXCEPTION WHEN NO_DATA_FOUND THEN   RAISE EXCEPTION 'Product not found in warehouse. Update or insert required.';
END;
UPDATE Product_Warehouse
SET LastUpdated = current_timestamp,
    Quantity = Old_Quantity + NEW.Quantity
WHERE PID = NEW.PID AND WID = NEW.WID;
END IF;
RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_warehouse_quantity
    AFTER UPDATE ON Product_Warehouse
    FOR EACH ROW
    EXECUTE PROCEDURE update_product_warehouse_quantity_when_re_order();


-- CREATE TRIGGER TO UPDATE THE STATUS AND  THE LAST DATE TO UPDATE TO Product_Warehouse table
CREATE OR REPLACE FUNCTION update_product_warehouse_status()
    RETURNS trigger AS $$
BEGIN
    IF NEW.Quantity <= 0 THEN
UPDATE Product_Warehouse
SET status = 'Out of Stock', LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(NOW(),'HH24:MI:SS')

WHERE PID = NEW.PID AND WID = NEW.WID;
ELSEIF NEW.Quantity < (SELECT minimumStockLevel FROM Product WHERE Product.PID = NEW.PID) THEN
UPDATE Product_Warehouse
SET status = 'Low Stock' , LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(NOW(),'HH24:MI:SS')

WHERE PID = NEW.PID AND WID = NEW.WID;
ELSE
UPDATE Product_Warehouse
SET status = 'In Stock', LastUpdatedDate = to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT', 'DD/MM/YYYY') ,LastUpdatedTime = to_char(NOW(),'HH24:MI:SS')
WHERE PID = NEW.PID AND WID = NEW.WID;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_warehouse_status
    AFTER INSERT ON Product_Warehouse
    FOR EACH ROW
    EXECUTE PROCEDURE update_product_warehouse_status();


--DROP TRIGGER trigger_update_warehouse_status ON product_warehouse

-- CREATE TRIGGER TO DELETE the corresponding the number of Product has been orderd by customer from the table Product_Warehouse.

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD001', 'T-Shirt', 'Brand X', 101, 5.99, 9.99, 20);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD002', 'Jeans', 'Brand Y', 102, 14.99, 24.99, 10);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD003', 'Laptop', 'Brand Z', 103, 499.99, 749.99, 5);

INSERT INTO Product (PID, Pname, Brand, SupplierID, CostPrice, UnitPrice, MinimumStockLevel)
VALUES ('PRD004', 'Coffee Mug', 'Brand M', 104, 2.99, 4.99, 30);



-- insert warehosue
INSERT INTO Warehouse (WID, WName, WAddress)
VALUES (1, 'Main Warehouse', '123 Main St, Anytown, CA 12345');

INSERT INTO Warehouse (WID, WName, WAddress)
VALUES (2, 'West Coast Warehouse', '456 Elm St, Los Angeles, CA 54321');


-- insert supplier
INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (101, 'Clothing Company', 'sales@clothingcompany.com', '789 Maple St, New York, NY 98765');

INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (102, 'Jeans Manufacturer', 'info@jeansmanufacturer.com', '012 Oak St, Chicago, IL 87654');

INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (103, 'Electronics Wholesaler', 'orders@electronicswholesaler.com', '345 Pine St, Houston, TX 76543');

INSERT INTO Supplier (SupplierID, SupplierName, SupplierContact, SupplierAddress)
VALUES (104, 'Mugs Inc.', 'customerservice@mugsinc.com', '678 Birch St, Miami, FL 65432');


-- insert product_warehouse
INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (1, 'PRD001', 100 );

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (1, 'PRD002', 50);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (1, 'PRD004', 200);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (2, 'PRD003', 15);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (2, 'PRD004', 15);

INSERT INTO Product_Warehouse (WID, PID, Quantity)
VALUES (2, 'PRD002', 0);


-- Insert data assuming an order from Warehouse 2 for Laptop (PRD003) from Supplier 103, dated 2024-04-04 with a quantity of 10
INSERT INTO Product_Order (OrderID, WID, PID, SupplierID, OrderDate, OrderQuantity)
VALUES (1, 2, 'PRD003', 103, '2024-04-04', 10);

-- Insert more data following the same format, replacing values with your specific orders
INSERT INTO Product_Order (OrderID, WID, PID, SupplierID, OrderDate, OrderQuantity)
VALUES (2, 1, 'PRD001', 101, '2024-04-06', 25);

-- ... and so on

SELECT * FROM Product_Warehouse


              -- TEST TIME FOR Time update Product_Warehouse table
-- SELECT NOW() AT TIME ZONE 'GMT+7'
-- SELECT LOCALTIMESTAMP(5) AT TIME ZONE 'GMT+7'
-- select date_trunc('second', LOCALTIMESTAMP(2) AT TIME ZONE 'GMT+7')
-- SELECT to_char(date_trunc('second', LOCALTIMESTAMP AT TIME ZONE 'GMT+7'), 'DD/MM/YYYY') AS truncated_datetime;
-- SELECT to_char(LOCALTIMESTAMP AT TIME ZONE 'GMT+7', 'DD/MM/YYYY HH24:MI:SS') AS current_datetime;


              -- Insert data for Clothing categoryee
              -- INSERT TO Type table
INSERT INTO Type (TID, TName)
VALUES (1, 'Clothing');

-- Insert data for Electronics category
INSERT INTO Type (TID, TName)
VALUES (2, 'Electronics');

-- Insert more data for other product categories as needed
INSERT INTO Type (TID, TName)
VALUES (3, 'Kitchenware');

INSERT INTO Type(TID, TName)
VALUES (4,'Education');
-- ... and so on

-- INSERT INTO Product_Category table
-- Link T-Shirt (PRD001) to Clothing category (TID 1)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD001', 1);

-- Link Jeans (PRD002) to Clothing category (TID 1)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD002', 4);

-- Link Laptop (PRD003) to Electronics category (TID 2)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD003', 2);

-- Link Coffee Mug (PRD004) to Kitchenware category (assuming TID 3 exists)
INSERT INTO Product_Category (PID, TID)
VALUES ('PRD004', 3);

--huy

-- ... and so on, linking products to their corresponding categories
-- count all of type
SELECT COUNT(*) AS total_types
FROM Type;

-- COUNT ALL OF TYPE BASED ON THE PRODUCT THAT WAREHOUSE HAS
SELECT COUNT(DISTINCT T.TID) AS total_tids_in_warehouse_1
FROM Product_Warehouse PW
         INNER JOIN Product_Category PC ON PW.PID = PC.PID
         INNER JOIN Type T ON PC.TID = T.TID
WHERE PW.WID = 1;


-- SELECT ALL THE PRODUCT WITH STATUS IS ' LOW STOCK '
SELECT PID, Quantity,Status
FROM Product_Warehouse
WHERE COALESCE(Status, '') = 'Low Stock';

SELECT * FROM Product_Warehouse


                  TRUNCATE TABLE Product_Warehouse;
DROP TRIGGER trigger_update_warehouse_status ON Product_Warehouse;

-- CREATE TRIGGER
CREATE OR REPLACE PROCEDURE update_status_after_update(NEWPID varchar(100) , NewWID int, NEWQuantity int)
    LANGUAGE plpgsql
as $$
DECLARE CurrentQuantity int;
BEGIN
SELECT Product_Warehouse.Quantity INTO CurrentQuantity FROM Product_Warehouse WHERE PID = NEWPID AND Product_Warehouse.WID = NEWWID;
IF CurrentQuantity+NEWQuantity <= 0 THEN
UPDATE Product_Warehouse
SET status = 'Out of Stock', LastUpdated = CURRENT_TIMESTAMP
WHERE PID = NEWPID AND WID = NEWWID;
ELSEIF CurrentQuantity+NEWQuantity < (SELECT minimumStockLevel FROM Product WHERE Product.PID = NEWPID) THEN
UPDATE Product_Warehouse
SET status = 'Low Stock' , LastUpdated = CURRENT_TIMESTAMP, Quantity = NEWQuantity
WHERE PID = NEWPID AND WID = NEWWID;
ELSE
UPDATE Product_Warehouse
SET status = 'In Stock', LastUpdated = CURRENT_TIMESTAMP,Quantity = NEWQuantity
WHERE PID = NEWPID AND WID = NEWWID;
END IF;
COMMIT;
END; $$;



call update_status_after_update('PRD004' , 2 , 40);


DROP PROCEDURE update_status_after_update(NEWPID varchar(100), NewWID int, NEWQuantity int)