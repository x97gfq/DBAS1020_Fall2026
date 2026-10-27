<?php
require 'session.php';

// Empty the server-side data, delete the browser's cookie, then destroy the session
$_SESSION = [];
$params = session_get_cookie_params();
setcookie(session_name(), '', time() - 3600, $params['path'], $params['domain'],
          $params['secure'], $params['httponly']);
session_destroy();
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Logged Out</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-5">
  <div class="row justify-content-center">
    <div class="col-md-6">
      <h2 class="mb-4">Logged Out</h2>
      <div class="alert alert-secondary">You have been logged out. The session no longer exists.</div>
      <a href="login_form.php" class="btn btn-primary me-2">Back to Login</a>
      <a href="dashboard.php" class="btn btn-outline-secondary">Try the Dashboard</a>
    </div>
  </div>
</div>
</body>
</html>
