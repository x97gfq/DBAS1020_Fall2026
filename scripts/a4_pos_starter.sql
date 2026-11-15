-- =====================================================================
-- DBAS 1020 - Assignment 4 starter: point-of-sale database
-- Builds the tables AND loads sample data in one run (MySQL 8.4).
--
-- If you need a fresh copy of your database, run this script. It
-- rebuilds the Assignment 2 tables and sample data and adds a payment
-- table, which is the sensitive table for this assignment. Rename
-- pos_firstname to your own first name before running it (see below).
--
-- WHAT'S IN HERE
--   customer, product, `order`, order_item  - same as Assignment 2
--   payment  - NEW: card last-4 digits and processor auth codes.
--              Treat this as the sensitive table for Assignment 4.
--
-- WHO SHOULD SEE WHAT (the grants you will write in users.sql)
--   pos_admin    ALL PRIVILEGES on the whole database
--   pos_app      SELECT, INSERT, UPDATE, DELETE on every table
--   pos_reporter SELECT only, on customer, `order`, order_item and product
--                - enough to build a sales report (who bought what, and
--                  order totals) but NO access to payment.
--   Grant pos_reporter table by table (db.table), not db.*, or it will
--   be able to read payment too.
--
-- BEFORE YOU RUN IT: rename the database to your own first name.
--   Find & Replace  pos_firstname  ->  pos_<yourfirstname>   (e.g. pos_sam)
--   It appears 3 times, all at the top of this file.
--
-- Safe to re-run: it drops and rebuilds the database each time.
-- If you already have a working pos_<firstname> database from
-- Assignment 2, you can keep it - just add the payment table below.
-- =====================================================================

DROP DATABASE IF EXISTS pos_firstname;
CREATE DATABASE pos_firstname;
USE pos_firstname;

-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------

CREATE TABLE customer (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name  VARCHAR(50)  NOT NULL,
  last_name   VARCHAR(50)  NOT NULL,
  email       VARCHAR(100) NULL UNIQUE,
  phone       VARCHAR(20)  NULL
);

CREATE TABLE product (
  product_id   INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(100)  NOT NULL,
  category     VARCHAR(30)   NOT NULL,
  price        DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  qty_in_stock INT           NOT NULL DEFAULT 0 CHECK (qty_in_stock >= 0)
);

-- ORDER is a reserved word, so it is back-ticked everywhere.
CREATE TABLE `order` (
  order_id    INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NULL,                              -- NULL = walk-in sale
  order_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
    REFERENCES customer (customer_id) ON DELETE RESTRICT
);

-- Junction table resolving Order >--< Product.
CREATE TABLE order_item (
  order_id   INT NOT NULL,
  product_id INT NOT NULL,
  quantity   INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL,                 -- price at time of sale
  PRIMARY KEY (order_id, product_id),
  CONSTRAINT fk_item_order   FOREIGN KEY (order_id)   REFERENCES `order` (order_id) ON DELETE CASCADE,
  CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES product (product_id)
);

-- NEW for Assignment 4: a sensitive table.
-- Card details and processor auth codes are exactly the kind of data a
-- read-only reporting account should NOT be able to see.
CREATE TABLE payment (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id   INT NOT NULL,
  method     ENUM('cash','debit','credit') NOT NULL,
  amount     DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  card_last4 CHAR(4)     NULL,                       -- NULL for cash
  auth_code  VARCHAR(20) NULL,                       -- processor approval code
  paid_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES `order` (order_id)
);

-- ---------------------------------------------------------------------
-- Sample data (parents before children so every FK resolves)
-- ---------------------------------------------------------------------

INSERT INTO customer (first_name, last_name, email, phone) VALUES
 ('Ava',   'MacDonald',   'ava.macdonald@example.com',    '902-555-0101'),
 ('Liam',  'Nickerson',   'liam.nickerson@example.com',   '902-555-0102'),
 ('Chloe', 'd''Entremont','chloe.dentremont@example.com', '902-555-0103'),
 ('Noah',  'Smith',       'noah.smith@example.com',       '902-555-0104'),
 ('Emma',  'Atwood',      'emma.atwood@example.com',      NULL),
 ('Owen',  'Crowell',     'owen.crowell@example.com',     '902-555-0106');

INSERT INTO product (name, category, price, qty_in_stock) VALUES
 ('Claw Hammer',         'Hardware',  24.99, 15),
 ('Cordless Drill',      'Hardware', 129.00,  4),
 ('Box of Screws (100)', 'Hardware',   8.49, 60),
 ('Lobster Buoy',        'Marine',    18.75,  7),
 ('Rope 50 ft',          'Marine',    32.00, 12),
 ('Rain Gear Set',       'Marine',    89.99,  3),
 ('Coffee 1 kg',         'Grocery',   17.29, 25),
 ('Maple Syrup 500 ml',  'Grocery',   14.99,  9);

-- Order 6 is a walk-in (no customer).
INSERT INTO `order` (customer_id, order_date) VALUES
 (1,    '2026-10-01 09:15:00'),
 (2,    '2026-10-02 13:40:00'),
 (3,    '2026-10-03 16:05:00'),
 (4,    '2026-10-05 10:30:00'),
 (1,    '2026-10-06 11:20:00'),
 (NULL, '2026-10-08 14:45:00');

INSERT INTO order_item (order_id, product_id, quantity, unit_price) VALUES
 (1, 1, 1,  24.99), (1, 3, 2,   8.49), (1, 7, 1, 17.29),
 (2, 4, 4,  18.75), (2, 5, 2,  32.00),
 (3, 6, 1,  89.99), (3, 8, 2,  14.99),
 (4, 2, 1, 129.00), (4, 3, 3,   8.49),
 (5, 7, 2,  17.29), (5, 8, 1,  14.99),
 (6, 5, 1,  32.00), (6, 1, 1,  24.99);

-- One payment per order; amount = the order's total.
INSERT INTO payment (order_id, method, amount, card_last4, auth_code, paid_at) VALUES
 (1, 'credit',  59.26, '4417', 'AUTH-883104', '2026-10-01 09:16:02'),
 (2, 'debit',  139.00, '0932', 'AUTH-551987', '2026-10-02 13:41:10'),
 (3, 'credit', 119.97, '7720', 'AUTH-209466', '2026-10-03 16:06:45'),
 (4, 'debit',  154.47, '3381', 'AUTH-764015', '2026-10-05 10:31:30'),
 (5, 'cash',    49.57, NULL,   NULL,          '2026-10-06 11:20:40'),
 (6, 'cash',    56.99, NULL,   NULL,          '2026-10-08 14:45:55');

-- ---------------------------------------------------------------------
-- Quick check: every payment should match its order total (diff = 0.00)
-- ---------------------------------------------------------------------
SELECT o.order_id,
       SUM(oi.quantity * oi.unit_price) AS order_total,
       p.amount                         AS paid,
       p.amount - SUM(oi.quantity * oi.unit_price) AS diff
FROM `order` o
JOIN order_item oi ON oi.order_id = o.order_id
JOIN payment    p  ON p.order_id  = o.order_id
GROUP BY o.order_id, p.amount
ORDER BY o.order_id;
