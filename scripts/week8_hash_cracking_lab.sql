-- DBAS 1020 - Week 8 (Class 2) Lab: Crack a Leaked Password Table - With SQL
-- You'll play the attacker against an OLD app that stored unsalted SHA-256
-- hashes, then see why salts and slow hashes (bcrypt) shut the same attack down.
-- Then you'll log in as the login app's own account and find its limits.
--
-- BEFORE YOU START
--   * You ran scripts/week8_secure_login_setup.sql (Class 1), and
--   * you registered at least TWO accounts at http://localhost/week8_login/
--     that use the SAME password (e.g. alice and bob, both  correct-horse-battery).
--
-- HOW TO RUN
--   PARTS 1-5 and 7: MySQL Workbench connected as root on 127.0.0.1:13306.
--   PART 6: a NEW Workbench connection as login_app (instructions in PART 6).
--   Run one statement at a time (Ctrl+Enter) and compare with "You should see".
--   When you reach a  >>> CHAT  line, post your answer in the class chat.
--
--   Prefer the command line? PART 1 runs fine from PowerShell:
--     Get-Content scripts\week8_hash_cracking_lab.sql | docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword
--   (that runs the WHOLE file, top to bottom - good for checking, not for learning)
--
-- Stuck? Re-run PART 1. Done? PART 7 removes the lab tables.


-- =====================================================================
-- PART 1 - SETUP: A "LEAKED" TABLE AND A WORDLIST (run all at once)
-- =====================================================================
USE secure_login;
DROP TABLE IF EXISTS leaked_old_app, leaked_salted_app, wordlist;

-- An old app that did it WRONG: one fast hash, no salt.
CREATE TABLE leaked_old_app (
    username      VARCHAR(30) PRIMARY KEY,
    password_sha  CHAR(64)    NOT NULL      -- SHA2(password, 256)
);
INSERT INTO leaked_old_app VALUES
('mtremblay', SHA2('password123',      256)),
('sleblanc',  SHA2('Halifax2026',      256)),
('kmacdonald',SHA2('qwerty',           256)),
('jpoirier',  SHA2('password123',      256)),
('dcormier',  SHA2('iloveyou',         256)),
('agallant',  SHA2('Tr0ub4dor&3',      256)),
('nlandry',   SHA2('password123',      256)),
('rarsenault',SHA2('my dog ate 3 lobsters at Peggys Cove', 256));

-- The attacker's wordlist. Real ones (rockyou.txt) have 14 million entries.
CREATE TABLE wordlist (word VARCHAR(100) PRIMARY KEY);
INSERT INTO wordlist VALUES
('123456'),('password'),('password123'),('qwerty'),('iloveyou'),('letmein'),
('admin'),('welcome'),('monkey'),('dragon'),('football'),('Halifax2026'),
('Summer2026!'),('Tr0ub4dor&3'),('sunshine'),('princess'),('trustno1');

SELECT COUNT(*) AS leaked_rows FROM leaked_old_app;   -- You should see 8
SELECT COUNT(*) AS words       FROM wordlist;         -- You should see 17


-- =====================================================================
-- PART 2 - CRACK IT WITH ONE JOIN
-- =====================================================================
-- Hash every word ONCE, then match those hashes against the leak.
-- This is a precomputed lookup - a "rainbow table" in miniature.
SELECT l.username, w.word AS cracked_password
FROM leaked_old_app l
JOIN wordlist w ON SHA2(w.word, 256) = l.password_sha
ORDER BY l.username;
-- You should see 7 rows. Every password that is IN the wordlist falls.
--
-- >>> CHAT 1: Only one user survived. Who, and why? And agallant's password
--     Tr0ub4dor&3 looks "complex" - why did it fall anyway?


-- =====================================================================
-- PART 3 - THE LEAK GIVES AWAY EVEN MORE: DUPLICATES
-- =====================================================================
-- No salt means the same password always gives the same hash.
-- You don't even need a wordlist to see who shares a password:
SELECT password_sha, COUNT(*) AS users_sharing, GROUP_CONCAT(username) AS who
FROM leaked_old_app
GROUP BY password_sha
HAVING COUNT(*) > 1;
-- You should see 1 row: 3 users share a hash (mtremblay, jpoirier, nlandry).
-- Crack one, you've cracked all three.


-- =====================================================================
-- PART 4 - ADD A SALT. DOES THE JOIN STILL WORK?
-- =====================================================================
-- Same users, same passwords, but each user now gets a random salt that is
-- stored right next to the hash (that's normal - the salt is not a secret).
DROP TABLE IF EXISTS leaked_salted_app;
CREATE TABLE leaked_salted_app (
    username      VARCHAR(30) PRIMARY KEY,
    salt          CHAR(16)    NOT NULL,
    password_sha  CHAR(64)    NOT NULL      -- SHA2(CONCAT(salt, password), 256)
);
-- (Real salts come from a secure random generator; these are typed in so
--  everyone's results match.)
INSERT INTO leaked_salted_app (username, salt, password_sha) VALUES
('mtremblay', '9f2c41ab07de5531', SHA2(CONCAT('9f2c41ab07de5531', 'password123'), 256)),
('sleblanc',  '4be81d0c66a2f90e', SHA2(CONCAT('4be81d0c66a2f90e', 'Halifax2026'), 256)),
('kmacdonald','c03a7e5519bd4f82', SHA2(CONCAT('c03a7e5519bd4f82', 'qwerty'), 256)),
('jpoirier',  '71d9e2b8a04c3f66', SHA2(CONCAT('71d9e2b8a04c3f66', 'password123'), 256)),
('dcormier',  'e5b0136fd28a9c47', SHA2(CONCAT('e5b0136fd28a9c47', 'iloveyou'), 256)),
('agallant',  '2a68f4c19e0b7d35', SHA2(CONCAT('2a68f4c19e0b7d35', 'Tr0ub4dor&3'), 256)),
('nlandry',   'b8c5097e3f1a26d4', SHA2(CONCAT('b8c5097e3f1a26d4', 'password123'), 256)),
('rarsenault','06fe3db2c7894a1b', SHA2(CONCAT('06fe3db2c7894a1b', 'my dog ate 3 lobsters at Peggys Cove'), 256));

SELECT * FROM leaked_salted_app ORDER BY username;
-- Look at mtremblay, jpoirier and nlandry: same password, three different hashes.

-- 4.1  The PART 2 attack, unchanged:
SELECT l.username, w.word
FROM leaked_salted_app l
JOIN wordlist w ON SHA2(w.word, 256) = l.password_sha;
-- You should see 0 rows. The precomputed hashes are useless now.

-- 4.2  The PART 3 duplicate check, unchanged:
SELECT password_sha, COUNT(*) FROM leaked_salted_app GROUP BY password_sha HAVING COUNT(*) > 1;
-- You should see 0 rows. Shared passwords are hidden.

-- 4.3  But the attacker can read the salt too. So: try every word WITH each user's salt.
SELECT l.username, w.word AS cracked_password
FROM leaked_salted_app l
JOIN wordlist w ON SHA2(CONCAT(l.salt, w.word), 256) = l.password_sha
ORDER BY l.username;
-- You should see the SAME 7 rows as PART 2.
--
-- >>> CHAT 2: So what did the salt actually buy us? (Hint: compare how many
--     SHA2() calls PART 2 needed with how many 4.3 needed.)


-- =====================================================================
-- PART 5 - NOW LOOK AT THE BCRYPT HASHES YOUR APP STORED
-- =====================================================================
SELECT username,
       LEFT(password_hash, 4)          AS algorithm,
       SUBSTRING(password_hash, 5, 2)  AS cost,
       SUBSTRING(password_hash, 8, 22) AS salt,
       SUBSTRING(password_hash, 30)    AS hash,
       LENGTH(password_hash)           AS len
FROM users
ORDER BY username;
-- You should see $2y$, cost 10, a different 22-char salt per row, length 60.
-- Your two same-password users have completely different hashes.
--
-- Try to repeat PART 4.3 against these: MySQL has no bcrypt() function, so you
-- can't. An attacker would use a GPU cracking rig instead - and bcrypt is
-- deliberately slow on those too. Open http://localhost/week8_hash_lab.php and
-- compare the SHA-256 time with the bcrypt time.
--
-- >>> CHAT 3: SHA-256 took about ____ ms and bcrypt cost 10 took about ____ ms.
--     Roughly how many times slower is bcrypt? Why is slow GOOD here?


-- =====================================================================
-- PART 6 - EXPLORE THE APP'S ACCOUNT: WHAT CAN login_app DO?
-- =====================================================================
-- First, as root, read its grants again:
SHOW GRANTS FOR 'login_app'@'%';
-- GRANT USAGE ON *.* TO `login_app`@`%`
-- GRANT SELECT, INSERT, UPDATE (`last_login_at`) ON `secure_login`.`users` TO `login_app`@`%`
--
-- Now open a NEW Workbench connection:
--   Hostname 127.0.0.1   Port 13306   Username login_app   Password Login-App-Week8!
--   Default Schema secure_login
-- Run each line below IN THAT CONNECTION and write down what happens.
-- (Copy them over, or open this file in that tab. Don't run them as root.)
--
--   6.1  SELECT USER(), CURRENT_USER();
--          -> login_app@172.x.x.x   login_app@%
--   6.2  SHOW DATABASES;
--          -> only information_schema, performance_schema, secure_login
--   6.3  SHOW TABLES;
--          -> only users. The leaked_* tables are invisible to this account.
--   6.4  SELECT id, username, last_login_at FROM users;
--          -> works
--   6.5  UPDATE users SET last_login_at = NOW() WHERE username = 'alice';
--          -> works (the one column it may change)
--   6.6  UPDATE users SET password_hash = 'hacked' WHERE username = 'alice';
--          -> ERROR 1143: UPDATE command denied ... for column 'password_hash'
--   6.7  DELETE FROM users WHERE username = 'alice';
--          -> ERROR 1142: DELETE command denied to user 'login_app'@'172.x.x.x' for table 'users'
--   6.8  DROP TABLE users;
--          -> ERROR 1142: DROP command denied ...
--   6.9  SELECT * FROM appdb.contacts;
--          -> ERROR 1142: SELECT command denied ... for table 'contacts'
--   6.10 SELECT * FROM leaked_old_app;
--          -> ERROR 1142: SELECT command denied ... for table 'leaked_old_app'
--
-- >>> CHAT 4: Suppose the login page had a SQL injection hole (Week 7). Name
--     two things from 6.6-6.10 an attacker STILL couldn't do, and why.
-- >>> CHAT 5: The app has SELECT on password_hash. Does it need it? What would
--     break without it? (This is exactly the kind of question Week 9 is about.)


-- =====================================================================
-- PART 7 - CLEAN UP (as root)
-- =====================================================================
USE secure_login;
DROP TABLE IF EXISTS leaked_old_app, leaked_salted_app, wordlist;
SHOW TABLES;   -- You should see only: users
