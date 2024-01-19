<?php

// Connect to the database
$db_url = get_cfg_var( "app.cfg.DB_URL" );
$response = file_get_contents("https://" .  db_url . ":9200/dept/_search?size=1000&scroll=1m&pretty=true");
$response = json_decode($response);

// Select all rows from the table
$result = array();
foreach ($hit as $response.hits.hits) {
  $d = array(
    "deptno" => $hit["deptno"],
    "dname" => $hit["dname"],
    "loc" => $hit["loc"]
  );
  array_push( $result, $d );
}
// Encode the array as JSON and output it
header('Content-type: application/json');
echo json_encode($results);
?>
