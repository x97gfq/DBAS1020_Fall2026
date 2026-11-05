-- DBAS 1020 - Week 9 (Tuesday) Demo: User Privileges, Roles & Responsibilities
-- Live demos for the lecture. Run in MySQL Workbench connected as root (port 13306).
--
-- HOW TO RUN
--   Run one statement at a time (Ctrl+Enter) and read the result before moving on.
--   Every demo account starts with  w9_  so it never collides with the Thursday lab
--   (web_app, web_reporter) or Assignment 4 (pos_admin, pos_app, pos_reporter).
--
-- Stuck? Run PART 7 (clean up) and start again. It only removes the w9_ accounts.


-- =====================================================================
-- PART 0 - WHO AM I, AND WHO ELSE IS THERE?
-- =====================================================================
SELECT USER(), CURRENT_USER();
-- USER()         = who you said you were, and where you came from
-- CURRENT_USER() = the account row MySQL actually matched you to

SELECT user, host FROM mysql.user ORDER BY user, host;
-- You should see root twice (root@% and root@localhost) - two DIFFERENT accounts -
-- plus appuser@%, the account every PHP page in www/ has used all term.


-- =====================================================================
-- PART 1 - WHAT CAN OUR APP DO RIGHT NOW?
-- =====================================================================
SHOW GRANTS FOR 'appuser'@'%';
-- You should see:
--   GRANT USAGE ON *.* TO `appuser`@`%`               <- USAGE means "can log in", nothing else
--   GRANT ALL PRIVILEGES ON `appdb`.* TO `appuser`@`%`
--
-- ALL PRIVILEGES includes DROP, ALTER, CREATE and TRUNCATE. The contacts page only
-- ever reads. If an attacker finds an injection hole in it (Week 7), they inherit
-- ALL of that. That is the blast radius we are about to shrink.


-- =====================================================================
-- PART 2 - A USER IS (username, host)
-- =====================================================================
-- Same name, two hosts, two passwords = two completely separate accounts.
CREATE USER 'w9_demo'@'localhost' IDENTIFIED BY 'Local-Only-Pass1!';
CREATE USER 'w9_demo'@'%'         IDENTIFIED BY 'Anywhere-Pass2!';

SELECT user, host FROM mysql.user WHERE user = 'w9_demo';
-- You should see 2 rows.

-- Now try it: make a NEW Workbench connection as w9_demo on 127.0.0.1:13306.
--   * Password Local-Only-Pass1!  -> Access denied
--   * Password Anywhere-Pass2!    -> works
-- Why? Workbench reaches MySQL through Docker, so MySQL sees you arriving from the
-- Docker gateway (something like 172.17.0.1), NOT from localhost. Only the @'%' row
-- matches. Run this in that new connection to prove it:
--     SELECT USER(), CURRENT_USER();
--     -> w9_demo@172.17.0.1    w9_demo@%

DROP USER 'w9_demo'@'localhost';
DROP USER 'w9_demo'@'%';


-- =====================================================================
-- PART 3 - FOUR SCOPES: SERVER, DATABASE, TABLE, COLUMN
-- =====================================================================
CREATE USER 'w9_server'@'%'   IDENTIFIED BY 'Scope-Server-1!';
CREATE USER 'w9_database'@'%' IDENTIFIED BY 'Scope-Database-2!';
CREATE USER 'w9_table'@'%'    IDENTIFIED BY 'Scope-Table-3!';
CREATE USER 'w9_column'@'%'   IDENTIFIED BY 'Scope-Column-4!';

-- Server-wide: every database on this server, now and in the future.
GRANT SELECT ON *.* TO 'w9_server'@'%';

-- One database: every table in appdb, including tables created later.
GRANT SELECT ON appdb.* TO 'w9_database'@'%';

-- One table.
GRANT SELECT ON appdb.contacts TO 'w9_table'@'%';

-- Specific columns: names and emails, but not phone numbers.
GRANT SELECT (first_name, last_name, email) ON appdb.contacts TO 'w9_column'@'%';

SHOW GRANTS FOR 'w9_server'@'%';
SHOW GRANTS FOR 'w9_database'@'%';
SHOW GRANTS FOR 'w9_table'@'%';
SHOW GRANTS FOR 'w9_column'@'%';
-- Read the ON clause of each: *.*  ->  appdb.*  ->  appdb.contacts  ->  (columns) appdb.contacts

-- Try it as w9_column (new Workbench connection, password Scope-Column-4!):
--     SELECT first_name, last_name FROM appdb.contacts;   -- works
--     SELECT COUNT(*) FROM appdb.contacts;                -- works
--     SELECT * FROM appdb.contacts;
--       -> ERROR 1143: SELECT command denied ... for column 'id' in table 'contacts'
--     SELECT * FROM appdb.users;
--       -> ERROR 1142: SELECT command denied ... for table 'users'
--     SHOW TABLES FROM appdb;                             -- only contacts is listed!


-- =====================================================================
-- PART 4 - GRANT, SHOW GRANTS, REVOKE
-- =====================================================================
CREATE USER 'w9_app'@'%' IDENTIFIED BY 'Demo-App-Pass5!';

-- Exactly what a CRUD app needs: read and change ROWS. Nothing that changes TABLES.
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'w9_app'@'%';
SHOW GRANTS FOR 'w9_app'@'%';

-- As w9_app (password Demo-App-Pass5!), these work:
--     SELECT * FROM appdb.contacts;
--     UPDATE appdb.contacts SET phone = phone WHERE id = 1;
-- ...and these are refused:
--     DROP TABLE appdb.contacts;      -> ERROR 1142: DROP command denied
--     TRUNCATE TABLE appdb.contacts;  -> ERROR 1142: DROP command denied  (TRUNCATE needs DROP!)
--     CREATE TABLE appdb.x (id INT);  -> ERROR 1142: CREATE command denied
--     CREATE USER 'evil'@'%';         -> ERROR 1227: you need the CREATE USER privilege

-- Take one privilege back.
REVOKE DELETE ON appdb.* FROM 'w9_app'@'%';
SHOW GRANTS FOR 'w9_app'@'%';
-- You should see:  GRANT SELECT, INSERT, UPDATE ON `appdb`.* ...

-- NOTE: no FLUSH PRIVILEGES needed. GRANT, REVOKE, CREATE USER and DROP USER update
-- the server's in-memory copy themselves. FLUSH PRIVILEGES is only for when someone
-- edits the mysql.* tables directly with INSERT/UPDATE - which you should not do.
--
-- NOTE 2: a session that is ALREADY connected can keep a database-level privilege
-- until it reconnects (or runs USE again). New connections are refused at once.
-- To cut someone off right now: REVOKE (or lock) and then end their session.
SHOW PROCESSLIST;          -- find their connection Id
-- KILL <Id>;


-- =====================================================================
-- PART 5 - ROLES: A NAMED BUNDLE OF PRIVILEGES
-- =====================================================================
CREATE ROLE 'w9_writer';
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'w9_writer';

CREATE USER 'w9_app2'@'%' IDENTIFIED BY 'Demo-App2-Pass6!';
GRANT 'w9_writer' TO 'w9_app2'@'%';

SHOW GRANTS FOR 'w9_app2'@'%';
-- Only shows:  GRANT `w9_writer`@`%` TO `w9_app2`@`%`   - the role, not what's in it.
SHOW GRANTS FOR 'w9_app2'@'%' USING 'w9_writer';
-- Expands the role, so you can see the actual privileges.

-- THE GOTCHA. Log in as w9_app2 (password Demo-App2-Pass6!) right now and try:
--     SELECT CURRENT_ROLE();                   -> NONE
--     SELECT * FROM appdb.contacts;            -> ERROR 1142: SELECT command denied
-- The role is GRANTED but not ACTIVE. A role does nothing until it is switched on.

SET DEFAULT ROLE 'w9_writer' TO 'w9_app2'@'%';
-- Reconnect as w9_app2:
--     SELECT CURRENT_ROLE();                   -> `w9_writer`@`%`
--     SELECT * FROM appdb.contacts;            -> works

-- Why bother? Change the role once and every user who has it changes too.
-- Ten app servers, one role, one GRANT to update.

-- Under the hood, a role is just a locked account that can't log in:
SELECT user, host, account_locked FROM mysql.user WHERE user LIKE 'w9_%';


-- =====================================================================
-- PART 6 - FINDING THE FIVE MISTAKES ON A REAL SERVER
-- =====================================================================
-- 1. Is any app connecting as root?  Look at who is connected right now.
SELECT user, host, db, command FROM information_schema.processlist;

-- 2. Shared accounts?  One login, many people - you cannot tell them apart in a log.
--    (There is no query for this one. You find it by asking "who uses this account?")

-- 3. Old employees still have valid logins?  Every account, and whether it's locked:
SELECT user, host, account_locked, password_last_changed
FROM mysql.user
ORDER BY password_last_changed;
--    Offboarding, in order of preference:
--      DROP USER 'someone'@'%';                  -- gone for good
--      ALTER USER 'someone'@'%' ACCOUNT LOCK;    -- kept, but can't log in
--                                                   (error 3118: Account is locked)

-- 4. Read-only users with write privileges "just in case"?
SELECT grantee, table_schema, privilege_type
FROM information_schema.schema_privileges
WHERE privilege_type IN ('INSERT','UPDATE','DELETE','DROP','ALTER')
ORDER BY grantee;

-- 5. Passwords over plain TCP? Is this connection encrypted?
SHOW SESSION STATUS LIKE 'Ssl_cipher';
-- An empty Value means this connection is NOT encrypted. We fix that later in the term.


-- =====================================================================
-- PART 7 - CLEAN UP (removes every w9_ account and role)
-- =====================================================================
DROP USER IF EXISTS 'w9_demo'@'localhost', 'w9_demo'@'%',
                    'w9_server'@'%', 'w9_database'@'%', 'w9_table'@'%', 'w9_column'@'%',
                    'w9_app'@'%', 'w9_app2'@'%';
DROP ROLE IF EXISTS 'w9_writer';

SELECT user, host FROM mysql.user WHERE user LIKE 'w9_%';
-- You should see: 0 rows.
