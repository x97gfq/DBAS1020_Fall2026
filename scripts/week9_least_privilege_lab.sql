-- DBAS 1020 - Week 9 (Thursday) Lab: Least Privilege for Your Own App
-- Move the PHP pages in www/ off the all-powerful appuser account and onto a new
-- account that can do exactly what the app needs - and prove the database refuses
-- everything else.
-- Run in MySQL Workbench connected as root (port 13306) unless a step says otherwise.
--
-- HOW TO RUN
--   1. Run PART 1 (setup) in one go: select it all, Ctrl+Shift+Enter.
--   2. Do the parts IN ORDER. Write your SQL on the blank lines under each
--      exercise, then run it (Ctrl+Enter).
--   3. After each exercise, run the CHECK and compare with "You should see".
--      If it doesn't match, fix it before moving on.
--   4. When you reach a  >>> CHAT  line, post your answer in the class chat.
--
-- LAB PASSWORDS. Use these exact passwords so the tester page (PART 6) can log in.
-- They're in a public git repo, so they are NOT secret - never do this for real.
--     web_app       App-Week9-Pass!
--     web_reporter  Report-Week9-Pass!
--
-- Stuck? Re-run PART 1. It removes the lab accounts and leaves your data alone.
-- This lab is the dress rehearsal for Assignment 4: same moves, different database.


-- =====================================================================
-- PART 1 - SETUP (run all at once)
-- =====================================================================
DROP USER IF EXISTS 'web_app'@'%', 'web_reporter'@'%';
DROP ROLE IF EXISTS 'web_writer';

SHOW GRANTS FOR 'appuser'@'%';
-- You should see:  GRANT ALL PRIVILEGES ON `appdb`.* TO `appuser`@`%`
-- That's what every page in www/ connects as today. Time to fix it.


-- =====================================================================
-- PART 2 - CREATE THE APP ACCOUNT
-- =====================================================================
-- 2.1  Create the user web_app, allowed to connect from any host ('%'),
--      with the password App-Week9-Pass!



-- 2.2  Grant web_app the four CRUD privileges on every table in appdb.
--      Nothing else: no CREATE, no DROP, no ALTER.



-- CHECK
SHOW GRANTS FOR 'web_app'@'%';
-- You should see exactly 2 lines:
--   GRANT USAGE ON *.* TO `web_app`@`%`
--   GRANT SELECT, INSERT, UPDATE, DELETE ON `appdb`.* TO `web_app`@`%`
-- >>> CHAT 2.2: what does the USAGE line let web_app do?


-- =====================================================================
-- PART 3 - SWITCH THE APP OVER
-- =====================================================================
-- No SQL here. In VS Code, change the connection line in these two files so they
-- log in as web_app instead of appuser:
--
--   www/index.php            line 2
--   www/week5_injection.php  line 8
--
--   before:  ... "appuser", "apppassword", "appdb");
--   after:   ... "web_app", "App-Week9-Pass!", "appdb");
--
-- Save, then check normal use still works (no rebuild needed - www/ is mounted):
--   3.1  http://localhost/                    the contacts list loads
--   3.2  http://localhost/week5_injection.php search for  Smith  -> 1 contact
--   3.3  same page, SAFE mode on, delete contact id 5         -> 1 row deleted
-- >>> CHAT 3: "all three work" - or the error message if one didn't


-- =====================================================================
-- PART 4 - THE SURPRISE
-- =====================================================================
-- 4.1  On week5_injection.php, click "Reset contacts".
--      It fails:  DROP command denied to user 'web_app'@'...' for table 'contacts'
--      The button doesn't drop anything. Open www/week5_injection.php and find out
--      what statement it runs.
-- >>> CHAT 4.1: which SQL statement needs the DROP privilege, and why?
--
-- 4.2  You have two ways to make Reset work again:
--        (a) GRANT DROP ON appdb.* TO 'web_app'@'%';
--        (b) change the code so it doesn't need DROP
--      Option (a) hands every SQL-injection hole in the app the power to drop tables,
--      so do (b): in www/week5_injection.php, replace
--          TRUNCATE TABLE contacts
--      with
--          DELETE FROM contacts
--      Click Reset again - it works now. (The ids keep counting up from where they
--      were instead of restarting at 1. That's fine.)
-- >>> CHAT 4.2: one sentence on why (b) beats (a)


-- =====================================================================
-- PART 5 - PROVE THE DATABASE SAYS NO
-- =====================================================================
-- Make a NEW Workbench connection:
--     Hostname 127.0.0.1   Port 13306   Username web_app   Password App-Week9-Pass!
-- Run each line below in THAT connection, and take a screenshot of each result.
-- (Assignment 4 asks for exactly this kind of evidence.)
--
--   5.1  SELECT USER(), CURRENT_USER();
--        You should see:  web_app@172.x.x.x   web_app@%
--   5.2  SELECT * FROM appdb.contacts;                               -- allowed
--   5.3  INSERT INTO appdb.contacts (first_name, last_name, email, phone)
--        VALUES ('Lab', 'Test', 'lab@example.com', '902-555-0000');  -- allowed
--   5.4  DROP TABLE appdb.contacts;                                  -- refused
--   5.5  CREATE TABLE appdb.sneaky (id INT);                         -- refused
--   5.6  SELECT user, host FROM mysql.user;                          -- refused
-- >>> CHAT 5: the error NUMBER you got for 5.4


-- =====================================================================
-- PART 6 - SIDE BY SIDE IN THE BROWSER
-- =====================================================================
-- Open http://localhost/week9_privileges.php
-- It logs in as whichever account you pick and tries 10 things, from a plain
-- SELECT up to CREATE USER. Green = allowed, red = refused by MySQL.
--   6.1  Run it as appuser   (password apppassword)
--   6.2  Run it as web_app   (password App-Week9-Pass!)
-- >>> CHAT 6: how many checks went red for web_app? Which ones?


-- =====================================================================
-- PART 7 - A READ-ONLY REPORTING ACCOUNT, DOWN TO THE COLUMN
-- =====================================================================
-- The office manager wants a dashboard of names and emails. Phone numbers stay
-- private, and the users table (password hashes!) is completely off limits.
--
-- 7.1  Create web_reporter@'%' with the password Report-Week9-Pass!



-- 7.2  Grant SELECT on ONLY the first_name, last_name and email columns of
--      appdb.contacts. (Column list goes in brackets right after SELECT.)



-- CHECK
SHOW GRANTS FOR 'web_reporter'@'%';
-- You should see:
--   GRANT SELECT (`email`, `first_name`, `last_name`) ON `appdb`.`contacts` TO `web_reporter`@`%`
--
-- 7.3  On week9_privileges.php, run the checks as web_reporter.
--      SELECT first_name... is green; SELECT * is red (error 1143 - a COLUMN was
--      refused); the users table is red (error 1142 - the whole TABLE was refused).
-- >>> CHAT 7.3: why does SELECT * fail when the reporter can read 3 of the columns?


-- =====================================================================
-- PART 8 - TAKING ACCESS AWAY
-- =====================================================================
-- 8.1  REVOKE web_app's DELETE privilege on appdb.*



-- 8.2  Delete a contact on week5_injection.php. It should fail with
--      "DELETE command denied". (Each page load is a new connection, so the
--      change shows up immediately.)
-- 8.3  Put DELETE back with a GRANT.



-- 8.4  The bookkeeper went on leave. LOCK the web_reporter account (ALTER USER).



-- 8.5  Run week9_privileges.php as web_reporter.
--      You should see: Account is locked (error 3118).
-- 8.6  UNLOCK web_reporter again.



-- >>> CHAT 8: when would you LOCK an account instead of DROP USER?


-- =====================================================================
-- PART 9 - ROLES (stretch - the same idea as the Assignment 4 stretch)
-- =====================================================================
-- Move web_app's privileges into a role so the next app server is one GRANT away.
--
-- 9.1  Create a role named web_writer and give it SELECT, INSERT, UPDATE, DELETE
--      on appdb.*



-- 9.2  Take web_app's direct privileges away (REVOKE all four on appdb.*), then
--      grant the web_writer role to web_app.



-- 9.3  Reload http://localhost/ - it BREAKS: SELECT command denied.
--      Run this as root and look at what web_app actually has:
SHOW GRANTS FOR 'web_app'@'%';
SHOW GRANTS FOR 'web_app'@'%' USING 'web_writer';
-- >>> CHAT 9.3: the role is granted - so why can't the app read anything?
--
-- 9.4  Fix it: make web_writer the DEFAULT role for web_app.



-- 9.5  Reload http://localhost/ - the contacts are back.


-- =====================================================================
-- EXIT TICKET (one chat message)
-- =====================================================================
--   a) The app account you built can't DROP. Name one attack that just got smaller.
--   b) One thing in your own projects that connects with more privilege than it needs.
--
-- Want your original pages back?   git checkout www/index.php www/week5_injection.php
