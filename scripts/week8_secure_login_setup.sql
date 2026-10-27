-- DBAS 1020 - Week 8 (Class 1): Secure Login - database + application account
-- Creates the secure_login database, its users table, and the ONE MySQL account
-- the PHP login app (www/week8_login/) is allowed to connect as.
--
-- HOW TO RUN (pick one) - run as root, because it creates a database and a user.
--
--   PowerShell (Windows), from your DBAS 1020 folder:
--     Get-Content scripts\week8_secure_login_setup.sql | docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword
--
--   Terminal (macOS / Linux / Git Bash), from your DBAS 1020 folder:
--     docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword < scripts/week8_secure_login_setup.sql
--
--   MySQL Workbench: connect as root on 127.0.0.1:13306, open this file,
--     select everything and run it (Ctrl+Shift+Enter).
--
-- The warning "Using a password on the command line interface can be insecure"
-- is MySQL telling you the truth: anyone who can list processes on that machine
-- can see -prootpassword. Fine for a local teaching container. Not fine at work.
--
-- Safe to re-run: it drops and rebuilds everything, which also DELETES any
-- accounts you registered. That's how you start over.


-- =====================================================================
-- PART 1 - THE DATABASE AND TABLE
-- =====================================================================
DROP DATABASE IF EXISTS secure_login;
CREATE DATABASE secure_login CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE secure_login;

CREATE TABLE users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(30)  NOT NULL,
    -- password_hash() output. bcrypt is 60 chars today; PHP recommends 255 so
    -- the column still fits when PASSWORD_DEFAULT moves to a longer algorithm.
    password_hash VARCHAR(255) NOT NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME     NULL,
    -- The DATABASE enforces "no two users with the same name", not the PHP.
    -- The _ci collation means 'Alice' and 'alice' count as the same name.
    CONSTRAINT uq_users_username UNIQUE (username)
);

-- Notice what is NOT here: no password column. There is nothing to decrypt.


-- =====================================================================
-- PART 2 - THE APPLICATION'S OWN ACCOUNT
-- =====================================================================
-- The PHP app does NOT log in as root, and NOT as appuser (which can do anything
-- in appdb). It gets its own account with only what the login app needs:
--
--   register page  -> INSERT a new row
--   login page     -> SELECT the row for a username
--   login page     -> UPDATE last_login_at (and ONLY that column)
--
-- Password is public (it's in a git repo), so it is NOT secret. Never do this for real.
DROP USER IF EXISTS 'login_app'@'%';
CREATE USER 'login_app'@'%' IDENTIFIED BY 'Login-App-Week8!';

GRANT SELECT, INSERT          ON secure_login.users TO 'login_app'@'%';
GRANT UPDATE (last_login_at)  ON secure_login.users TO 'login_app'@'%';


-- =====================================================================
-- PART 3 - CHECK IT
-- =====================================================================
SHOW GRANTS FOR 'login_app'@'%';
-- You should see two lines:
--   GRANT USAGE ON *.* TO `login_app`@`%`
--   GRANT SELECT, INSERT, UPDATE (`last_login_at`) ON `secure_login`.`users` TO `login_app`@`%`
-- (MySQL folds the two GRANT statements into the second line.)
--
-- EXPLORE (Week 9 is all about this):
--   * USAGE ON *.* means "may log in" - nothing else.
--   * There is no DELETE. What happens if the app tries to delete a user?
--   * UPDATE has a column list. Could the app change someone's password_hash?
--   * The grant is on ONE table, not secure_login.* - what about a new table?

DESCRIBE users;
SELECT COUNT(*) AS users_so_far FROM users;
-- You should see 0. Go to http://localhost/week8_login/ and register someone.
