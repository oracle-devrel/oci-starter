<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>

<head>
    <title>Simple JSP - OCI Starter</title>
    <script src="script.js"></script>
</head>

<body onload="loadRest()">
    <h2>OCI Starter - Simple JSP</h2>
    <p>Date: <%= (new java.util.Date()).toLocaleString()%></p>
    <h3>Rest Result </h3>
    <p>URL: <a href="dept" target="_blank">/app/dept</a></p>
    <div id="json"></div>
    <h3>Table format</h3>
    <div id="table"></div>
    <h3>Info</h3>
    <div id="info"></div>
</body>

</html>