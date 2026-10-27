<?php
require 'session.php';
require 'db.php';

$username = trim($_POST['username'] ?? '');
$password = $_POST['password'] ?? '';
$confirm  = $_POST['confirm'] ?? '';

// Server-side validation happens before we ever touch the database.
// (Browser-side checks are a convenience; anyone can skip them.)
$errors = [];
if (!preg_match('/^[A-Za-z0-9_]{3,30}$/', $username)) {
    $errors[] = 'Username must be 3-30 letters, numbers or underscores.';
}
if (strlen($password) < 12) {
    $errors[] = 'Password must be at least 12 characters.';
}
// bcrypt only uses the first 72 BYTES of a password and silently ignores the rest
if (strlen($password) > 72) {
    $errors[] = 'Password must be 72 characters or fewer.';
}
if ($password !== $confirm) {
    $errors[] = 'The two passwords do not match.';
}

if (!empty($errors)) {
    $_SESSION['flash_errors'] = $errors;
    $_SESSION['old_username'] = $username;
    header('Location: register_form.php');
    exit;
}

// This is the moment the plain password stops existing. password_hash() makes a
// new random salt, runs bcrypt, and returns one string holding the algorithm,
// the cost, the salt and the hash. That string is all we ever store.
$hash = password_hash($password, PASSWORD_DEFAULT);

try {
    $conn = db();
    $stmt = $conn->prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)');
    $stmt->bind_param('ss', $username, $hash);
    $stmt->execute();
    $stmt->close();
    $conn->close();
} catch (mysqli_sql_exception $e) {
    // 1062 = duplicate entry: the UNIQUE constraint on username did its job
    if ($e->getCode() === 1062) {
        $_SESSION['flash_errors'] = ['That username is already taken.'];
        $_SESSION['old_username'] = $username;
        header('Location: register_form.php');
        exit;
    }
    // Anything else: log the real error for us, show a vague one to the user
    error_log('Register failed: ' . $e->getMessage());
    $_SESSION['flash_errors'] = ['Something went wrong. Please try again.'];
    header('Location: register_form.php');
    exit;
}

$_SESSION['flash_notice'] = 'Account created. You can log in now.';
$_SESSION['old_username'] = $username;
header('Location: login_form.php');
exit;
