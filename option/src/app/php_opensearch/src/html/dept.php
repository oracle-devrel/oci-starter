<?php

// Connect to the database
$db_url = get_cfg_var( "app.cfg.DB_URL" );
$response = file_get_contents("https://" .  $db_url . ":9200/dept/_search?size=1000&scroll=1m&pretty=true");
$response = json_decode($response);

// Select all rows from the table
$result = array();
foreach ($response->hits->hits as $hit) {
  $result[] = array( "deptno" => $hit->_source->deptno, "dname" => $hit->_source->dname, "loc" => $hit->_source->loc );
}
// Encode the array as JSON and output it
header('Content-type: application/json');
echo json_encode($result);
?>
