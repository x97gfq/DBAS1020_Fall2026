-- DBAS 1020 - Week 11 Class 1: Backup & Restore Lab - VERIFY
-- Run this AFTER the restore. Every number must match PART 2 of week11_backup_setup.sql.
--
-- HOW TO RUN (pick one)
--   PowerShell (Windows):
--     Get-Content scripts\week11_backup_verify.sql | docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword
--   bash / macOS:
--     docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword < scripts/week11_backup_verify.sql
--   MySQL Workbench: connect as root to 127.0.0.1:13306, open this file, run it all.
--
-- If you get  ERROR 1049 (42000): Unknown database 'bookshop'  the restore did not run
-- (or you ran this between the DROP and the restore). Go back to step 3.


-- =====================================================================
-- PART 1 - IS EVERYTHING BACK?
-- =====================================================================
USE bookshop;

SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'books',       COUNT(*) FROM books
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
-- You should see 4, 5, 4, 7 - the same as before.

SELECT SUM(oi.qty * b.price) AS total_sales
FROM order_items oi JOIN books b ON b.book_id = oi.book_id;
-- You should see 172.42

CHECKSUM TABLE customers, books, orders, order_items;
-- Same four numbers as before?  Then the restore is PROVEN, not hoped for.


-- =====================================================================
-- PART 2 - DID THE STRUCTURE COME BACK TOO?
-- =====================================================================
SELECT table_name, constraint_name, referenced_table_name
FROM information_schema.referential_constraints
WHERE constraint_schema = 'bookshop'
ORDER BY table_name, constraint_name;
-- You should see 3 foreign keys. A logical dump rebuilds tables, keys and
-- constraints from CREATE TABLE statements - not just the rows.


-- =====================================================================
-- PART 3 - POINT-IN-TIME RECOVERY: THE BINARY LOG
-- =====================================================================
SHOW BINARY LOGS;
-- You should see two or more files named binlog.000001, binlog.000002, ...
-- MySQL 8.4 writes every change to a binary log (binlog) by default.
-- A dump is a snapshot at ONE moment. The binlog records everything AFTER it -
-- including the DROP DATABASE you just ran.
-- Restore the dump, then replay the binlog up to just before the mistake
-- = point-in-time recovery (PITR). Notice the Encrypted column says No.

-- >>> CHAT
-- The dump was taken at 9:00. Someone ran DELETE FROM orders at 14:00.
-- If you ONLY restore the dump, what do you lose?


-- =====================================================================
-- PART 4 - CLEAN UP (optional - only when you are done with the lab)
-- =====================================================================
-- DROP DATABASE IF EXISTS bookshop;
