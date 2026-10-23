-- DBAS 1020 - Assignment 3, Part B ANSWER KEY: users_fixed.sql
-- Instructor copy. Passwords stored with PHP password_hash() (bcrypt, $2y$).
--
-- Use with login_fixed.php, which verifies via password_verify().
-- Load the same way as users.sql (see vulnerable_login/README.md):
--   docker compose down -v && docker compose up -d --build
--   or: docker exec -i dbsec-lamp-db mysql -uroot -prootpassword appdb < initdb/users_fixed.sql

USE appdb;

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50)  NOT NULL,
    password VARCHAR(255) NOT NULL,   -- a bcrypt hash from password_hash(), ~60 chars
    role     VARCHAR(20)  NOT NULL DEFAULT 'user'
);

-- Bcrypt hashes generated with password_hash($pw, PASSWORD_DEFAULT).
-- Plaintext (for grading/testing only - never ships in a real app):
--   admin=S3cur3Admin!2026  jsymonds=lighthouse99  rbourque=bluenose!
--   ccollins=halifax1749    ajohnson=sunflower22   bsmith=p@ssw0rd
INSERT INTO users (username, password, role) VALUES
('admin',    '$2y$10$86pz8MnVEVlbo3DoLUgxp.0IGGP.QwO4HPuHUifR0nzqkRBHjBeTu', 'admin'),
('jsymonds', '$2y$10$R06IeC1kw.gG.tAVZ6T48OdPZc.6NzPmsnXIq0seObgNGcnN6lYK2', 'staff'),
('rbourque', '$2y$10$yJw5FLK6q.X7FdS0YL1d.ePCeXWlbUYGQ8E72ll5SImkb8a4hOxBa', 'staff'),
('ccollins', '$2y$10$2HemnNBl0pzQPqZb.Y9bv.FJN8I3LhAGn5Ua2ITroEURol/pAw8WS', 'user'),
('ajohnson', '$2y$10$pABG3QqVuSSc0GZt1PPgeuSbohFoPzuoRXBF4U7FKofKzezCG5G/i', 'user'),
('bsmith',   '$2y$10$Y.ymjXgguBkJnF4QBRWJFuf8kAtvVRJuROtlS7hMQ/qJP8B4Am29y', 'user');

-- A student may instead seed hashes from their own PHP (password_hash) - any
-- valid bcrypt hash that password_verify() accepts earns the marks. The exact
-- hash strings will differ every time because bcrypt salts randomly; that's fine.

SELECT id, username, role FROM users ORDER BY id;   -- 6 rows, admin first
