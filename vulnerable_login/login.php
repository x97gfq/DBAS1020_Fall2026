<?php
// DBAS 1020 - Assignment 3: deliberately vulnerable login (login.php).
//
// INTENTIONALLY INSECURE. Local Docker teaching use only.
// Drop this file into   ~/dbas1020/www/   and visit:
//     http://localhost:80/login.php
//
// This is the TARGET for Part A of Assignment 3. Never write code like this,
// and never run injection payloads against a system you do not own.

$conn = new mysqli(getenv('DB_HOST') ?: "db", "appuser", "apppassword", "appdb");

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES); }

$sqlShown = null;   // the exact SQL the app sent to MySQL (also written to the debug log)
$rows     = null;   // whatever MySQL returned
$message  = null;
$error    = null;
$attempted = false;

if (isset($_POST['user'])) {
    $attempted = true;
    $user = $_POST['user'];
    $pass = $_POST['pass'] ?? '';

    // ----------------------------------------------------------------
    // THE VULNERABILITY: $user and $pass are concatenated straight into
    // the SQL string. Two columns are selected so a UNION lines up easily.
    //
    // The password is hashed before comparison (SHA2), so an honest login with
    // the right password works and no cleartext is stored. That does NOT stop
    // the attack: the hole is the USERNAME, which is still glued in raw.
    // ----------------------------------------------------------------
    $sqlShown = "SELECT username, password FROM users "
              . "WHERE username = '$user' AND password = SHA2('$pass', 256)";

    // --- Debug log -------------------------------------------------------
    // The app records every statement it runs. Part A asks you to report
    // "the full SQL statement the application ended up running" - read it
    // here, in the on-page DEBUG LOG panel below, or in the container log
    // (docker logs dbsec-lamp-web).
    error_log("[login.php SQL] " . $sqlShown);

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
        // Leaking raw DB errors to the user is itself a flaw; shown here to learn.
        $error = $e->getMessage();
        error_log("[login.php ERROR] " . $error);
    }
}
?>
<!DOCTYPE html>
<html>
<head>
<title>TopSail Portal - Sign In</title>
<style>
 body{font-family:Arial,Helvetica,sans-serif;margin:40px;max-width:820px;color:#1b2a4a}
 h1{margin-bottom:2px}
 .sub{margin-top:0;color:#5a6b85}
 .warn{background:#fdf0e7;border:1px solid #e8752b;padding:10px 14px;margin:14px 0}
 .card{border:1px solid #d7deea;border-radius:8px;padding:18px 20px;margin:16px 0;background:#f3f6fb}
 label{display:block;font-weight:bold;margin:10px 0 4px}
 input[type=text],input[type=password]{width:320px;padding:7px;border:1px solid #9aa7bd;border-radius:4px}
 button{margin-top:14px;background:#1b2a4a;color:#fff;border:0;padding:9px 20px;border-radius:4px;cursor:pointer}
 .log{background:#1b2a4a;color:#f3f6fb;font-family:'Courier New',monospace;padding:12px;white-space:pre-wrap;border-radius:6px}
 .logtag{font-size:11px;letter-spacing:1px;color:#f2a65a;font-weight:bold;margin-bottom:6px}
 .ok{background:#e6f2ec;border:1px solid #2e7d5b;padding:10px 14px;border-radius:6px}
 .fail{background:#eef1f7;border:1px solid #9aa7bd;padding:10px 14px;border-radius:6px}
 .err{background:#fbe9e7;border:1px solid #b03a2e;padding:10px 14px;border-radius:6px}
 table{border-collapse:collapse;margin-top:10px} td,th{border:1px solid #c7d0e0;padding:6px 12px;text-align:left}
 th{background:#1f3864;color:#fff}
</style>
</head>
<body>

<h1>TopSail Internal Portal</h1>
<p class="sub">Staff sign-in</p>

<div class="warn">
 <b>Teaching page - intentionally vulnerable.</b> This login concatenates your input
 straight into a SQL query. It is the target for Assignment 3, Part A. Only ever
 attack it on your own Docker container.
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
 <div class="log"><div class="logtag">DEBUG LOG &mdash; SQL EXECUTED</div><?= h($sqlShown) ?></div>

 <?php if ($error): ?>
  <p class="err"><b>MySQL error:</b> <?= h($error) ?></p>
 <?php elseif ($rows !== null): ?>
  <p class="ok"><?= h($message) ?></p>
  <table>
   <tr><th>username</th><th>password</th></tr>
   <?php foreach ($rows as $r): ?>
    <tr>
     <td><?= h(reset($r)) ?></td>
     <td><?= h(end($r)) ?></td>
    </tr>
   <?php endforeach; ?>
  </table>
 <?php else: ?>
  <p class="fail"><?= h($message) ?></p>
 <?php endif; ?>
<?php endif; ?>

</body>
</html>
