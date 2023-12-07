<?php

// Connect to the database
$db_url = get_cfg_var( "app.cfg.DB_URL" );
$db_user = get_cfg_var( "app.cfg.DB_USER" );
$db_password = get_cfg_var( "app.cfg.DB_PASSWORD" );

$conn = pg_connect("host=" . $db_url . " dbname=postgres user=" . $db_user . " password=" . $db_password);

// Check connection
if (!$conn) {
    die("Connection failed" . pg_last_error($conn));
}

// Select all rows from the table
$sql = "SELECT deptno, dname, loc FROM dept";
$result = pg_query($conn, $sql);
$results = pg_fetch_all($result);

// Encode the array as JSON and output it
header('Content-type: application/json');
echo json_encode($results);

// Close the connection
pg_free_result($result);
pg_close($conn);
?>
