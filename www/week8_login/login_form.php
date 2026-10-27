<?php
// session.php starts the session - this page reads (and clears) any flash data
// left behind by process_login.php, process_register.php or dashboard.php
require 'session.php';

$errors = $_SESSION['flash_errors'] ?? [];
$notice = $_SESSION['flash_notice'] ?? null;
$oldUsername = $_SESSION['old_username'] ?? '';

// Flash data is meant to be shown exactly once, so clear it as soon as we read it
unset($_SESSION['flash_errors'], $_SESSION['flash_notice'], $_SESSION['old_username']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Login</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-5">
  <div class="row justify-content-center">
    <div class="col-md-4">
      <h2 class="mb-4">Login</h2>
      <?php if ($notice): ?>
        <div class="alert alert-info"><?php echo h($notice); ?></div>
      <?php endif; ?>
      <?php if (!empty($errors)): ?>
        <div class="alert alert-danger">
          <ul class="mb-0">
            <?php foreach ($errors as $error): ?>
              <li><?php echo h($error); ?></li>
            <?php endforeach; ?>
          </ul>
        </div>
      <?php endif; ?>
      <form action="process_login.php" method="post">
        <div class="mb-3">
          <label for="username" class="form-label">Username</label>
          <!-- The username is repopulated from the failed attempt; the password never is -->
          <input type="text" class="form-control" id="username" name="username"
                 value="<?php echo h($oldUsername); ?>">
        </div>
        <div class="mb-3">
          <label for="password" class="form-label">Password</label>
          <input type="password" class="form-control" id="password" name="password">
        </div>
        <button type="submit" class="btn btn-primary">Login</button>
        <a href="register_form.php" class="btn btn-link">Create an account</a>
      </form>
    </div>
  </div>
</div>
</body>
</html>
