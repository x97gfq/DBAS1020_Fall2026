-- DBAS 1020 - Week 4 (Thursday) Activity: Raw vs Hardened
-- Same data, same INSERT / UPDATE / DELETE statements, two tables:
--   contacts           - no rules at all (like appdb.contacts from our Docker starter)
--   contacts_hardened  - PRIMARY KEY, NOT NULL, UNIQUE, CHECK, FOREIGN KEY, DEFAULT
-- Run in MySQL Workbench connected as root (port 13306).
--
-- HOW TO RUN
--   1. Run PART 1 (setup) in one go: select it all, Ctrl+Shift+Enter.
--   2. From PART 2 on, run ONE statement at a time (cursor on it, Ctrl+Enter).
--      Every test has an (a) line for contacts and a (b) line for contacts_hardened.
--      Predict the result of both BEFORE you run them.
--   3. Many (b) lines are EXPECTED TO FAIL. Read the error in the Output panel.
--      A failed statement changes nothing: MySQL undoes the whole statement.
--
-- Uses its own schema (contacts_lab), so appdb and steam_library are untouched.
-- Re-run PART 1 any time to reset.


-- =====================================================================
-- PART 1 - SETUP (run all at once)
-- =====================================================================
DROP DATABASE IF EXISTS contacts_lab;
CREATE DATABASE contacts_lab;
USE contacts_lab;

-- Workbench's "safe updates" mode refuses UPDATE/DELETE unless the WHERE uses
-- a key column. The raw table has NO keys, so every UPDATE on it would be
-- blocked (Error 1175). Turn it off for this session only, for the activity.
-- (Safe updates exist to stop the "forgot the WHERE" mistake in Test 8!)
SET SQL_SAFE_UPDATES = 0;

-- Lookup (parent) table for the foreign key. Both contact tables store a
-- province code, but only the hardened one is forced to use a real one.
CREATE TABLE province (
    province_code CHAR(2)     NOT NULL,
    province_name VARCHAR(40) NOT NULL,
    CONSTRAINT pk_province      PRIMARY KEY (province_code),
    CONSTRAINT uq_province_name UNIQUE (province_name)
);

INSERT INTO province (province_code, province_name) VALUES
('NS', 'Nova Scotia'),
('NB', 'New Brunswick'),
('PE', 'Prince Edward Island'),
('NL', 'Newfoundland and Labrador'),
('ON', 'Ontario');

-- ---------- The raw table: every column optional, nothing checked ----------
CREATE TABLE contacts (
    contact_id    INT,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    email         VARCHAR(100),
    phone         VARCHAR(25),
    province_code CHAR(2),
    created_at    DATETIME
);

-- ---------- The hardened table: same columns, every rule enforced ----------
CREATE TABLE contacts_hardened (
    contact_id    INT          NOT NULL,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL,
    phone         VARCHAR(25)  NULL,          -- optional, but if given it must look like a phone
    province_code CHAR(2)      NOT NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_contacts_hardened PRIMARY KEY (contact_id),
    CONSTRAINT uq_ch_email          UNIQUE (email),
    CONSTRAINT chk_ch_first_name    CHECK (first_name <> ''),
    CONSTRAINT chk_ch_last_name     CHECK (last_name <> ''),
    CONSTRAINT chk_ch_email         CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT chk_ch_phone         CHECK (phone REGEXP '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'),
    CONSTRAINT fk_ch_province       FOREIGN KEY (province_code)
                                    REFERENCES province (province_code)
                                    ON DELETE RESTRICT
);

-- Same five good rows in both tables.
INSERT INTO contacts (contact_id, first_name, last_name, email, phone, province_code, created_at) VALUES
(1, 'Jamie', 'Symonds', 'jamie@example.com', '902-555-1001', 'NS', NOW()),
(2, 'Randy', 'Bourque', 'randy@example.com', '902-555-1002', 'NS', NOW()),
(3, 'Craig', 'Collins', 'craig@example.com', '902-555-1003', 'NB', NOW()),
(4, 'Alice', 'Johnson', 'alice@example.com', '902-555-1004', 'PE', NOW()),
(5, 'Bob',   'Smith',   'bob@example.com',   '902-555-1005', 'NS', NOW());

INSERT INTO contacts_hardened (contact_id, first_name, last_name, email, phone, province_code) VALUES
(1, 'Jamie', 'Symonds', 'jamie@example.com', '902-555-1001', 'NS'),
(2, 'Randy', 'Bourque', 'randy@example.com', '902-555-1002', 'NS'),
(3, 'Craig', 'Collins', 'craig@example.com', '902-555-1003', 'NB'),
(4, 'Alice', 'Johnson', 'alice@example.com', '902-555-1004', 'PE'),
(5, 'Bob',   'Smith',   'bob@example.com',   '902-555-1005', 'NS');

-- ---------- Scorecard: counts the garbage in each table ----------
-- A view is a saved SELECT. Run  SELECT * FROM scorecard;  whenever you like.
CREATE VIEW scorecard AS
SELECT 'contacts' AS tbl,
       COUNT(*)                                                AS total_rows,
       COUNT(*) - COUNT(DISTINCT contact_id)                   AS duplicate_ids,
       SUM(email IS NULL OR email NOT LIKE '%_@_%._%')         AS bad_emails,
       COUNT(email) - COUNT(DISTINCT email)                    AS duplicate_emails,
       SUM(last_name IS NULL)                                  AS missing_last_names,
       SUM(phone NOT REGEXP '^[0-9]{3}-[0-9]{3}-[0-9]{4}$')    AS bad_phones,
       SUM(province_code NOT IN (SELECT province_code FROM province)) AS unknown_provinces,
       SUM(created_at IS NULL)                                 AS missing_created_at
FROM contacts
UNION ALL
SELECT 'contacts_hardened',
       COUNT(*),
       COUNT(*) - COUNT(DISTINCT contact_id),
       SUM(email IS NULL OR email NOT LIKE '%_@_%._%'),
       COUNT(email) - COUNT(DISTINCT email),
       SUM(last_name IS NULL),
       SUM(phone NOT REGEXP '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'),
       SUM(province_code NOT IN (SELECT province_code FROM province)),
       SUM(created_at IS NULL)
FROM contacts_hardened;

SELECT * FROM scorecard;   -- both tables clean: 5 rows, all zeros

-- Compare the definitions side by side:
SHOW CREATE TABLE contacts;
SHOW CREATE TABLE contacts_hardened;


-- =====================================================================
-- PART 2 - INSERTS (one statement at a time: predict, then Ctrl+Enter)
-- =====================================================================
USE contacts_lab;
SET SQL_SAFE_UPDATES = 0;   -- again, in case you reconnected

-- ---------- Test 1: PRIMARY KEY - a second "contact 1" ----------
-- EXPECTED (b): Error 1062 Duplicate entry '1' for key 'contacts_hardened.PRIMARY'
INSERT INTO contacts          (contact_id, first_name, last_name, email, phone, province_code)
VALUES (1, 'Eve', 'Imposter', 'eve@example.com', '902-555-6666', 'NS');                       -- (a)
INSERT INTO contacts_hardened (contact_id, first_name, last_name, email, phone, province_code)
VALUES (1, 'Eve', 'Imposter', 'eve@example.com', '902-555-6666', 'NS');                       -- (b)

-- ---------- Test 2: NOT NULL - a contact with no email ----------
-- EXPECTED (b): Error 1048 Column 'email' cannot be null
INSERT INTO contacts          (contact_id, first_name, last_name, email, phone, province_code)
VALUES (6, 'Nora', 'Null', NULL, '902-555-1006', 'NS');                                        -- (a)
INSERT INTO contacts_hardened (contact_id, first_name, last_name, email, phone, province_code)
VALUES (6, 'Nora', 'Null', NULL, '902-555-1006', 'NS');                                        -- (b)

-- ---------- Test 3: UNIQUE - same email, different capitals ----------
-- EXPECTED (b): Error 1062 Duplicate entry 'JAMIE@example.com' for key 'contacts_hardened.uq_ch_email'
-- The default collation is case-insensitive, so JAMIE@ and jamie@ collide.
-- Think: a password reset for jamie@example.com now has two accounts to pick from.
INSERT INTO contacts          (contact_id, first_name, last_name, email, phone, province_code)
VALUES (7, 'Jaime', 'Symons', 'JAMIE@example.com', '902-555-1007', 'NS');                     -- (a)
INSERT INTO contacts_hardened (contact_id, first_name, last_name, email, phone, province_code)
VALUES (7, 'Jaime', 'Symons', 'JAMIE@example.com', '902-555-1007', 'NS');                     -- (b)

-- ---------- Test 4: CHECK - an empty name and a nonsense email ----------
-- EXPECTED (b): Error 3819 Check constraint 'chk_ch_email' is violated.
-- (Also try first_name = '' to trip chk_ch_first_name.)
INSERT INTO contacts          (contact_id, first_name, last_name, email, phone, province_code)
VALUES (8, 'Sam', 'Spammer', 'not-an-email', '902-555-1008', 'NS');                           -- (a)
INSERT INTO contacts_hardened (contact_id, first_name, last_name, email, phone, province_code)
VALUES (8, 'Sam', 'Spammer', 'not-an-email', '902-555-1008', 'NS');                           -- (b)

-- ---------- Test 5: CHECK - a phone number that isn't one ----------
-- EXPECTED (b): Error 3819 Check constraint 'chk_ch_phone' is violated.
INSERT INTO contacts          (contact_id, first_name, last_name, email, phone, province_code)
VALUES (9, 'Carly', 'Jepsen', 'carly@example.com', 'call me maybe', 'ON');                    -- (a)
INSERT INTO contacts_hardened (contact_id, first_name, last_name, email, phone, province_code)
VALUES (9, 'Carly', 'Jepsen', 'carly@example.com', 'call me maybe', 'ON');                    -- (b)

-- ---------- Test 6: FOREIGN KEY - a province that doesn't exist ----------
-- EXPECTED (b): Error 1452 Cannot add or update a child row: a foreign key constraint fails
INSERT INTO contacts          (contact_id, first_name, last_name, email, phone, province_code)
VALUES (10, 'Zed', 'Nowhere', 'zed@example.com', '902-555-1010', 'ZZ');                       -- (a)
INSERT INTO contacts_hardened (contact_id, first_name, last_name, email, phone, province_code)
VALUES (10, 'Zed', 'Nowhere', 'zed@example.com', '902-555-1010', 'ZZ');                       -- (b)

-- ---------- Checkpoint ----------
-- contacts has 11 rows (6 of them bad). contacts_hardened still has 5.
-- Notice created_at: NULL for every new raw row; hardened fills it in by DEFAULT.
SELECT * FROM contacts          ORDER BY contact_id;
SELECT * FROM contacts_hardened ORDER BY contact_id;
SELECT * FROM scorecard;


-- =====================================================================
-- PART 3 - UPDATES (constraints are checked on every change, not just INSERT)
-- =====================================================================

-- ---------- Test 7: NOT NULL on UPDATE - blank out a name ----------
-- EXPECTED (b): Error 1048 Column 'last_name' cannot be null
UPDATE contacts          SET last_name = NULL WHERE contact_id = 2;                           -- (a)
UPDATE contacts_hardened SET last_name = NULL WHERE contact_id = 2;                           -- (b)

-- ---------- Test 8: The forgotten WHERE ----------
-- Someone meant to fix ONE email and forgot the WHERE clause.
-- EXPECTED (a): every row now has Randy's email.
-- EXPECTED (b): Error 1062 Duplicate entry 'randy@example.com' for key 'contacts_hardened.uq_ch_email'
--               and ZERO rows change: a statement is all-or-nothing.
UPDATE contacts          SET email = 'randy@example.com';                                     -- (a)
UPDATE contacts_hardened SET email = 'randy@example.com';                                     -- (b)

SELECT contact_id, first_name, email FROM contacts          ORDER BY contact_id;
SELECT contact_id, first_name, email FROM contacts_hardened ORDER BY contact_id;


-- =====================================================================
-- PART 4 - DELETES
-- =====================================================================

-- ---------- Test 9: "Please delete my data" (contact 1, Jamie) ----------
-- EXPECTED (a): 2 row(s) affected - Jamie AND Eve the imposter from Test 1 share id 1.
-- EXPECTED (b): 1 row(s) affected - exactly one person, because the PK guarantees it.
DELETE FROM contacts          WHERE contact_id = 1;                                           -- (a)
DELETE FROM contacts_hardened WHERE contact_id = 1;                                           -- (b)

-- ---------- Test 10: FOREIGN KEY on the parent side ----------
-- Delete a province that hardened contacts still use.
-- EXPECTED: Error 1451 Cannot delete or update a parent row: a foreign key constraint fails
-- (One province table serves both, so only the hardened rows protect it. If
--  this worked, Randy and Bob would point at a province that no longer exists.)
DELETE FROM province WHERE province_code = 'NS';

-- Nobody uses Ontario in the hardened table, so this one is allowed:
-- DELETE FROM province WHERE province_code = 'ON';


-- =====================================================================
-- PART 5 - FINAL SCORECARD
-- =====================================================================
-- Compare with the checkpoint. Test 8 overwrote every raw email with the
-- same value, so the raw table's damage now looks different, not smaller.
SELECT * FROM scorecard;


-- =====================================================================
-- DISCUSSION - what constraints CAN'T stop (both tables accept these)
-- =====================================================================
-- A perfectly formatted but WRONG email:  UPDATE ... SET email = 'bob@exmaple.com' WHERE contact_id = 5;
-- A typo in a name:                        UPDATE ... SET first_name = 'Bbo'         WHERE contact_id = 5;
-- Deleting everyone:                       DELETE FROM contacts_hardened;   -- no FK points AT contacts, so nothing stops it
-- Constraints guarantee data is VALID, not that it's TRUE. For the rest you need
-- app-side validation, least-privilege accounts, backups, and audit logs.

-- Put safe updates back on when you're done:
SET SQL_SAFE_UPDATES = 1;
