CREATE TABLE Inventory (
    id INT PRIMARY KEY,
    product_id INT,
    stock_level INT,
    -- عواميد الذكاء الاصطناعي المطلوبة
    min_stock INT DEFAULT 10, 
    daily_usage DECIMAL(5,2) DEFAULT 1.0, 
    lead_time_days INT DEFAULT 3, 
    FOREIGN KEY (product_id) REFERENCES Product(id)
);

select * from inventory;

-- إضافة البيانات مع القيم الجديدة الخاصة بالذكاء الاصطناعي
INSERT INTO Inventory (id, product_id, stock_level, min_stock, daily_usage, lead_time_days) VALUES
(1, 1, 23, 10, 1.5, 3),  -- Product 1
(2, 2, 73, 20, 4.0, 2),  -- Product 2
(3, 3, 37, 10, 2.0, 3),  -- Product 3
(4, 4, 32, 15, 3.5, 5),  -- Product 4
(5, 5, 85, 25, 5.0, 2),  -- Product 5
(6, 6, 24, 10, 1.2, 4);  -- Product 6