-- DBAS 1020 - Week 5 (Thursday) Lab: CRUD Practice
-- Practise INSERT, SELECT, UPDATE and DELETE on the Steam library,
-- then the missing WHERE, transactions, and SQL injection.
-- Run in MySQL Workbench connected as root (port 13306).
--
-- HOW TO RUN
--   1. Run PART 1 (setup) in one go: select it all, Ctrl+Shift+Enter.
--   2. Do the exercises IN ORDER. Write your SQL on the blank lines
--      under each exercise, then run it (Ctrl+Enter).
--   3. After each exercise, run the CHECK query and compare with
--      "You should see". If it doesn't match, fix it before moving on.
--   4. When you reach a  >>> CHAT  line, post your answer in the class chat.
--
-- Stuck? Re-run PART 1 to start over. It only touches the steam_lab schema.


-- =====================================================================
-- PART 1 - SETUP (run all at once)
-- =====================================================================
DROP DATABASE IF EXISTS steam_lab;
CREATE DATABASE steam_lab;
USE steam_lab;

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

-- buy_game: a purchase that catches its own errors (used in Exercise 7.3).
-- If anything fails, the EXIT HANDLER rolls the whole purchase back.
DROP PROCEDURE IF EXISTS buy_game;
DELIMITER $$
CREATE PROCEDURE buy_game(IN p_user_id INT, IN p_game_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Purchase FAILED - nothing was changed' AS result;
    END;

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

SET SQL_SAFE_UPDATES = 1;
SELECT 'steam_lab ready' AS status;


-- =====================================================================
-- PART 2 - READ (SELECT)
-- =====================================================================
USE steam_lab;

-- 2.1  Show every column of every game.
--      You should see: 8 rows




-- 2.2  Show the title and price of games that cost LESS THAN $20,
--      cheapest first.
--      You should see: 4 rows, starting with Counter-Strike 2 (0.00)
--      and ending with Balatro (19.99)




-- 2.3  Show the username and wallet of the 3 users with the MOST money.
--      HINT: ORDER BY ... DESC, then LIMIT
--      You should see: mochi_dev 100.00, nullptr_nate 40.00, pixelpanda 25.00




-- >>> CHAT: Which game is the 2nd cheapest?


-- =====================================================================
-- PART 3 - CREATE (INSERT)
-- Always name your columns. Never type an id; AUTO_INCREMENT does that.
-- =====================================================================

-- 3.1  Add YOURSELF as a user. Pick a username (lowercase, no spaces).
--      You live in Canada (country_id 1) and have $50.00 in your wallet.




--      CHECK (put your username in):
--      SELECT * FROM users WHERE username = 'yourname';
--      You should see: 1 row, country_id 1, wallet 50.00
--      Write down your user_id here:  ______  (you'll need it later)

-- >>> CHAT: Post your username and user_id.


-- 3.2  Valve (developer_id 3) is adding 'Half-Life 2' for $9.99. Add it.




--      CHECK:  SELECT * FROM game WHERE title = 'Half-Life 2';
--      You should see: 1 row. Write down its game_id:  ______


-- 3.3  Add a new developer: 'Supergiant Games', from the USA (country_id 2).




--      CHECK:  SELECT * FROM developer WHERE developer_name = 'Supergiant Games';
--      You should see: developer_id 7


-- 3.4  Supergiant Games (developer_id 7) has three games. Add all three
--      with ONE INSERT statement (one VALUES list with three rows):
--          Hades       27.99
--          Hades II    32.99
--          Bastion     16.99




--      CHECK:  SELECT * FROM game WHERE developer_id = 7;
--      You should see: 3 rows
--      CHECK:  SELECT COUNT(*) FROM game;
--      You should see: 12


-- =====================================================================
-- PART 4 - UPDATE
-- The habit: SELECT first with the same WHERE. Then change SELECT * to UPDATE.
-- =====================================================================

-- 4.1  Portal 2 (game_id 5) is on sale for $4.99.
--      Step A: SELECT the row you're about to change.
--      Step B: UPDATE it, using the SAME WHERE.
--      You should see in the Output panel: 1 row(s) affected




--      Now run your UPDATE a SECOND time and read the Output panel.
-- >>> CHAT: What does "Rows matched / Changed" say the second time? Why?


-- 4.2  Add $25.00 to YOUR wallet. Don't type 75.00: compute it from
--      the old value (SET wallet = wallet + ...). Use your user_id.




--      CHECK:  SELECT username, wallet FROM users WHERE user_id = <your id>;
--      You should see: 75.00


-- 4.3  You moved to the UK (country_id 3). Update your row.




--      CHECK:  same SELECT as 4.2 plus country_id. You should see: 3


-- =====================================================================
-- PART 5 - DELETE
-- =====================================================================

-- 5.1  Half-Life 2 is being removed from the store. Delete it using its
--      game_id (from 3.2). SELECT it first!
--      You should see in the Output panel: 1 row(s) affected




--      CHECK:  SELECT COUNT(*) FROM game;
--      You should see: 11


-- 5.2  Try to delete the user pixelpanda (user_id 1). It will FAIL.
--      Read the error message in the Output panel.




-- >>> CHAT: What's the error number, and in a few words, why did it fail?


-- =====================================================================
-- PART 6 - THE MISSING WHERE
-- =====================================================================

-- 6.1  Run this UPDATE exactly as written. Read the error.
--          UPDATE users SET wallet = 0;
--      You should see: Error 1175 (safe update mode)




-- 6.2  Safe updates is a Workbench setting. Real apps don't have it.
--      Run these lines ONE AT A TIME. Look at the damage, then undo it:
--          SET SQL_SAFE_UPDATES = 0;
--          START TRANSACTION;
--          UPDATE users SET wallet = 0;
--          SELECT username, wallet FROM users;
--          ROLLBACK;
--          SET SQL_SAFE_UPDATES = 1;




--      CHECK:  SELECT username, wallet FROM users;
--      You should see: the wallets are back (yours is 75.00)

-- >>> CHAT: How many rows did the UPDATE say it affected? (Hint: not 9. Why?)


-- =====================================================================
-- PART 7 - TRANSACTIONS
-- =====================================================================

-- 7.1  Buy Hades (game_id 10, $27.99) for yourself. Two changes, both or neither:
--          START TRANSACTION;
--          take 27.99 off your wallet          (UPDATE users ...)
--          add the game to your library         (INSERT INTO ownership (user_id, game_id, price_paid) ...)
--          SELECT your wallet to check it       (should be 47.01)
--          COMMIT;




--      CHECK:  SELECT * FROM ownership WHERE user_id = <your id>;
--      You should see: 1 row, game_id 10, price_paid 27.99


-- 7.2  Try to buy Baldur's Gate 3 (game_id 4, $89.99). You can't afford it.
--      Do it in THIS order so you can see what happens:
--          START TRANSACTION;
--          INSERT the ownership row first      (this works)
--          UPDATE the wallet second            (this FAILS: Error 3819)
--          SELECT * FROM ownership WHERE user_id = <your id>;   <-- look!
--      The failed UPDATE was undone. Is the INSERT still there?
--      Finish the job: type ROLLBACK; and run the SELECT again.




--      You should see after ROLLBACK: only Hades in your library, wallet 47.01

-- >>> CHAT: After the error but BEFORE ROLLBACK, how many games did you own?


-- 7.3  Let the database catch the error for you.
--      buy_game() wraps a purchase in a transaction and rolls back on ANY error.
--          CALL buy_game(<your id>, 4);    -- Baldur's Gate 3 again: can't afford
--          CALL buy_game(<your id>, 12);   -- Bastion, $16.99: can afford




--      You should see: "Purchase FAILED - nothing was changed", then "Purchase complete"
--      CHECK:  SELECT username, wallet FROM users WHERE user_id = <your id>;
--      You should see: 30.02

-- >>> CHAT: Post your final wallet.


-- 7.4  Your final library (just run it, joins are coming in a later week):
--          SELECT u.username, g.title, o.price_paid
--          FROM ownership o
--          JOIN users u ON u.user_id = o.user_id
--          JOIN game g  ON g.game_id = o.game_id
--          WHERE o.user_id = <your id>;
--      You should see: Hades 27.99 and Bastion 16.99


-- =====================================================================
-- PART 8 - SQL INJECTION (in your browser)
-- =====================================================================
-- Make sure Docker is running (docker compose up -d --build), then open:
--     http://localhost/week5_injection.php
-- The page shows the exact SQL it sends to MySQL. Read it every time.
--
-- 8.1  UNSAFE mode. Search for:  Smith          You should see: 1 contact
-- 8.2  Search for:  O'Brien                     You should see: a MySQL error. Why?
-- 8.3  Search for:  zzz' OR 1=1 #              You should see: all 5 contacts
--      (Nobody is called zzz. Why did everyone come back?)
-- 8.4  Delete contact by id:  0 OR 1=1          You should see: 5 row(s) deleted
-- 8.5  Click "Reset contacts". Switch to SAFE mode. Try 8.2, 8.3 and 8.4 again.
--      Compare the SQL shown on the page with what you saw in UNSAFE mode.
--
-- >>> CHAT: In SAFE mode, what does the page show instead of your input
--           inside the SQL?
