<?php

{%- if db_family == "none" %}
$data = array();
$data[] = array("deptno"=>"10", "dname"=>"ACCOUNTING", "loc"=>"Seoul");
$data[] = array("deptno"=>"20", "dname"=>"RESEARCH", "loc"=>"Cape Town");
$data[] = array("deptno"=>"30", "dname"=>"SALES", "loc"=>"Brussels");
$data[] = array("deptno"=>"40", "dname"=>"OPERATIONS", "loc"=>"San Francisco");

{%- else %}
// Load from php.ini
$db_url = get_cfg_var( "app.cfg.DB_URL" );
$db_user = get_cfg_var( "app.cfg.DB_USER" );
$db_password = get_cfg_var( "app.cfg.DB_PASSWORD" );

{%- if db_family == "oracle" %}
$conn = oci_connect( $db_user, $db_password, $db_url);
if (!$conn) {
    $e = oci_error();
    trigger_error(htmlentities($e['message'], ENT_QUOTES), E_USER_ERROR);
}

$stid = oci_parse($conn, 'SELECT deptno, dname, loc FROM dept');
if (!$stid) {
    $e = oci_error($conn);
    trigger_error(htmlentities($e['message'], ENT_QUOTES), E_USER_ERROR);
}

$r = oci_execute($stid);
if (!$r) {
    $e = oci_error($stid);
    trigger_error(htmlentities($e['message'], ENT_QUOTES), E_USER_ERROR);
}

$data = array();
while ($row = oci_fetch_array($stid, OCI_ASSOC+OCI_RETURN_NULLS)) {
    $data[] = $row;
}
oci_free_statement($stid);
oci_close($conn);

{%- elif db_family == "mysql" %}
$a = explode(":", $db_url);
$host = $a[0];

$conn = mysqli_connect($host, $db_user, $db_password, "db1");
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

$sql = "SELECT deptno, dname, loc FROM dept";
$result = mysqli_query($conn, $sql);

$data = array();
if (mysqli_num_rows($result) > 0) {
    while($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }
}
mysqli_close($conn);

{%- elif db_family == "psql" %}
$conn = pg_connect("host=" . $db_url . " dbname=postgres user=" . $db_user . " password=" . $db_password);
if (!$conn) {
    die("Connection failed" . pg_last_error($conn));
}

$sql = "SELECT deptno, dname, loc FROM dept";
$result = pg_query($conn, $sql);
$data = pg_fetch_all($result);

pg_free_result($result);
pg_close($conn);

{%- elif db_family == "opensearch" %}
$response = file_get_contents("https://" .  $db_url . ":9200/dept/_search?size=1000&scroll=1m&pretty=true");
$response = json_decode($response);

$data = array();
foreach ($response->hits->hits as $hit) {
  $data[] = array( "deptno" => $hit->_source->deptno, "dname" => $hit->_source->dname, "loc" => $hit->_source->loc );
}
{%- endif %}
{%- endif %}

header('Content-type: application/json');
echo json_encode($data);
?>
