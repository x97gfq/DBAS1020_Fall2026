-- DBAS 1020 - Week 5 (Tuesday) Demos: SQL DML - CRUD, WHERE, Transactions
-- Follow along in MySQL Workbench connected as root (port 13306).
--
-- HOW TO RUN
--   1. Run PART 0 (setup) in one go: select it all, Ctrl+Shift+Enter.
--   2. From PART 1 on, run ONE statement at a time (cursor on it, Ctrl+Enter).
--      Before every UPDATE or DELETE, say out loud how many rows you expect.
--      Then check "N row(s) affected" in the Output panel.
--   3. Lines marked EXPECTED: Error ... are meant to fail. Read the error.
--
-- Uses its own schema (steam_dml), so steam_library and appdb are untouched.
-- Re-run PART 0 any time to reset.


-- =====================================================================
-- PART 0 - SETUP (run all at once)
-- Same Steam library as Week 3, plus a wallet balance on each user.
-- =====================================================================
DROP DATABASE IF EXISTS steam_dml;
CREATE DATABASE steam_dml;
USE steam_dml;

CREATE TABLE country (
    country_id   INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE users (
    user_id    INT AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(30) NOT NULL UNIQUE,
    country_id INT NOT NULL,
    wallet     DECIMAL(6,2) NOT NULL DEFAULT 0 CHECK (wallet >= 0),
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);

CREATE TABLE developer (
    developer_id   INT AUTO_INCREMENT PRIMARY KEY,
    developer_name VARCHAR(100) NOT NULL UNIQUE,
    country_id     INT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);

CREATE TABLE game (
    game_id      INT AUTO_INCREMENT PRIMARY KEY,
    title        VARCHAR(100) NOT NULL,
    price        DECIMAL(5,2) NOT NULL CHECK (price >= 0),
    developer_id INT NOT NULL,
    FOREIGN KEY (developer_id) REFERENCES developer(developer_id)
);

CREATE TABLE ownership (
    user_id    INT,
    game_id    INT,
    price_paid DECIMAL(5,2) NOT NULL CHECK (price_paid >= 0),
    hours      INT NOT NULL DEFAULT 0 CHECK (hours >= 0),
    achieved   DECIMAL(5,2) CHECK (achieved BETWEEN 0 AND 100),
    PRIMARY KEY (user_id, game_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (game_id) REFERENCES game(game_id)
);

INSERT INTO country (country_name) VALUES
('Canada'), ('USA'), ('UK'), ('Japan'), ('Belgium');

INSERT INTO users (username, country_id, wallet) VALUES
('pixelpanda',   1,  25.00),
('vexmoth',      1,   0.00),
('saltyhalifax', 1,  12.50),
('grimjoy',      2,   5.00),
('nullptr_nate', 2,  40.00),
('kestrel',      3,  15.00),
('mochi_dev',    4, 100.00),
('brambleweft',  5,   7.25);

INSERT INTO developer (developer_name, country_id) VALUES
('LocalThunk', 1), ('FromSoftware', 4), ('Valve', 2),
('Larian Studios', 5), ('poncle', 3), ('Studio MDHR', 1);

INSERT INTO game (title, price, developer_id) VALUES
('Balatro',           19.99, 1),
('Elden Ring',        79.99, 2),
('Counter-Strike 2',   0.00, 3),
('Baldur''s Gate 3',  89.99, 4),
('Portal 2',          12.49, 3),
('Vampire Survivors',  6.49, 5),
('Elden Ring',        79.99, 2),
('Cuphead',           26.99, 6);

INSERT INTO ownership (user_id, game_id, price_paid, hours, achieved) VALUES
(1, 1, 19.99,  87,  62),
(2, 2, 79.99, 156,  71),
(3, 3,  0.00, 512,   8),
(4, 4, 89.99, 203,  49),
(5, 5,  3.74,  19, 100),
(6, 6,  6.49,  55,  78),
(7, 7, 79.99, 311,  83),
(8, 8, 13.49,  22,  31);

-- Workbench starts with safe updates ON. Make sure it is on for the demos.
SET SQL_SAFE_UPDATES = 1;
SELECT 'steam_dml ready' AS status;


-- =====================================================================
-- PART 1 - READ: SELECT  (the R in CRUD)
-- =====================================================================
USE steam_dml;

SELECT * FROM game;                                  -- every column, every row

SELECT title, price FROM game;                       -- only the columns you need

SELECT title, price FROM game WHERE price < 20;      -- WHERE picks the rows

SELECT title, price FROM game
WHERE price < 20
ORDER BY price DESC;                                 -- sort the result

SELECT username, wallet FROM users
ORDER BY wallet DESC
LIMIT 3;                                             -- top 3 wallets

-- Text needs quotes, numbers don't. A quote inside text is doubled: ''
SELECT * FROM game WHERE title = 'Baldur''s Gate 3';


-- =====================================================================
-- PART 2 - CREATE: INSERT  (the C in CRUD)
-- =====================================================================

-- 2a. Always name the columns. The id is left out: AUTO_INCREMENT fills it.
INSERT INTO country (country_name) VALUES ('Australia');
SELECT LAST_INSERT_ID();                             -- the id MySQL just gave us (6)

-- Leaving out the column list works... until someone adds a column.
-- Then every INSERT written this way breaks (or worse, lands in the wrong column).
-- INSERT INTO country VALUES (7, 'France');         -- don't do this

-- 2b. DEFAULT fills in what you leave out: wallet becomes 0.00
INSERT INTO users (username, country_id) VALUES ('tidepool', 6);
SELECT * FROM users WHERE username = 'tidepool';

-- 2c. Many rows in ONE statement: one round trip, one check, all or nothing.
INSERT INTO developer (developer_name, country_id) VALUES ('Team Cherry', 6);

INSERT INTO game (title, price, developer_id) VALUES
('Hollow Knight',            19.49, 7),
('Hollow Knight: Silksong',  24.99, 7),
('Stardew Valley',           16.99, 3);   -- oops, wrong developer! we fix it in Part 3

SELECT * FROM game;

-- 2d. A multi-row INSERT is ONE statement. One bad row = no rows at all.
-- EXPECTED: Error 3819 Check constraint 'game_chk_1' is violated.
INSERT INTO game (title, price, developer_id) VALUES
('Tunic',     32.99, 3),
('Free Demo', -1.00, 3);                  -- negative price breaks the CHECK

SELECT * FROM game WHERE title = 'Tunic'; -- empty: Tunic was NOT inserted either

-- 2e. Constraints from Week 4 still guard every INSERT.
-- EXPECTED: Error 1062 Duplicate entry 'kestrel' for key 'users.username'
INSERT INTO users (username, country_id) VALUES ('kestrel', 1);
-- EXPECTED: Error 1452 Cannot add or update a child row: a foreign key constraint fails
INSERT INTO users (username, country_id) VALUES ('ghost', 99);


-- =====================================================================
-- PART 3 - UPDATE  (the U in CRUD)
-- The habit: write it as a SELECT first. Check the rows. Then swap the verb.
-- =====================================================================

-- 3a. Stardew Valley is by ConcernedApe, not Valve. Add the developer first.
INSERT INTO developer (developer_name, country_id) VALUES ('ConcernedApe', 2);   -- id 8

-- Step 1: SELECT with the WHERE you plan to use.
SELECT * FROM game WHERE game_id = 11;               -- 1 row: Stardew Valley

-- Step 2: same WHERE, now an UPDATE. Expect: 1 row(s) affected
UPDATE game SET developer_id = 7 WHERE game_id = 11;

SELECT * FROM developer;

-- 3b. Run the same UPDATE twice. Second time: "Rows matched: 1  Changed: 0"
UPDATE game SET price = 14.99 WHERE game_id = 11;
UPDATE game SET price = 14.99 WHERE game_id = 11;

-- 3c. Several columns at once, and a value computed from the old value.
UPDATE users SET wallet = wallet + 10.00, country_id = 1 WHERE user_id = 6;
SELECT * FROM users WHERE user_id = 6;

-- 3d. Constraints guard UPDATE too.
-- EXPECTED: Error 3819 Check constraint 'users_chk_1' is violated.
UPDATE users SET wallet = wallet - 500 WHERE user_id = 6;


-- =====================================================================
-- PART 4 - DELETE  (the D in CRUD)
-- =====================================================================

-- 4a. SELECT first, then DELETE by primary key.
SELECT * FROM users WHERE user_id = 9;               -- tidepool
DELETE FROM users WHERE user_id = 9;                 -- 1 row(s) affected

-- 4b. A parent with children can't be deleted (FK, Week 4).
-- EXPECTED: Error 1451 Cannot delete or update a parent row: a foreign key constraint fails
DELETE FROM users WHERE user_id = 8;                 -- brambleweft owns Cuphead

-- Children first, then the parent:
DELETE FROM ownership WHERE user_id = 8 AND game_id = 8;
DELETE FROM users WHERE user_id = 8;


-- =====================================================================
-- PART 5 - THE MISSING WHERE
-- No WHERE means EVERY row. MySQL won't ask "are you sure?"
-- =====================================================================

-- 5a. Workbench's safe updates mode catches the obvious case.
-- EXPECTED: Error 1175 You are using safe update mode and you tried to update
--           a table without a WHERE that uses a KEY column.
UPDATE game SET price = 0;

-- 5b. Safe updates is a Workbench setting, not a database rule.
-- PHP, Python, the mysql command line... none of them have it on by default.
-- Turn it off and do the damage INSIDE a transaction so we can undo it:
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;
UPDATE game SET price = 0;                           -- 10 row(s) affected (CS2 was already 0). Everything is free!
SELECT title, price FROM game;
ROLLBACK;                                            -- phew
SELECT title, price FROM game;                       -- prices are back
SET SQL_SAFE_UPDATES = 1;

-- 5c. A WHERE that is there but too wide. How many 'Elden Ring' rows?
SELECT * FROM game WHERE title = 'Elden Ring';       -- 2! (the Week 4 duplicate)
-- A name is not a key. Delete or update by the PRIMARY KEY.

-- 5d. The stray semicolon. With Ctrl+Shift+Enter (run all) the first line
--     deletes EVERY ownership row and the second line is a syntax error.
--     Do NOT run this outside a transaction:
--
--     DELETE FROM ownership;  WHERE user_id = 3;
--
SET SQL_SAFE_UPDATES = 0;
START TRANSACTION;
DELETE FROM ownership;                               -- the first "half"
SELECT COUNT(*) FROM ownership;                      -- 0
ROLLBACK;
SELECT COUNT(*) FROM ownership;                      -- 7 again
SET SQL_SAFE_UPDATES = 1;


-- =====================================================================
-- PART 6 - TRANSACTIONS: COMMIT or ROLLBACK
-- =====================================================================

-- 6a. autocommit = 1: every statement is saved the moment it succeeds.
SELECT @@autocommit;

-- 6b. A purchase is TWO changes that must happen together:
--     take money from the wallet AND add the game to the library.
--     mochi_dev (user 7, wallet 100.00) buys Balatro (game 1, 19.99).
START TRANSACTION;
UPDATE users SET wallet = wallet - 19.99 WHERE user_id = 7;
INSERT INTO ownership (user_id, game_id, price_paid) VALUES (7, 1, 19.99);
SELECT username, wallet FROM users WHERE user_id = 7;     -- 80.01 (only WE can see this yet)
COMMIT;                                                   -- now it's permanent

-- 6c. A purchase that can't be paid for. grimjoy (user 4) has 5.00.
--     Order matters to show the gotcha: insert first, pay second.
START TRANSACTION;
INSERT INTO ownership (user_id, game_id, price_paid) VALUES (4, 2, 79.99);
-- EXPECTED: Error 3819 Check constraint 'users_chk_1' is violated.
UPDATE users SET wallet = wallet - 79.99 WHERE user_id = 4;

-- GOTCHA: the failed UPDATE was undone, but the INSERT before it was NOT.
-- MySQL does not roll back the whole transaction for you.
SELECT * FROM ownership WHERE user_id = 4;                -- free Elden Ring!
ROLLBACK;                                                 -- you have to say it
SELECT * FROM ownership WHERE user_id = 4;                -- only Baldur's Gate 3

-- 6d. DDL (CREATE / ALTER / DROP) quietly COMMITs whatever is pending.
START TRANSACTION;
UPDATE users SET wallet = 999.99 WHERE user_id = 2;
CREATE TABLE scratch (x INT);                            -- implicit COMMIT here!
ROLLBACK;                                                -- too late
SELECT username, wallet FROM users WHERE user_id = 2;    -- 999.99 stuck
UPDATE users SET wallet = 0.00 WHERE user_id = 2;        -- fix it by hand
DROP TABLE scratch;

-- 6e. (Optional) Isolation. Open a SECOND connection to the server
--     (Workbench Home tab -> click the connection again), then:
--       Connection A:  START TRANSACTION;
--                      UPDATE game SET price = 1.00 WHERE game_id = 5;
--       Connection B:  SELECT price FROM steam_dml.game WHERE game_id = 5;   -- still 12.49
--       Connection B:  UPDATE steam_dml.game SET price = 2.00 WHERE game_id = 5;  -- waits (row is locked)
--       Connection A:  ROLLBACK;                                              -- B finishes

-- 6f. Catch the error, then ROLLBACK automatically.
--     In 6c WE had to notice the error and type ROLLBACK. Code can do it for us.
--     In SQL that needs a stored procedure (more on those later in the course):
--     an EXIT HANDLER is MySQL's version of try/catch.
--     Select from DELIMITER down to the second DELIMITER and run it (Ctrl+Shift+Enter).
DROP PROCEDURE IF EXISTS buy_game;
DELIMITER $$
CREATE PROCEDURE buy_game(IN p_user_id INT, IN p_game_id INT)
BEGIN
    -- "catch": if ANY statement below fails, jump here
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;                                         -- undo everything since START TRANSACTION
        SELECT 'Purchase FAILED - nothing was changed' AS result;
    END;

    -- "try"
    START TRANSACTION;
    INSERT INTO ownership (user_id, game_id, price_paid)
        SELECT p_user_id, game_id, price FROM game WHERE game_id = p_game_id;
    UPDATE users
        SET wallet = wallet - (SELECT price FROM game WHERE game_id = p_game_id)
        WHERE user_id = p_user_id;
    COMMIT;
    SELECT 'Purchase complete' AS result;
END$$
DELIMITER ;

-- grimjoy (user 4, wallet 5.00) tries to buy Elden Ring (game 2, 79.99).
-- The UPDATE breaks CHECK (wallet >= 0), the handler catches it and rolls back.
CALL buy_game(4, 2);                                       -- Purchase FAILED
SELECT * FROM ownership WHERE user_id = 4;                 -- no Elden Ring this time (compare 6c)
SELECT username, wallet FROM users WHERE user_id = 4;      -- still 5.00

-- nullptr_nate (user 5, wallet 40.00) buys Vampire Survivors (game 6, 6.49).
CALL buy_game(5, 6);                                       -- Purchase complete
SELECT username, wallet FROM users WHERE user_id = 5;      -- 33.51

-- Buying it again fails too: duplicate primary key in ownership. Caught, rolled back.
CALL buy_game(5, 6);                                       -- Purchase FAILED
SELECT username, wallet FROM users WHERE user_id = 5;      -- still 33.51, not charged twice

-- In app code it's the same shape (PHP):
--   $conn->begin_transaction();
--   try {
--       ... UPDATE wallet ... INSERT ownership ...
--       $conn->commit();
--   } catch (mysqli_sql_exception $e) {
--       $conn->rollback();
--       echo "Purchase failed - nothing was changed.";
--   }


-- =====================================================================
-- PART 7 - A FIRST LOOK: WHEN USER INPUT REACHES THE SQL
-- An app builds SQL from what someone typed in a box.
-- We can fake that in pure SQL with a variable and PREPARE.
-- =====================================================================

-- 7a. Concatenation: the input becomes PART OF THE SQL.
SET @input = '3';                                         -- a normal user id
SET @sql = CONCAT('SELECT user_id, username, wallet FROM users WHERE user_id = ', @input);
SELECT @sql;                                              -- look at the finished SQL
PREPARE stmt FROM @sql;  EXECUTE stmt;                    -- 1 row

SET @input = '0 OR 1=1';                                  -- what an attacker types
SET @sql = CONCAT('SELECT user_id, username, wallet FROM users WHERE user_id = ', @input);
SELECT @sql;                                              -- ...WHERE user_id = 0 OR 1=1
PREPARE stmt FROM @sql;  EXECUTE stmt;                    -- EVERY row
-- Now imagine that was  DELETE FROM users WHERE user_id = ...
-- The attacker just removed the WHERE clause. Part 5, on purpose.

-- 7b. Parameter: the SQL is fixed, the input is only ever a VALUE.
PREPARE stmt FROM 'SELECT user_id, username, wallet FROM users WHERE user_id = ?';
SET @input = '3';         EXECUTE stmt USING @input;      -- 1 row
SET @input = '0 OR 1=1';  EXECUTE stmt USING @input;      -- 0 rows: there is no user "0 OR 1=1"
DEALLOCATE PREPARE stmt;

-- The PHP version of this is www/week5_injection.php (slides 27-33, Thursday lab Part 8).
