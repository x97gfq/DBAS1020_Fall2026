<?php
require 'session.php';
require 'db.php';

$username = trim($_POST['username'] ?? '');
$password = $_POST['password'] ?? '';

// Server-side validation happens before we ever touch the database
$errors = [];
if ($username === '') {
    $errors[] = 'Username is required.';
}
if ($password === '') {
    $errors[] = 'Password is required.';
}

if (!empty($errors)) {
    $_SESSION['flash_errors'] = $errors;
    $_SESSION['old_username'] = $username;
    header('Location: login_form.php');
    exit;
}

$conn = db();

// Prepared statement: the username travels as DATA, never as part of the SQL (Week 7)
$stmt = $conn->prepare('SELECT id, username, password_hash FROM users WHERE username = ?');
$stmt->bind_param('s', $username);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

// password_verify() reads the algorithm, cost and salt out of the stored hash,
// re-hashes what was typed the same way, and compares. If the username doesn't
// exist we still verify against a dummy hash, so a wrong username takes as long
// as a wrong password and the response time doesn't reveal which names exist.
$dummyHash = '$2y$10$EEK4foSrvdtxaW7JoqxZQ.1q4rdjAB7d7XDzwebLMjtmx/q0Xixj6';
$ok = password_verify($password, $row['password_hash'] ?? $dummyHash) && $row;

if (!$ok) {
    $conn->close();
    // Same generic message either way - never reveal which part was wrong
    $_SESSION['flash_errors'] = ['Invalid username or password.'];
    $_SESSION['old_username'] = $username;
    header('Location: login_form.php');
    exit;
}

// login_app may UPDATE exactly one column. Try changing password_hash here instead
// and MySQL refuses with error 1143 - see the Class 2 lab.
$stmt = $conn->prepare('UPDATE users SET last_login_at = NOW() WHERE id = ?');
$stmt->bind_param('i', $row['id']);
$stmt->execute();
$stmt->close();
$conn->close();

// A fresh session ID on login prevents session fixation - an attacker who
// tricked a victim into using a known session ID can no longer reuse it
session_regenerate_id(true);
$_SESSION = [];   // start the logged-in session clean (drops leftover flash data)
$_SESSION['user_id'] = $row['id'];
$_SESSION['username'] = $row['username'];
$_SESSION['login_time'] = time();
$_SESSION['last_seen'] = time();

// process_login.php never renders a page itself - it only validates and
// redirects (the POST/Redirect/GET pattern), so refreshing the result
// page never resubmits the form
header('Location: dashboard.php');
exit;
