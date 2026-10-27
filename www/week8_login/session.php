<?php
// DBAS 1020 - Week 8: start the session the same, safe way on every page.
//
// The browser only ever holds a random session ID in a cookie (PHPSESSID).
// Everything we put in $_SESSION is stored on the SERVER, in the web container.

session_set_cookie_params([
    'lifetime' => 0,          // cookie dies when the browser closes
    'path'     => '/',
    'httponly' => true,       // JavaScript can't read it, so XSS can't steal it
    'samesite' => 'Lax',      // not sent on cross-site POSTs (helps against CSRF)
    'secure'   => false,      // set true once the site runs on HTTPS
]);

// Refuse session IDs the server never issued (blocks one kind of session fixation)
ini_set('session.use_strict_mode', '1');

session_start();

// Logged-in sessions expire after 15 minutes of doing nothing
const IDLE_LIMIT_SECONDS = 15 * 60;

function h($s): string
{
    return htmlspecialchars((string)$s, ENT_QUOTES);
}
