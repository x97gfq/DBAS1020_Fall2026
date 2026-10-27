<?php
// DBAS 1020 - Week 8: the ONE place this app's database credentials live.
//
// Every page that needs MySQL does   require 'db.php';   and calls db().
// Change the account here and the whole app changes with it.
//
// The four parts of the connection:
//   host      'db'           - the Docker Compose service name. Inside the web
//                              container, "localhost" would mean the web container
//                              itself, where there is no MySQL.
//   user      'login_app'    - this app's OWN account, created in
//                              scripts/week8_secure_login_setup.sql. Not root.
//                              Not appuser. Run  SHOW GRANTS FOR 'login_app'@'%';
//   password  ...            - in a real app this comes from an environment
//                              variable or a secrets file outside the web root,
//                              never from a file in a public git repo.
//   database  'secure_login' - the default database for this connection.

// Throw an exception on every MySQL error instead of failing quietly
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

function db(): mysqli
{
    $conn = new mysqli(
        getenv('DB_HOST') ?: 'db',
        'login_app',
        getenv('LOGIN_APP_PASSWORD') ?: 'Login-App-Week8!',
        'secure_login'
    );
    $conn->set_charset('utf8mb4');
    return $conn;
}
