<?php
// DBAS 1020 - Week 8: hash lab (Class 1 demo + student practice).
// Local Docker teaching use only. Open http://localhost/week8_hash_lab.php
//
// Type a password and see it run through fast hashes (MD5, SHA-256) and slow,
// salted ones (bcrypt, Argon2id). Nothing is stored anywhere.

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES); }

// Time one call in milliseconds
function timed(callable $fn): array
{
    $start = hrtime(true);
    $out = $fn();
    return [$out, (hrtime(true) - $start) / 1e6];
}

$pw = $_POST['pw'] ?? '';
$rows = [];
$bcrypt = null;

if ($pw !== '') {
    // Fast, unsalted: same input -> same output, every time, on every computer
    [$md5, $t] = timed(fn() => md5($pw));
    $rows[] = ['MD5 (never for passwords)', $md5, $t, 'Same every time'];
    [$sha, $t] = timed(fn() => hash('sha256', $pw));
    $rows[] = ['SHA-256, unsalted', $sha, $t, 'Same every time'];
    [$sha2, $t] = timed(fn() => hash('sha256', $pw));
    $rows[] = ['SHA-256 again', $sha2, $t, $sha2 === $sha ? 'IDENTICAL to the line above' : 'different'];

    // Slow, salted: a new random salt on every call
    [$b1, $t] = timed(fn() => password_hash($pw, PASSWORD_BCRYPT));
    $rows[] = ['bcrypt, cost 10 (PASSWORD_DEFAULT)', $b1, $t, 'New salt'];
    [$b2, $t] = timed(fn() => password_hash($pw, PASSWORD_BCRYPT));
    $rows[] = ['bcrypt, cost 10 again', $b2, $t, $b2 === $b1 ? 'identical' : 'DIFFERENT from the line above'];
    [$b12, $t] = timed(fn() => password_hash($pw, PASSWORD_BCRYPT, ['cost' => 12]));
    $rows[] = ['bcrypt, cost 12', $b12, $t, '4x the work of cost 10'];
    if (defined('PASSWORD_ARGON2ID')) {
        [$a, $t] = timed(fn() => password_hash($pw, PASSWORD_ARGON2ID));
        $rows[] = ['Argon2id (memory-hard)', $a, $t, 'New salt'];
    }

    // Take the first bcrypt hash apart: $2y$ 10 $ <22-char salt> <31-char hash>
    $bcrypt = [
        'algo' => substr($b1, 0, 4),
        'cost' => substr($b1, 4, 2),
        'salt' => substr($b1, 7, 22),
        'hash' => substr($b1, 29),
    ];
    [$v1, $tv] = timed(fn() => password_verify($pw, $b1));
    $v2 = password_verify($pw, $b2);
    $vWrong = password_verify($pw . 'x', $b1);
}
?>
<!DOCTYPE html>
<html>
<head>
<title>Week 8 - Hash Lab</title>
<style>
 body{font-family:Arial,Helvetica,sans-serif;margin:40px;max-width:1000px;color:#1b2a4a}
 h1{margin-bottom:2px}
 .sub{margin-top:0;color:#5a6b85}
 .card{border:1px solid #d7deea;border-radius:8px;padding:18px 20px;margin:16px 0;background:#f3f6fb}
 input[type=text]{width:320px;padding:7px;border:1px solid #9aa7bd;border-radius:4px}
 button{background:#1b2a4a;color:#fff;border:0;padding:8px 18px;border-radius:4px;cursor:pointer}
 table{border-collapse:collapse;margin-top:10px;width:100%} td,th{border:1px solid #c7d0e0;padding:6px 10px;text-align:left;vertical-align:top}
 th{background:#1f3864;color:#fff}
 code{font-family:'Courier New',monospace;font-size:13px;word-break:break-all}
 .num{text-align:right;white-space:nowrap}
 .salt{background:#fcebdd;color:#b4561b;font-weight:bold}
 .meta{background:#e4e9f2;color:#1b2a4a;font-weight:bold}
 .hash{background:#e3f1ea;color:#2e7d5b}
 .ok{color:#2e7d5b;font-weight:bold} .no{color:#b03a2e;font-weight:bold}
</style>
</head>
<body>

<h1>Hash Lab</h1>
<p class="sub">Week 8 &mdash; what happens to a password before it reaches the database</p>

<div class="card">
<form method="post">
 <label for="pw"><b>Password to hash</b> (it's shown on screen, so use a fake one)</label><br><br>
 <input type="text" id="pw" name="pw" value="<?= h($pw) ?>" autofocus>
 <button type="submit">Hash it</button>
 <span class="sub">&nbsp; Try <code>password123</code>, then submit it again and compare.</span>
</form>
</div>

<?php if ($rows): ?>
<table>
 <tr><th>Method</th><th>Output (what would be stored)</th><th class="num">Time</th><th>Note</th></tr>
 <?php foreach ($rows as [$name, $out, $ms, $note]): ?>
  <tr><td><?= h($name) ?></td><td><code><?= h($out) ?></code></td>
      <td class="num"><?= number_format($ms, 4) ?> ms</td><td><?= h($note) ?></td></tr>
 <?php endforeach; ?>
</table>

<h3>Anatomy of the first bcrypt hash</h3>
<p><code><span class="meta"><?= h($bcrypt['algo']) ?></span><span class="meta"><?= h($bcrypt['cost']) ?></span>$<span class="salt"><?= h($bcrypt['salt']) ?></span><span class="hash"><?= h($bcrypt['hash']) ?></span></code></p>
<table>
 <tr><td class="meta"><code><?= h($bcrypt['algo']) ?></code></td><td>Algorithm: bcrypt</td></tr>
 <tr><td class="meta"><code><?= h($bcrypt['cost']) ?></code></td><td>Cost: 2<sup><?= (int)$bcrypt['cost'] ?></sup> = <?= number_format(2 ** (int)$bcrypt['cost']) ?> rounds</td></tr>
 <tr><td class="salt"><code><?= h($bcrypt['salt']) ?></code></td><td>Salt: 22 characters, random, made by password_hash(). Stored in the open.</td></tr>
 <tr><td class="hash"><code><?= h($bcrypt['hash']) ?></code></td><td>Hash: 31 characters, the result of running bcrypt on (salt + password)</td></tr>
</table>

<h3>password_verify()</h3>
<table>
 <tr><td><code>password_verify('<?= h($pw) ?>', first bcrypt)</code></td><td class="<?= $v1 ? 'ok' : 'no' ?>"><?= $v1 ? 'true' : 'false' ?></td><td class="num"><?= number_format($tv, 3) ?> ms</td></tr>
 <tr><td><code>password_verify('<?= h($pw) ?>', second bcrypt)</code></td><td class="<?= $v2 ? 'ok' : 'no' ?>"><?= $v2 ? 'true' : 'false' ?></td><td>different hash, same password, still true</td></tr>
 <tr><td><code>password_verify('<?= h($pw) ?>x', first bcrypt)</code></td><td class="<?= $vWrong ? 'ok' : 'no' ?>"><?= $vWrong ? 'true' : 'false' ?></td><td>one character off</td></tr>
</table>
<?php endif; ?>

</body>
</html>
