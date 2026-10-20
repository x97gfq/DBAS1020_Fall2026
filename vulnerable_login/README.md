# Assignment 3 — Vulnerable Login (setup)

This folder is the starting point for **Assignment 3 — SQL Injection: Attack & Defend**.
It contains a deliberately insecure login page and the database table it checks against.

> ⚠️ **Ethics.** These files are for attacking **your own Docker container only**.
> Running SQL-injection payloads against systems you do not own is illegal in Canada
> (Criminal Code s. 342.1). Don't.

## Files

| File | Goes into | What it is |
|---|---|---|
| `login.php` | `~/dbas1020/www/` | The vulnerable login (the Part A target) |
| `users.sql` | `~/dbas1020/initdb/` | Creates and seeds the `users` table |

## Setup

1. Copy the two files into place:
   - `login.php` → your `www/` folder
   - `users.sql` → your `initdb/` folder
2. Rebuild and start the containers:
   ```bash
   docker compose up -d --build
   ```
3. Open the page:
   ```
   http://localhost:80/login.php
   ```

An honest login (`admin` + any password) says **“Login failed.”** — that's expected.
Your job in Part A is to get in anyway.

## Loading users.sql

Files in `initdb/` run **automatically the first time the database volume is created**.
If the `users` table is missing (for example, your database already existed), load it one of these ways:

**A — Clean rebuild (simplest; wipes all data and re-seeds):**
```bash
docker compose down -v
docker compose up -d --build
```

**B — Load into the running container (keeps existing data):**
```bash
docker exec -i dbsec-lamp-db mysql -uroot -prootpassword appdb < initdb/users.sql
```

**C — MySQL Workbench:** connect as `root` on `localhost:13306`, open `users.sql`, and run it.

Check it worked:
```sql
SELECT COUNT(*) FROM users;   -- expect 6
```

## Reading the SQL the app ran

Part A asks for the **full SQL statement the application ended up running**. `login.php`
shows it three ways:

- the **DEBUG LOG** panel on the page, after every attempt;
- the container log: `docker logs dbsec-lamp-web`;
- (both come from the same `error_log()` call in `login.php`).

## What you build (Parts B & C)

You do **not** edit these files for your submission. In Part B you create a fixed
copy, `login_fixed.php`, plus `users_fixed.sql` (passwords stored with
`password_hash()`), and in Part C you write `reflection.md`. See the assignment
brief for the full rubric.
