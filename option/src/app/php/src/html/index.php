<!DOCTYPE html>
<html>

<head>
    <title>OCI Starter - Simple PHP</title>
    <script src="script.js"></script>
</head>

<body onload="loadRest()">
    <h2>OCI Starter - Simple PHP</h2>
    <p></p>
    <?php echo date("F j, Y, g:i a"); ?> 
    <h3>Rest Result </h3>
    <p>URL: <a href="dept" target="_blank">dept</a></p>
    <div id="json"></div>
    <h3>Table format</h3>
    <div id="table"></div>
    <h3>Info</h3>
    <div id="info"></div>
</body>

</html>