<?php
// DBAS 1020 - Week 9: privilege tester (demo + Thursday lab, PART 6).
// Local Docker teaching use only. Open http://localhost/week9_privileges.php
//
// Logs in to MySQL as whichever account you type, then tries ten things, from a
// plain SELECT up to CREATE USER. Green = MySQL allowed it, red = MySQL refused it.
// Nothing is left behind: the INSERT is rolled back, the UPDATE and DELETE match
// no real change, and anything the probes create is dropped again straight away.

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES); }

// The ten probes, in order. 'after' runs only if the probe succeeded, to tidy up.
$probes = [
    ['Read every column',        "SELECT * FROM contacts LIMIT 3"],
    ['Read names and emails',    "SELECT first_name, last_name, email FROM contacts LIMIT 3"],
    ['Add a row (rolled back)',  "INSERT INTO contacts (first_name, last_name, email, phone) VALUES ('Probe', 'Row', 'probe@example.com', '000')",
                                 'before' => "START TRANSACTION", 'after' => "ROLLBACK"],
    ['Change a row (no-op)',     "UPDATE contacts SET phone = phone WHERE id = 1"],
    ['Delete rows (none match)', "DELETE FROM contacts WHERE id = 0"],
    ['Read password hashes',     "SELECT username, password FROM users LIMIT 1"],
    ['Create a table',           "CREATE TABLE week9_probe (id INT)"],
    ['Drop a table',             "DROP TABLE IF EXISTS week9_probe"],
    ['Read the account list',    "SELECT user, host FROM mysql.user"],
    ['Create a new user',        "CREATE USER 'week9_probe'@'%' IDENTIFIED BY 'Probe-Pass-1!'",
                                 'after' => "DROP USER 'week9_probe'@'%'"],
];

$user = $_POST['user'] ?? '';
$pass = $_POST['pass'] ?? '';
$who = $grants = $results = $connError = null;

if ($user !== '') {
    try {
        $conn = new mysqli(getenv('DB_HOST') ?: "db", $user, $pass, "appdb");

        $who = $conn->query("SELECT USER(), CURRENT_USER(), CURRENT_ROLE()")->fetch_row();
        $grants = array_column($conn->query("SHOW GRANTS")->fetch_all(), 0);

        $results = [];
        foreach ($probes as $p) {
            [$label, $sql] = $p;
            try {
                if (isset($p['before'])) $conn->query($p['before']);
                $res = $conn->query($sql);
                $detail = ($res instanceof mysqli_result)
                        ? $res->num_rows . " row(s) returned"
                        : $conn->affected_rows . " row(s) affected";
                if (isset($p['after'])) { $conn->query($p['after']); $detail .= " - then undone"; }
                $results[] = [$label, $sql, true, $detail];
            } catch (mysqli_sql_exception $e) {
                if (isset($p['before'])) $conn->query("ROLLBACK");
                $results[] = [$label, $sql, false, "ERROR " . $e->getCode() . ": " . $e->getMessage()];
            }
        }
    } catch (mysqli_sql_exception $e) {
        $connError = "ERROR " . $e->getCode() . ": " . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html>
<head>
<title>Week 9 - Privilege Tester</title>
<style>
 body{font-family:Arial,Helvetica,sans-serif;margin:40px;max-width:900px;color:#1b2a4a}
 h1{margin-bottom:2px}
 .sub{margin-top:0;color:#5a6b85}
 .card{border:1px solid #d7deea;border-radius:8px;padding:18px 20px;margin:16px 0;background:#f3f6fb}
 label{display:block;font-weight:bold;margin:10px 0 4px}
 input[type=text],input[type=password]{width:320px;padding:7px;border:1px solid #9aa7bd;border-radius:4px}
 button{margin-top:14px;background:#1b2a4a;color:#fff;border:0;padding:9px 20px;border-radius:4px;cursor:pointer}
 .hint{font-size:13px;color:#5a6b85;margin-top:12px}
 .log{background:#1b2a4a;color:#f3f6fb;font-family:'Courier New',monospace;padding:12px;white-space:pre-wrap;border-radius:6px}
 .logtag{font-size:11px;letter-spacing:1px;color:#f2a65a;font-weight:bold;margin-bottom:6px}
 .err{background:#fbe9e7;border:1px solid #b03a2e;padding:10px 14px;border-radius:6px}
 table{border-collapse:collapse;margin-top:10px;width:100%} td,th{border:1px solid #c7d0e0;padding:6px 10px;text-align:left;vertical-align:top}
 th{background:#1f3864;color:#fff}
 td.sql{font-family:'Courier New',monospace;font-size:13px}
 tr.yes td.mark{background:#e6f2ec;color:#2e7d5b;font-weight:bold}
 tr.no  td.mark{background:#fbe9e7;color:#b03a2e;font-weight:bold}
 .score{font-size:18px;margin:14px 0 4px}
 code{background:#eef1f7;padding:1px 5px;border-radius:3px}
</style>
</head>
<body>

<h1>Privilege Tester</h1>
<p class="sub">Log in as an account and see exactly what MySQL lets it do</p>

<div class="card">
<form method="post">
 <label for="user">MySQL username</label>
 <input type="text" id="user" name="user" list="accounts" value="<?= h($user) ?>" autofocus>
 <datalist id="accounts">
  <option value="appuser"><option value="web_app"><option value="web_reporter">
 </datalist>
 <label for="pass">Password</label>
 <input type="password" id="pass" name="pass">
 <br><button type="submit">Run the 10 checks</button>
 <p class="hint">Lab accounts: <code>appuser</code> / <code>apppassword</code> &middot;
  <code>web_app</code> / <code>App-Week9-Pass!</code> &middot;
  <code>web_reporter</code> / <code>Report-Week9-Pass!</code></p>
</form>
</div>

<?php if ($connError): ?>
 <p class="err"><b>Could not log in.</b> <?= h($connError) ?></p>
<?php elseif ($results !== null): ?>
 <div class="log"><div class="logtag">WHO MYSQL THINKS YOU ARE</div>USER()         = <?= h($who[0]) ?>

CURRENT_USER() = <?= h($who[1]) ?>

CURRENT_ROLE() = <?= h($who[2]) ?>


<span class="logtag">SHOW GRANTS</span>
<?= h(implode("\n", $grants)) ?></div>

 <?php $allowed = count(array_filter(array_column($results, 2))); ?>
 <p class="score"><b><?= $allowed ?></b> allowed &middot; <b><?= count($results) - $allowed ?></b> refused</p>
 <table>
  <tr><th></th><th>Check</th><th>SQL sent</th><th>What MySQL said</th></tr>
  <?php foreach ($results as [$label, $sql, $ok, $detail]): ?>
   <tr class="<?= $ok ? 'yes' : 'no' ?>">
    <td class="mark"><?= $ok ? '&#10003;' : '&#10007;' ?></td>
    <td><?= h($label) ?></td>
    <td class="sql"><?= h($sql) ?></td>
    <td><?= h($detail) ?></td>
   </tr>
  <?php endforeach; ?>
 </table>
<?php endif; ?>

</body>
</html>
