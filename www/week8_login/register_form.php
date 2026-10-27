<?php
require 'session.php';

$errors = $_SESSION['flash_errors'] ?? [];
$oldUsername = $_SESSION['old_username'] ?? '';

// Flash data is meant to be shown exactly once, so clear it as soon as we read it
unset($_SESSION['flash_errors'], $_SESSION['old_username']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Register</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<div class="container mt-5">
  <div class="row justify-content-center">
    <div class="col-md-5">
      <h2 class="mb-4">Create an Account</h2>
      <?php if (!empty($errors)): ?>
        <div class="alert alert-danger">
          <ul class="mb-0">
            <?php foreach ($errors as $error): ?>
              <li><?php echo h($error); ?></li>
            <?php endforeach; ?>
          </ul>
        </div>
      <?php endif; ?>
      <form action="process_register.php" method="post">
        <div class="mb-3">
          <label for="username" class="form-label">Username</label>
          <input type="text" class="form-control" id="username" name="username"
                 value="<?php echo h($oldUsername); ?>">
          <div class="form-text">3-30 letters, numbers or underscores.</div>
        </div>
        <div class="mb-3">
          <label for="password" class="form-label">Password</label>
          <input type="password" class="form-control" id="password" name="password">
          <div class="form-text">At least 12 characters. A short sentence works well.</div>
        </div>
        <div class="mb-3">
          <label for="confirm" class="form-label">Confirm password</label>
          <input type="password" class="form-control" id="confirm" name="confirm">
        </div>
        <button type="submit" class="btn btn-primary">Register</button>
        <a href="login_form.php" class="btn btn-link">I already have an account</a>
      </form>
    </div>
  </div>
</div>
</body>
</html>
