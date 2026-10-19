-- DBAS 1020 - Week 7: users table for the SQL Injection attack lab.
-- Seeds the login that www/week7_login.php authenticates against.
--
-- New containers run every file in initdb/ automatically on first start.
-- If your container already exists, run this file by hand instead:
--   docker exec -i dbsec-lamp-db mysql -uroot -prootpassword appdb < initdb/02_users.sql
-- or paste it into MySQL Workbench (connected as root on port 13306).

USE appdb;

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50)  NOT NULL,
    password VARCHAR(64)  NOT NULL,   -- a SHA-256 hash, NOT the plain password
    role     VARCHAR(20)  NOT NULL DEFAULT 'user'
);

-- The password column stores SHA-256 hashes, the way a real app would.
-- Nobody can log in by typing these 64-character strings, so the normal
-- login always fails - which is the whole point of the lab: you get in
-- WITHOUT knowing the password, by rewriting the query.
INSERT INTO users (username, password, role) VALUES
('admin',    SHA2('S3cur3Admin!2026', 256), 'admin'),
('jsymonds', SHA2('lighthouse99',     256), 'staff'),
('rbourque', SHA2('bluenose!',        256), 'staff'),
('ccollins', SHA2('halifax1749',      256), 'user'),
('ajohnson', SHA2('sunflower22',      256), 'user'),
('bsmith',   SHA2('p@ssw0rd',         256), 'user');

-- Quick check: you should see 6 rows, and the admin row first.
SELECT id, username, role FROM users ORDER BY id;
