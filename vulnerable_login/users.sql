-- DBAS 1020 - Assignment 3: users table for the vulnerable login (users.sql).
--
-- Drop this file into   ~/dbas1020/initdb/   then rebuild the containers.
-- Files in initdb/ run automatically the first time the database volume is
-- created. See HOW TO RUN below.

USE appdb;

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50)  NOT NULL,
    password VARCHAR(64)  NOT NULL,   -- a SHA-256 hash, NOT the plain password
    role     VARCHAR(20)  NOT NULL DEFAULT 'user'
);

-- Passwords are stored as SHA-256 hashes, the way a basic app might. Nobody
-- can log in by typing a 64-character hash, so the normal login always fails -
-- which is exactly why Part A matters: you get in WITHOUT the password by
-- rewriting the query.
INSERT INTO users (username, password, role) VALUES
('admin',    SHA2('S3cur3Admin!2026', 256), 'admin'),
('jsymonds', SHA2('lighthouse99',     256), 'staff'),
('rbourque', SHA2('bluenose!',        256), 'staff'),
('ccollins', SHA2('halifax1749',      256), 'user'),
('ajohnson', SHA2('sunflower22',      256), 'user'),
('bsmith',   SHA2('p@ssw0rd',         256), 'user');

-- Quick check: 6 rows, admin first.
SELECT id, username, role FROM users ORDER BY id;

-- ===================================================================
-- HOW TO RUN THIS FILE
-- ===================================================================
-- Option A - clean rebuild (simplest; drops ALL data and re-seeds):
--     docker compose down -v
--     docker compose up -d --build
--   A fresh volume re-runs every .sql in initdb/, including this one.
--
-- Option B - load it into the running container without wiping anything:
--     docker exec -i dbsec-lamp-db mysql -uroot -prootpassword appdb < initdb/users.sql
--
-- Option C - MySQL Workbench: connect as root on localhost:13306,
--   open this file, and run it (Ctrl+Shift+Enter).
-- ===================================================================
