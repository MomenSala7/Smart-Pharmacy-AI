CREATE TABLE Shipment (
    id INT PRIMARY KEY,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,
    boxes_shipped INT,
    product_id INT,
    customer_id INT,
    shift_id INT,
    season_id INT,
    FOREIGN KEY (product_id) REFERENCES Product(id),
    FOREIGN KEY (customer_id) REFERENCES Customer(id),
    FOREIGN KEY (shift_id) REFERENCES Shift(id),
    FOREIGN KEY (season_id) REFERENCES Season(id)
);

select * from Shipment;

-- بيانات مبدئية للتجربة (Dummy Data)
INSERT INTO Shipment (id, boxes_shipped, product_id, customer_id, shift_id, season_id) VALUES
(1, 2, 1, 1, 1, 2), -- بيع علبتين من دواء 1 للعميل 1 في شيفت 1 موسم 2
(2, 5, 2, 2, 2, 1),
(3, 1, 3, 3, 1, 3);