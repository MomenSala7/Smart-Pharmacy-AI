CREATE TABLE Product (
    id INT PRIMARY KEY,
    brand_name VARCHAR(100),
    category VARCHAR(100),
    unit_price DECIMAL(10,2)
);

select * FROM product

INSERT INTO Product (id, brand_name, category, unit_price)
VALUES (1, 'Tears Guard', 'eye drops', 254 );


INSERT INTO Product (id, brand_name, category, unit_price)
VALUES (2, 'Digest-Eze', 'digestive enzyme', 314 ),
       (3, 'Mebo', 'antiseptic cream', 24 ),
       (4, 'Zymogen', 'digestive enzyme', 332 ),
       (5, 'Digest-Eze', 'digestive enzyme', 299 ),
       (6, 'Zyrtec', 'allergy pills', 389 );