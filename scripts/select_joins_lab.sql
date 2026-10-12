-- DBAS 1020 - Week 6 (Thursday) Lab: SELECT, JOINs & Aggregates
-- Ask game_shop real questions: filter, sort, combine tables, then summarise.
-- Run in MySQL Workbench connected as root (port 13306).
--
-- HOW TO RUN
--   1. Do PART 1 (setup) first.
--   2. Do the exercises IN ORDER. Write your SQL on the blank lines
--      under each exercise, then run it (Ctrl+Enter).
--   3. Compare your result with "You should see". If it doesn't match,
--      fix it before moving on. Workbench shows the row count in the
--      Output panel at the bottom.
--   4. When you reach a  >>> CHAT  line, post your answer in the class chat.
--
-- Everything in this lab is a SELECT, so you can't break anything.
-- If your data ever looks wrong, re-run scripts/game_shop.sql to reset it.


-- =====================================================================
-- PART 1 - SETUP
-- =====================================================================
-- Open scripts/game_shop.sql and run ALL of it: select it all, Ctrl+Shift+Enter.
-- (Already did it on Tuesday? Run it again anyway so everyone has the same data.)
-- Then come back here and run these two lines:

USE game_shop;
SELECT COUNT(*) FROM orders;

-- You should see: 700
-- >>> CHAT: Type READY when you see 700.
--
-- The tables:
--   platforms   (platform_id, name, manufacturer)
--   games       (game_id, title, platform_id, genre, esrb_rating, price, stock_qty, release_date)
--   customers   (customer_id, first_name, last_name, email, phone, city, province, joined_date)
--   orders      (order_id, customer_id, order_date, status, shipped_date)
--   order_items (order_item_id, order_id, game_id, quantity, unit_price)


-- =====================================================================
-- PART 2 - FILTER (WHERE, LIKE, IN, BETWEEN, IS NULL)
-- =====================================================================

-- 2.1  Show the title and price of every Horror game.
--      You should see: 15 rows




-- 2.2  Show the title and price of games that cost from $30 to $50,
--      INCLUDING $30 and $50.
--      HINT: price >= 30 AND price <= 50   (or: price BETWEEN 30 AND 50)
--      You should see: 34 rows




-- 2.3  Find customers whose email address ends in @eastlink.ca.
--      HINT: LIKE with % at the start
--      You should see: 57 rows




-- 2.4  Find orders that are 'Pending' AND were placed in 2026
--      (order_date on or after '2026-01-01').
--      You should see: 26 rows




-- 2.5  Find every order that has no shipped_date.
--      You should see: 105 rows




-- >>> CHAT: Look at the status column in 2.5. Which TWO statuses have no
--           shipped_date, and why does that make sense?


-- =====================================================================
-- PART 3 - SORT AND CAP (ORDER BY, LIMIT)
-- =====================================================================

-- 3.1  Show the 5 cheapest games (title and price). Break ties by title, A to Z.
--      You should see: 5 rows, all $9.99, starting with Crimson Saga




-- >>> CHAT: Every one of your 5 rows costs $9.99. Without the tie-break on
--           title, would you always get the same 5 games? Why or why not?


-- 3.2  Show the 3 customers who joined most recently (first name,
--      last name, joined_date), newest first.
--      You should see: Kayla Stoddard, Ryan Stoddard, Owen Penney




-- 3.3  List every game that is out of stock (stock_qty = 0), A to Z by title.
--      You should see: 17 rows, starting with Ancient Tide




-- =====================================================================
-- PART 4 - INNER JOIN
-- Use table aliases (g, p, c, o, oi). Every JOIN needs an ON.
-- =====================================================================

-- 4.1  Show the title, platform name and manufacturer of every game made
--      for a Nintendo platform (manufacturer = 'Nintendo').
--      Tables: games + platforms
--      You should see: 35 rows




-- 4.2  Emily Comeau is customer_id 268. Show the order_id, order_date
--      and status of all her orders, oldest first.
--      Tables: orders + customers (show her first and last name too)
--      You should see: 14 rows, from 2026-03-12 to 2026-09-28




-- 4.3  Show everything in order #7: the order date, the customer's first
--      and last name, each game title, the quantity and the unit_price.
--      Tables: FOUR of them (orders, customers, order_items, games)
--      HINT: start FROM orders o, then JOIN one table at a time.
--      You should see: 3 rows, all for Connor Wilson on 2024-04-25




-- >>> CHAT: Which game in order #7 did Connor buy two copies of?


-- =====================================================================
-- PART 5 - LEFT JOIN
-- =====================================================================

-- 5.1  Run both of these and compare the row counts:
--          SELECT COUNT(*) FROM customers c JOIN orders o
--              ON o.customer_id = c.customer_id;
--          SELECT COUNT(*) FROM customers c LEFT JOIN orders o
--              ON o.customer_id = c.customer_id;
--      You should see: 700, then 770




-- >>> CHAT: Where do the extra 70 rows in the LEFT JOIN come from?


-- 5.2  List every game that has NEVER been sold, with its platform name.
--      Tables: games, platforms, order_items
--      HINT: INNER JOIN to platforms (every game has one),
--            LEFT JOIN to order_items, then WHERE ... IS NULL
--      You should see: 12 rows. 5 of them are Xbox Series X games.




-- 5.3  Find customers who joined in 2026 (joined_date on or after
--      '2026-01-01') and have NEVER placed an order.
--      You should see: 4 rows




-- =====================================================================
-- PART 6 - AGGREGATES (COUNT, SUM, AVG, MIN, MAX)
-- =====================================================================

-- 6.1  In ONE query, show: how many games there are, the total stock_qty,
--      and the average price rounded to 2 decimals.
--      You should see: 150, 1614, 47.92




-- 6.2  How many customers have NO phone number? Do it with COUNT only,
--      no WHERE.
--      HINT: COUNT(*) counts rows. COUNT(phone) skips NULLs.
--      You should see: 68




-- 6.3  What is the total revenue (quantity * unit_price) from every order
--      that was NOT cancelled?
--      Tables: order_items + orders
--      You should see: 63711.67




-- >>> CHAT: Change one thing in 6.3 to find how much revenue was lost to
--           cancelled orders. Post the number.


-- =====================================================================
-- PART 7 - GROUP BY AND HAVING
-- WHERE filters rows BEFORE grouping. HAVING filters groups AFTER.
-- =====================================================================

-- 7.1  How many games are there in each genre? Most first.
--      You should see: 12 rows, Puzzle (18) first, Shooter (5) last




-- 7.2  Which cities have at least 20 customers? Most first.
--      You should see: 6 rows, Halifax (75) first




-- 7.3  How many orders were placed in each year?
--      HINT: YEAR(order_date) gives you the year. GROUP BY it.
--      You should see: 5 rows, 2022 to 2026, with 2026 the busiest (302)




-- 7.4  Which platforms earned MORE than $5,000 in revenue from orders
--      that were not cancelled? Highest first.
--      HINT: Tuesday's revenue-by-platform query, plus one HAVING line.
--      You should see: 4 rows, PlayStation 5 first




-- >>> CHAT: In 7.4, the status <> 'Cancelled' check goes in WHERE but the
--           > 5000 check goes in HAVING. Why can't they swap places?


-- =====================================================================
-- PART 8 - CHALLENGE
-- Everything from this week in one query each.
-- =====================================================================

-- 8.1  Top 5 customers by total spent (orders not cancelled). Show first
--      name, last name, city and total spent, biggest first.
--      Tables: customers, orders, order_items
--      HINT: GROUP BY c.customer_id, c.first_name, c.last_name, c.city
--      You should see: Ella MacDonald (Sydney) first with 1379.69




-- >>> CHAT: Who is the top spender, and in which city?


-- 8.2  For each platform, how many DIFFERENT customers have bought at least
--      one game for it? Most first.
--      HINT: COUNT(DISTINCT o.customer_id)
--      You should see: 8 rows, PC (146) first, Retro (NES) (25) last
