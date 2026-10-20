<?php
// DBAS 1020 - Week 7: the SQL Injection attack lab (Assignment 3).
//
// INTENTIONALLY VULNERABLE. Local Docker teaching use only.
// This is the deliberately broken login from the Week 7 lecture notes.
// Never write code like this - never glue user input into a query string.
//
// Open http://localhost/week7_login.php  (your own Docker container)
//
// Run initdb/02_users.sql first so the users table exists.

$conn = new mysqli(getenv('DB_HOST') ?: "db", "appuser", "apppassword", "appdb");

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES); }

$sqlShown = null;   // the exact SQL text the page sends to MySQL
$rows     = null;   // whatever MySQL hands back
$message  = null;
$error    = null;
$attempted = false;

if (isset($_POST['user'])) {
    $attempted = true;
    $user = $_POST['user'];
    $pass = $_POST['pass'] ?? '';

    // ----------------------------------------------------------------
    // THE VULNERABILITY: $user and $pass are pasted straight into SQL.
    // Two columns are selected so the lecture's UNION payload lines up.
    //
    // Note the password IS hashed before it is compared (SHA2), so an honest
    // login with the right password works and the DB never stores cleartext.
    // Hashing does NOT save us here - the injection is in the USERNAME, which
    // is still glued in raw. Good password hygiene and SQL injection are two
    // separate problems.
    // ----------------------------------------------------------------
    $sqlShown = "SELECT username, password FROM users "
              . "WHERE username = '$user' AND password = SHA2('$pass', 256)";

    try {
        $result = $conn->query($sqlShown);
        if ($result && $result->num_rows > 0) {
            $rows = $result->fetch_all(MYSQLI_ASSOC);
            $message = "Welcome, " . $user . "! Login succeeded ("
                     . count($rows) . " row(s) returned).";
        } else {
            $message = "Login failed.";
        }
    } catch (mysqli_sql_exception $e) {
        // Leaking the raw error to the user is itself a vulnerability -
        // we show it here only so you can see what the database tried to run.
        $error = $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html>
<head>
<title>Week 7 - SQL Injection Attack Lab</title>
<style>
 body{font-family:Arial,Helvetica,sans-serif;margin:40px;max-width:820px;color:#1b2a4a}
 h1{margin-bottom:4px}
 .warn{background:#fdf0e7;border:1px solid #e8752b;padding:10px 14px;margin:14px 0}
 .card{border:1px solid #d7deea;border-radius:8px;padding:18px 20px;margin:16px 0;background:#f3f6fb}
 label{display:block;font-weight:bold;margin:10px 0 4px}
 input[type=text],input[type=password]{width:320px;padding:7px;border:1px solid #9aa7bd;border-radius:4px}
 button{margin-top:14px;background:#1b2a4a;color:#fff;border:0;padding:9px 20px;border-radius:4px;cursor:pointer}
 .sql{background:#1b2a4a;color:#f3f6fb;font-family:'Courier New',monospace;padding:12px;white-space:pre-wrap;border-radius:6px}
 .ok{background:#e6f2ec;border:1px solid #2e7d5b;padding:10px 14px;border-radius:6px}
 .fail{background:#eef1f7;border:1px solid #9aa7bd;padding:10px 14px;border-radius:6px}
 .err{background:#fbe9e7;border:1px solid #b03a2e;padding:10px 14px;border-radius:6px}
 table{border-collapse:collapse;margin-top:10px} td,th{border:1px solid #c7d0e0;padding:6px 12px;text-align:left}
 th{background:#1f3864;color:#fff}
 code{background:#eef1f7;padding:1px 5px;border-radius:3px}
</style>
</head>
<body>

<h1>TopSail Internal Portal</h1>
<p style="margin-top:0;color:#5a6b85">Staff sign-in</p>

<div class="warn">
 <b>Teaching page - intentionally vulnerable.</b> This login glues your input
 straight into a SQL query. It exists only so you can attack it on your own container.
 Never write code like this, and never run these payloads against a system you do not own.
</div>

<div class="card">
<form method="post">
 <label for="user">Username</label>
 <input type="text" id="user" name="user" value="<?= isset($_POST['user']) ? h($_POST['user']) : '' ?>" autofocus>
 <label for="pass">Password</label>
 <input type="password" id="pass" name="pass">
 <br><button type="submit">Sign in</button>
</form>
</div>

<?php if ($attempted): ?>
 <h3>SQL the page sent to MySQL</h3>
 <div class="sql"><?= h($sqlShown) ?></div>

 <?php if ($error): ?>
  <p class="err"><b>MySQL error:</b> <?= h($error) ?></p>
 <?php elseif ($rows !== null): ?>
  <p class="ok"><?= h($message) ?></p>
  <table>
   <tr><th>username</th><th>password</th></tr>
   <?php foreach ($rows as $r): ?>
    <tr><td><?= h($r['username']) ?></td><td><?= h($r['password']) ?></td></tr>
   <?php endforeach; ?>
  </table>
 <?php else: ?>
  <p class="fail"><?= h($message) ?></p>
 <?php endif; ?>
<?php endif; ?>

</body>
</html>
