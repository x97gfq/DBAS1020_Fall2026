// DBAS 1020 - Week 11 Class 2: A Look at MongoDB (documents, queries, security, NoSQL injection)
// Builds a throwaway MongoDB database called bookshop - the SAME data as the MySQL
// bookshop from Class 1, stored as documents instead of tables.
//
// HOW TO RUN
//   First:  docker compose up -d      (starts the new dbsec-mongo container)
//   PowerShell (Windows):
//     Get-Content scripts\week11_mongo_demo.js | docker exec -i dbsec-mongo mongosh --quiet -u root -p rootpassword
//   bash / macOS:
//     docker exec -i dbsec-mongo mongosh --quiet -u root -p rootpassword < scripts/week11_mongo_demo.js
//   Interactive (type the commands yourself, one at a time):
//     docker exec -it dbsec-mongo mongosh -u root -p rootpassword
//
// Safe to re-run: it drops bookshop and the w11_app user first. Keep this file ASCII.

// ===================================================================
// PART 1 - A DATABASE, A COLLECTION, SOME DOCUMENTS
// ===================================================================
// SQL:   database -> table      -> row      -> column
// Mongo: database -> collection -> document -> field
use bookshop
db.dropDatabase()

// One order = one document. The customer and the line items live INSIDE it.
// In MySQL this took 4 tables and 3 foreign keys.
db.orders.insertMany([
  { _id: 1, date: "2026-11-02",
    customer: { name: "Ava Doucette", email: "ava@example.com", city: "Halifax" },
    items: [ { title: "Anne of Green Gables", price: 12.99, qty: 2 },
             { title: "Barometer Rising",     price: 16.00, qty: 1 } ] },
  { _id: 2, date: "2026-11-03",
    customer: { name: "Liam MacLeod", email: "liam@example.com", city: "Truro" },
    items: [ { title: "The Shipping News", price: 18.50, qty: 1 } ] },
  { _id: 3, date: "2026-11-09",
    customer: { name: "Ava Doucette", email: "ava@example.com", city: "Halifax" },
    items: [ { title: "Fall on Your Knees",   price: 21.95, qty: 1 },
             { title: "No Great Mischief",    price: 19.25, qty: 1 },
             { title: "Anne of Green Gables", price: 12.99, qty: 1 } ] },
  { _id: 4, date: "2026-11-12",
    customer: { name: "Noor Haddad", email: "noor@example.com", city: "Dartmouth" },
    items: [ { title: "No Great Mischief", price: 19.25, qty: 3, gift_wrap: true } ] }
])
// You should see  acknowledged: true, insertedIds: { '0': 1, '1': 2, '2': 3, '3': 4 }
// Notice order 4 has a gift_wrap field the others don't. No ALTER TABLE needed -
// MongoDB doesn't enforce a schema unless you ask it to.

// ===================================================================
// PART 2 - QUERYING: find() IS SELECT ... WHERE
// ===================================================================
print("--- orders from Halifax (SELECT ... WHERE city = 'Halifax')")
db.orders.find({ "customer.city": "Halifax" }, { _id: 1, date: 1 }).toArray()
// You should see orders 1 and 3. "customer.city" reaches INSIDE the embedded document.

print("--- orders containing No Great Mischief")
db.orders.find({ "items.title": "No Great Mischief" }, { _id: 1 }).toArray()
// You should see orders 3 and 4 - it searches inside the array too.

print("--- orders with exactly 3 line items  ($size)")
db.orders.find({ items: { $size: 3 } }, { _id: 1 }).toArray()
// You should see order 3. Operators start with $ :  $gt  $lt  $ne  $in  $size ...
// Remember the $ - it matters in PART 5.

print("--- total sales (the SUM ... JOIN ... from Class 1)")
db.orders.aggregate([
  { $unwind: "$items" },
  { $group: { _id: null, total_sales: { $sum: { $multiply: ["$items.price", "$items.qty"] } } } }
]).toArray()
// You should see total_sales: 172.42 (it may print as 172.42000000000002 -
// MongoDB stores price as a floating-point double; MySQL used exact DECIMAL).

// ===================================================================
// PART 3 - THE CATCH: DUPLICATED DATA
// ===================================================================
print("--- Ava moves to Bedford: how many documents hold her city?")
db.orders.countDocuments({ "customer.email": "ava@example.com" })
// You should see 2. In MySQL you would UPDATE one row in customers.
// Here you must update every order that embedded her - miss one and the data disagrees.
db.orders.updateMany({ "customer.email": "ava@example.com" }, { $set: { "customer.city": "Bedford" } })
// You should see matchedCount: 2, modifiedCount: 2

// ===================================================================
// PART 4 - SECURITY: AUTHENTICATION AND LEAST PRIVILEGE
// ===================================================================
// We logged in as root. The container only accepts logins because we set
// MONGO_INITDB_ROOT_USERNAME - by default, mongod has NO authentication at all.
use admin
if (db.getUser("w11_app")) { db.dropUser("w11_app") }
db.createUser({
  user: "w11_app",
  pwd:  "App-Pass-W11!",
  roles: [ { role: "readWrite", db: "bookshop" } ]   // like GRANT SELECT, INSERT, UPDATE, DELETE ON bookshop.*
})
// You should see { ok: 1 }
// Try it in a second terminal (it can read and write bookshop - nothing else):
//   docker exec -it dbsec-mongo mongosh -u w11_app -p App-Pass-W11! --authenticationDatabase admin bookshop
//   bookshop> db.orders.countDocuments()                    -> 4
//   bookshop> db.dropDatabase()                             -> MongoServerError: not authorized on bookshop
//   bookshop> db.getSiblingDB("shop2").x.insertOne({a: 1})  -> MongoServerError: not authorized on shop2
// And with NO username at all:
//   docker exec -it dbsec-mongo mongosh bookshop
//   bookshop> db.orders.countDocuments()  -> MongoServerError: Command aggregate requires authentication

// ===================================================================
// PART 5 - NoSQL INJECTION: THE SAME BUG IN DIFFERENT CLOTHES
// ===================================================================
use bookshop
db.users.insertOne({ username: "admin", password: "S3cret-Admin!" })   // plain text: Week 8 says NO. Demo only.

// A typical Node/Express login: take the JSON the browser sent and drop it into the query.
function login(body) {
  return db.users.findOne({ username: body.username, password: body.password })
}

print("--- 1. right password")
login({ username: "admin", password: "S3cret-Admin!" })
// You should see the admin document. Logged in.

print("--- 2. wrong password")
login({ username: "admin", password: "guess" })
// You should see null. Rejected.

print("--- 3. the attacker sends JSON, not a string")
login({ username: "admin", password: { "$ne": null } })
// You should see the admin document. Logged in WITHOUT the password.
// The query became:  password is NOT EQUAL to null  -> true for every user.
// SQL injection smuggled SQL into a string. This smuggles an OPERATOR into a value.

// The fix: only accept strings (input validation), just like a prepared statement
// stops the input from being treated as code.
function safeLogin(body) {
  if (typeof body.username !== "string" || typeof body.password !== "string") return null
  return db.users.findOne({ username: body.username, password: body.password })
}
print("--- 4. same attack against safeLogin")
safeLogin({ username: "admin", password: { "$ne": null } })
// You should see null. Rejected.

// ===================================================================
// PART 6 - CLEAN UP (uncomment and run when you are done)
// ===================================================================
// use bookshop
// db.dropDatabase()
// use admin
// db.dropUser("w11_app")
