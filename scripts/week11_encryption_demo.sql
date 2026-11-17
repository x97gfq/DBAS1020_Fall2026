-- DBAS 1020 - Week 11 Class 1: Encryption at Rest, in Transit, and Why Hashing Isn't Encryption
-- Builds a throwaway database called cryptodemo. Nothing else is touched.
--
-- HOW TO RUN (pick one)
--   PowerShell (Windows):
--     Get-Content scripts\week11_encryption_demo.sql | docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword
--   bash / macOS:
--     docker exec -i dbsec-lamp-db mysql -t -uroot -prootpassword < scripts/week11_encryption_demo.sql
--   MySQL Workbench (best for this one): connect as root to 127.0.0.1:13306 and run
--     one statement at a time (Ctrl+Enter).
--
-- The script STOPS at PART 5 with ERROR 3185. That is on purpose - read PART 5.
-- The card numbers below are fake.


-- =====================================================================
-- PART 1 - THE SAME CARD NUMBER, STORED TWO WAYS
-- =====================================================================
DROP DATABASE IF EXISTS cryptodemo;
CREATE DATABASE cryptodemo;
USE cryptodemo;

CREATE TABLE cards_plain (
    id   INT PRIMARY KEY,
    card VARCHAR(30) NOT NULL              -- plain text
);

CREATE TABLE cards_enc (
    id   INT PRIMARY KEY,
    card VARBINARY(64) NOT NULL            -- encrypted bytes, so BINARY, not VARCHAR
);

INSERT INTO cards_plain VALUES (1, '4520-1111-2222-3333');
INSERT INTO cards_enc   VALUES (1, AES_ENCRYPT('4520-1111-2222-3333', 'Week11-Demo-Key'));

SELECT id, card FROM cards_plain;
SELECT id, HEX(card) AS card_hex FROM cards_enc;
-- You should see the readable number, then 64 hex characters of gibberish:
--   30242DAE656D681C821EB9235334B3C43984756B35D7EF17FFF123B95D792153


-- =====================================================================
-- PART 2 - ENCRYPTION IS TWO-WAY (IF YOU HAVE THE KEY)
-- =====================================================================
SELECT CAST(AES_DECRYPT(card, 'Week11-Demo-Key') AS CHAR) AS right_key,
       AES_DECRYPT(card, 'wrong-key')                     AS wrong_key
FROM cards_enc;
-- You should see:  right_key = 4520-1111-2222-3333    wrong_key = NULL
-- The data is only as safe as the key. Notice where the key is right now: typed
-- into the query, so it is in your script, your app's source and maybe a log file.
-- Real systems keep keys in a key vault / KMS, away from the data.


-- =====================================================================
-- PART 3 - HASHING IS ONE-WAY (THERE IS NO "UNHASH")
-- =====================================================================
SELECT SHA2('4520-1111-2222-3333', 256) AS hash1,
       SHA2('4520-1111-2222-3333', 256) = SHA2('4520-1111-2222-3333', 256) AS same_input_same_hash;
-- You should see 3ab30d36d6bde26647e8e8fa79ee4673ed3526beb81d84f6684dd048e04303aa  and 1
-- There is no SHA2_DECRYPT. You can only hash a guess and compare (Week 8).
--   Passwords -> HASH them   (the app never needs the password back)
--   Card numbers, health card numbers -> ENCRYPT them   (the app DOES need them back)

-- >>> CHAT
-- A billing system needs to charge the stored card every month.
-- Hash it or encrypt it?  Why?


-- =====================================================================
-- PART 4 - IN TRANSIT: IS THIS CONNECTION ENCRYPTED?
-- =====================================================================
SHOW SESSION STATUS LIKE 'Ssl_cipher';
-- From the docker exec command: Value is EMPTY. docker exec talks to MySQL through
--   a local socket file inside the container, so no network, no TLS.
-- From Workbench on 127.0.0.1:13306: you should see a cipher such as
--   TLS_AES_128_GCM_SHA256 or TLS_AES_256_GCM_SHA384 - Workbench negotiated TLS.

SELECT @@tls_version, @@require_secure_transport;
-- You should see  TLSv1.2,TLSv1.3   and  0
-- 0 means the server ALLOWS unencrypted TCP connections. To force TLS for everyone:
--   SET PERSIST require_secure_transport = ON;
-- (Don't run it today - our PHP pages connect without TLS and would break.)


-- =====================================================================
-- PART 5 - AT REST: ENCRYPT THE WHOLE TABLE FILE (TDE)
-- =====================================================================
-- Last week grep read contacts.ibd straight off the disk. Run this in PowerShell:
--   docker exec dbsec-lamp-db mysql -uroot -prootpassword -e "FLUSH TABLES cryptodemo.cards_plain, cryptodemo.cards_enc FOR EXPORT"
--   docker exec dbsec-lamp-db grep -c 4520-1111 /var/lib/mysql/cryptodemo/cards_plain.ibd
--   docker exec dbsec-lamp-db grep -c 4520-1111 /var/lib/mysql/cryptodemo/cards_enc.ibd
-- You should see 1 for cards_plain (found on disk) and 0 for cards_enc.
--
-- Column encryption protects one column. Transparent Data Encryption (TDE)
-- encrypts the whole .ibd file. Try it:
ALTER TABLE cards_plain ENCRYPTION = 'Y';
-- You should see:
--   ERROR 3185 (HY000): Can't find master key from keyring, please check in the
--   server log if a keyring is loaded and initialized successfully.
-- TDE needs a KEYRING (somewhere to keep the master key) set up before MySQL starts.
-- No keyring, no TDE. The key management is the hard part, not the encryption.


-- =====================================================================
-- PART 6 - CLEAN UP (run by hand when you are done)
-- =====================================================================
-- DROP DATABASE IF EXISTS cryptodemo;
