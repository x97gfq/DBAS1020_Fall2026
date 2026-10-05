<?php
// DBAS 1020 - Week 5: a first look at SQL injection.
// INTENTIONALLY VULNERABLE in "unsafe" mode. Local Docker teaching use only.
// Never copy the unsafe code into a real project.
//
// Open http://localhost/week5_injection.php  (Ticket 10 of the Week 5 lab)

$conn = new mysqli(getenv('DB_HOST') ?: "db", "appuser", "apppassword", "appdb");

$mode = (($_GET['mode'] ?? $_POST['mode'] ?? 'unsafe') === 'safe') ? 'safe' : 'unsafe';
$sqlShown = null;     // the SQL text the page sent to MySQL
$params = null;       // safe mode only: the values sent separately
$message = null;
$error = null;
$rows = null;

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES); }

try {
    // ---------- Reset: put the five starter contacts back ----------
    if (isset($_POST['reset'])) {
        $conn->query("TRUNCATE TABLE contacts");
        $conn->query("INSERT INTO contacts (first_name,last_name,email,phone) VALUES
            ('Jamie','Symonds','jamie@example.com','902-555-1001'),
            ('Randy','Bourque','randy@example.com','902-555-1002'),
            ('Craig','Collins','craig@example.com','902-555-1003'),
            ('Alice','Johnson','alice@example.com','902-555-1004'),
            ('Bob','Smith','bob@example.com','902-555-1005')");
        $message = "Contacts reset to the 5 starter rows.";
    }

    // ---------- Delete by id ----------
    if (isset($_POST['delete_id'])) {
        $id = $_POST['delete_id'];
        if ($mode === 'unsafe') {
            // UNSAFE: the user's text is glued into the SQL.
            $sqlShown = "DELETE FROM contacts WHERE id = " . $id;
            $conn->query($sqlShown);
            $message = $conn->affected_rows . " row(s) deleted.";
        } else {
            // SAFE: validate the input, then send it as a parameter.
            $sqlShown = "DELETE FROM contacts WHERE id = ?";
            $params = [$id];
            if (!ctype_digit($id)) {
                $message = "Rejected: an id must be a whole number. Nothing was sent to MySQL.";
            } else {
                $stmt = $conn->prepare($sqlShown);
                $intId = (int)$id;
                $stmt->bind_param("i", $intId);
                $stmt->execute();
                $message = $stmt->affected_rows . " row(s) deleted.";
            }
        }
    }

    // ---------- Search by last name (always runs, so the table is visible) ----------
    $search = $_GET['last_name'] ?? '';
    if ($mode === 'unsafe') {
        $sqlSearch = "SELECT id, first_name, last_name, email, phone FROM contacts "
                   . "WHERE last_name LIKE '%" . $search . "%' ORDER BY id";
        $result = $conn->query($sqlSearch);
        $searchParams = null;
    } else {
        $sqlSearch = "SELECT id, first_name, last_name, email, phone FROM contacts "
                   . "WHERE last_name LIKE ? ORDER BY id";
        $stmt = $conn->prepare($sqlSearch);
        $like = "%" . $search . "%";
        $stmt->bind_param("s", $like);
        $stmt->execute();
        $result = $stmt->get_result();
        $searchParams = [$like];
    }
    $rows = $result->fetch_all(MYSQLI_ASSOC);
    if ($sqlShown === null) { $sqlShown = $sqlSearch; $params = $searchParams; }
} catch (mysqli_sql_exception $e) {
    // Showing raw database errors to users is itself a leak - we do it here to learn.
    $error = $e->getMessage();
    if ($sqlShown === null && isset($sqlSearch)) { $sqlShown = $sqlSearch; }
}
?>
<!DOCTYPE html>
<html><head><title>Week 5 - SQL Injection Lab</title>
<style>
 body{font-family:Arial;margin:40px;max-width:900px}
 table{border-collapse:collapse} td,th{border:1px solid #ccc;padding:6px 10px}
 .warn{background:#fdf0e7;border:1px solid #e8752b;padding:10px;margin-bottom:20px}
 .sql{background:#1b2a4a;color:#f3f6fb;font-family:'Courier New',monospace;padding:12px;white-space:pre-wrap}
 .err{background:#fbe9e7;border:1px solid #b03a2e;padding:10px}
 .ok{background:#e8edf6;padding:10px}
 .mode a{padding:6px 12px;border:1px solid #1b2a4a;text-decoration:none;color:#1b2a4a}
 .mode a.on{background:#1b2a4a;color:#fff}
 form{margin:12px 0}
</style>
</head><body>
<h1>Rolodex Contacts: Injection Lab</h1>
<div class="warn"><b>Teaching page.</b> In <b>UNSAFE</b> mode this page builds SQL by gluing your input
into the query string. Never write code like this outside this lab.</div>

<p class="mode">Mode:
 <a href="?mode=unsafe" class="<?= $mode === 'unsafe' ? 'on' : '' ?>">UNSAFE (concatenation)</a>
 <a href="?mode=safe" class="<?= $mode === 'safe' ? 'on' : '' ?>">SAFE (prepared statement)</a>
</p>

<form method="get">
 <input type="hidden" name="mode" value="<?= h($mode) ?>">
 Search last name: <input name="last_name" size="40" value="<?= h($_GET['last_name'] ?? '') ?>">
 <button>Search</button>
</form>

<form method="post" action="?mode=<?= h($mode) ?>">
 <input type="hidden" name="mode" value="<?= h($mode) ?>">
 Delete contact by id: <input name="delete_id" size="20">
 <button>Delete</button>
</form>

<form method="post" action="?mode=<?= h($mode) ?>">
 <input type="hidden" name="mode" value="<?= h($mode) ?>">
 <button name="reset" value="1">Reset contacts</button>
</form>

<?php if ($sqlShown !== null): ?>
 <h3>SQL sent to MySQL</h3>
 <div class="sql"><?= h($sqlShown) ?><?php if ($params !== null): ?>

-- parameter value(s), sent separately as DATA:
<?php foreach ($params as $p) echo "--   [" . h($p) . "]\n"; ?><?php endif; ?></div>
<?php endif; ?>

<?php if ($message): ?><p class="ok"><?= h($message) ?></p><?php endif; ?>
<?php if ($error): ?><p class="err"><b>MySQL error:</b> <?= h($error) ?></p><?php endif; ?>

<?php if ($rows !== null): ?>
 <h3><?= count($rows) ?> contact(s)</h3>
 <table><tr><th>id</th><th>First Name</th><th>Last Name</th><th>Email</th><th>Phone</th></tr>
 <?php foreach ($rows as $r): ?>
  <tr><td><?= h($r['id']) ?></td><td><?= h($r['first_name']) ?></td><td><?= h($r['last_name']) ?></td>
      <td><?= h($r['email']) ?></td><td><?= h($r['phone']) ?></td></tr>
 <?php endforeach; ?>
 </table>
<?php endif; ?>
</body></html>
