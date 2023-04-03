<?php
// Initialize an array to store the data
$data = array();
$data[] = array("deptno"=>"10", "dname"=>"ACCOUNTING", "loc"=>"Seoul");
$data[] = array("deptno"=>"20", "dname"=>"RESEARCH", "loc"=>"Cape Town");
$data[] = array("deptno"=>"30", "dname"=>"SALES", "loc"=>"Brussels");
$data[] = array("deptno"=>"40", "dname"=>"OPERATIONS", "loc"=>"San Francisco");

// Encode the array as JSON and output it
echo json_encode($data);
?>
