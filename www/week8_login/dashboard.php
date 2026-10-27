<?php
require 'session.php';
require 'db.php';

// This is the page being protected - anyone without an active session
// gets bounced straight back to the login form
if (!isset($_SESSION['user_id'])) {
    $_SESSION['flash_notice'] = 'Please log in to continue.';
    header('Location: login_form.php');
    exit;
}

// Idle too long? Throw the session away and make them log in again
if (time() - $_SESSION['last_seen'] > IDLE_LIMIT_SECONDS) {
    $_SESSION = [];
    session_regenerate_id(true);
    $_SESSION['flash_notice'] = 'Your session expired. Please log in again.';
    header('Location: login_form.php');
    exit;
}
$_SESSION['last_seen'] = time();

// TEACHING ONLY: show what the database actually stores for this user.
// A real app would never put a hash on screen.
$conn = db();
$stmt = $conn->prepare('SELECT password_hash, created_at, last_login_at FROM users WHERE id = ?');
$stmt->bind_param('i', $_SESSION['user_id']);
$stmt->execute();
$me = $stmt->get_result()->fetch_assoc();
$stmt->close();
$conn->close();

$info = password_get_info($me['password_hash']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-5">
  <div class="row justify-content-center">
    <div class="col-md-8">
      <h2 class="mb-4">Dashboard</h2>
      <div class="alert alert-success">Welcome back, <?php echo h($_SESSION['username']); ?>!</div>
      <p>This page only renders while a session is active. Try opening this URL in a private/incognito window.</p>

      <h5 class="mt-4">What the server remembers about you <small class="text-muted">($_SESSION)</small></h5>
      <table class="table table-sm table-bordered">
        <tr><th>Session ID (your PHPSESSID cookie)</th><td><code><?php echo h(session_id()); ?></code></td></tr>
        <?php foreach ($_SESSION as $key => $value): ?>
          <tr><th><?php echo h($key); ?></th><td><code><?php echo h($value); ?></code></td></tr>
        <?php endforeach; ?>
      </table>

      <h5 class="mt-4">What the database stores about you <small class="text-muted">(secure_login.users)</small></h5>
      <table class="table table-sm table-bordered">
        <tr><th>password_hash</th><td><code><?php echo h($me['password_hash']); ?></code></td></tr>
        <tr><th>algorithm / cost</th><td><?php echo h($info['algoName']); ?> / <?php echo h($info['options']['cost'] ?? '-'); ?></td></tr>
        <tr><th>created_at</th><td><?php echo h($me['created_at']); ?></td></tr>
        <tr><th>last_login_at</th><td><?php echo h($me['last_login_at']); ?></td></tr>
      </table>

      <a href="logout.php" class="btn btn-outline-danger">Logout</a>
    </div>
  </div>
</div>
</body>
</html>
