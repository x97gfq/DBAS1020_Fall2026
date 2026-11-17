-- DBAS 1020 - Week 11 Class 1: Backup & Restore Lab - SETUP
-- Builds a small throwaway database called bookshop, then prints the numbers you
-- will compare AFTER you back it up, destroy it and restore it.
--
-- HOW TO RUN (pick one)
--   PowerShell (Windows):
--     Get-Content scripts\week11_backup_setup.sql | docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword
--   bash / macOS:
--     docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword < scripts/week11_backup_setup.sql
--   MySQL Workbench: connect as root to 127.0.0.1:13306, open this file, run it all.
--
-- Safe to re-run: it drops and rebuilds bookshop every time. Nothing else is touched.
-- The full lab (backup -> disaster -> restore -> verify) is in the course notes and
-- on the slides. The verify script is scripts/week11_backup_verify.sql.


-- =====================================================================
-- PART 1 - BUILD THE DATABASE
-- =====================================================================
DROP DATABASE IF EXISTS bookshop;
CREATE DATABASE bookshop;
USE bookshop;

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(60)  NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    city        VARCHAR(40)  NOT NULL
);

CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title   VARCHAR(100) NOT NULL,
    author  VARCHAR(60)  NOT NULL,
    price   DECIMAL(6,2) NOT NULL
);

CREATE TABLE orders (
    order_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT  NOT NULL,
    order_date  DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id INT NOT NULL,
    book_id  INT NOT NULL,
    qty      INT NOT NULL,
    PRIMARY KEY (order_id, book_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (book_id)  REFERENCES books(book_id)
);

INSERT INTO customers (name, email, city) VALUES
('Ava Doucette',   'ava@example.com',   'Halifax'),
('Liam MacLeod',   'liam@example.com',  'Truro'),
('Noor Haddad',    'noor@example.com',  'Dartmouth'),
('Owen Boudreau',  'owen@example.com',  'Sydney');

INSERT INTO books (title, author, price) VALUES
('Anne of Green Gables',        'L. M. Montgomery',  12.99),
('The Shipping News',           'Annie Proulx',      18.50),
('Barometer Rising',            'Hugh MacLennan',    16.00),
('Fall on Your Knees',          'Ann-Marie MacDonald', 21.95),
('No Great Mischief',           'Alistair MacLeod', 19.25);

INSERT INTO orders (customer_id, order_date) VALUES
(1, '2026-11-02'), (2, '2026-11-03'), (1, '2026-11-09'), (3, '2026-11-12');

INSERT INTO order_items (order_id, book_id, qty) VALUES
(1, 1, 2), (1, 3, 1),
(2, 2, 1),
(3, 4, 1), (3, 5, 1), (3, 1, 1),
(4, 5, 3);


-- =====================================================================
-- PART 2 - THE "BEFORE" PICTURE (write these down or screenshot them)
-- =====================================================================
SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'books',       COUNT(*) FROM books
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
-- You should see 4, 5, 4, 7.

SELECT SUM(oi.qty * b.price) AS total_sales
FROM order_items oi JOIN books b ON b.book_id = oi.book_id;
-- You should see 172.42

CHECKSUM TABLE customers, books, orders, order_items;
-- A checksum is a fingerprint of a table's contents. Write the four numbers down.
-- After the restore they must match exactly - that is how you PROVE the backup worked.


-- =====================================================================
-- PART 3 - WHAT'S NEXT (run these in your terminal, not in MySQL)
-- =====================================================================
-- 1. BACK UP   (the file lands in the backups\ folder of your repo)
--      docker exec dbsec-lamp-db sh -c "mysqldump -uroot -prootpassword --single-transaction --databases bookshop > /backups/bookshop.sql"
-- 2. DISASTER
--      docker exec dbsec-lamp-db mysql -uroot -prootpassword -e "DROP DATABASE bookshop"
-- 3. RESTORE
--      docker exec dbsec-lamp-db sh -c "mysql -uroot -prootpassword < /backups/bookshop.sql"
-- 4. VERIFY
--      Get-Content scripts\week11_backup_verify.sql | docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword
