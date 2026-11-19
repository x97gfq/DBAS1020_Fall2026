-- DBAS 1020 - Week 11 Class 2: How to Make an "Encrypted Column"
-- MySQL has NO encrypted column type. You make the column BINARY and encrypt the
-- value as you write it (AES_ENCRYPT), then decrypt it as you read it (AES_DECRYPT).
-- Builds a throwaway database called encdemo. Nothing else is touched.
--
-- HOW TO RUN (pick one)
--   PowerShell (Windows):
--     Get-Content scripts\week11_encrypted_column.sql | docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword
--   bash / macOS:
--     docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword < scripts/week11_encrypted_column.sql
--   MySQL Workbench: connect as root to 127.0.0.1:13306, open this file, run it all.
--
-- Safe to re-run: it drops and rebuilds encdemo every time. The card numbers are fake.


-- =====================================================================
-- PART 1 - THE TABLE: THE "ENCRYPTED" COLUMN IS JUST VARBINARY
-- =====================================================================
DROP DATABASE IF EXISTS encdemo;
CREATE DATABASE encdemo;
USE encdemo;

CREATE TABLE customers (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60)   NOT NULL,        -- plain text, searchable
    card VARBINARY(64) NOT NULL         -- ciphertext: raw bytes, so BINARY, not VARCHAR
);
-- Size it for the CIPHERTEXT, not the plain value. AES works in 16-byte blocks:
--   bytes = 16 * (FLOOR(plain_length / 16) + 1)
-- A 19-character card number -> 32 bytes. VARBINARY(64) leaves room.


-- =====================================================================
-- PART 2 - WRITE: ENCRYPT ON THE WAY IN
-- =====================================================================
-- The key is in a session variable so it's typed once. In a real app it comes from a
-- key vault / KMS - never hard-coded, never stored in the database it protects.
SET @key = 'Week11-Demo-Key';

INSERT INTO customers (name, card) VALUES
('Ava',  AES_ENCRYPT('4520-1111-2222-3333', @key)),
('Liam', AES_ENCRYPT('4520-9999-8888-7777', @key)),
('Noor', AES_ENCRYPT('4520-1111-2222-3333', @key));   -- same card as Ava, on purpose


-- =====================================================================
-- PART 3 - READ: WHAT A SELECT SHOWS
-- =====================================================================
SELECT id, name, HEX(card) AS card_hex, LENGTH(card) AS bytes FROM customers;
-- You should see 64 hex characters (32 bytes) per row - ciphertext, not the card.
-- A plain  SELECT card  prints the raw bytes as garbage characters, and Workbench shows BLOB.

SELECT id, name, CAST(AES_DECRYPT(card, @key) AS CHAR) AS card FROM customers;
-- You should see the three card numbers - only because you supplied the key.

SELECT id, name, AES_DECRYPT(card, 'wrong-key') AS card FROM customers;
-- You should see NULL for every row. No error - just nothing.


-- =====================================================================
-- PART 4 - THE CATCH: DEFAULT MODE IS ECB
-- =====================================================================
SELECT @@block_encryption_mode;
-- You should see aes-128-ecb. In ECB the same plain value ALWAYS gives the same bytes:

SELECT name, HEX(card) AS card_hex FROM customers ORDER BY card_hex;
-- You should see Ava and Noor with IDENTICAL hex - anyone can tell they share a card
-- without decrypting anything.

SELECT name FROM customers WHERE card = AES_ENCRYPT('4520-1111-2222-3333', @key);
-- You should see Ava and Noor. Handy for lookups - but it is that same leak.


-- =====================================================================
-- PART 5 - BETTER: CBC MODE WITH A RANDOM IV PER ROW
-- =====================================================================
-- A random initialisation vector (IV) makes every encryption different, even of the
-- same value. You must store the IV (it isn't secret) to decrypt later.
SET SESSION block_encryption_mode = 'aes-256-cbc';

CREATE TABLE customers_cbc (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60)   NOT NULL,
    iv   BINARY(16)    NOT NULL,        -- 16 random bytes, stored next to the ciphertext
    card VARBINARY(64) NOT NULL
);

SET @iv1 = RANDOM_BYTES(16), @iv2 = RANDOM_BYTES(16);
INSERT INTO customers_cbc (name, iv, card) VALUES
('Ava',  @iv1, AES_ENCRYPT('4520-1111-2222-3333', @key, @iv1)),
('Noor', @iv2, AES_ENCRYPT('4520-1111-2222-3333', @key, @iv2));

SELECT name, HEX(card) AS card_hex FROM customers_cbc;
-- You should see two DIFFERENT hex strings for the same card (yours will differ every run).

SELECT name, CAST(AES_DECRYPT(card, @key, iv) AS CHAR) AS card FROM customers_cbc;
-- You should see 4520-1111-2222-3333 twice. The trade-off: WHERE card = AES_ENCRYPT(...)
-- no longer works - you can't search what you can't predict.

SET SESSION block_encryption_mode = DEFAULT;


-- =====================================================================
-- PART 6 - WHAT'S IN A DUMP? (run these in your terminal, not in MySQL)
-- =====================================================================
--   docker exec dbsec-lamp-db mysqldump -uroot -prootpassword --hex-blob encdemo customers | Select-String "INSERT"
-- You should see  INSERT INTO `customers` VALUES (1,'Ava',0x30242DAE...),...
-- Ciphertext only - the key is NOT in the dump. Restore it anywhere and it still
-- decrypts with the key. (Without --hex-blob you get _binary '...' with raw bytes.)


-- =====================================================================
-- PART 7 - CLEAN UP (run by hand when you are done)
-- =====================================================================
-- DROP DATABASE IF EXISTS encdemo;
