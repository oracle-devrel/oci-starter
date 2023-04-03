<?php

// Connect to the database
$db_url = get_cfg_var( "app.cfg.DB_URL" );
$db_user = get_cfg_var( "app.cfg.DB_USER" );
$db_password = get_cfg_var( "app.cfg.DB_PASSWORD" );
$a = explode(":", $db_url);
$host = $a[0];

$conn = mysqli_connect($host, $db_user, $db_password, "db1");

// Check connection
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

// Select all rows from the table
$sql = "SELECT deptno, dname, loc FROM dept";
$result = mysqli_query($conn, $sql);

// Initialize an array to store the data
$data = array();

if (mysqli_num_rows($result) > 0) {
    // Store the data for each row in the array
    while($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }
}

// Encode the array as JSON and output it
echo json_encode($data);

// Close the connection
mysqli_close($conn);

?>
