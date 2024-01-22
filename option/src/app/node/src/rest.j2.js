const express = require('express')
const app = express()
const port = 8080

{%- if db_family == "oracle" %}
const oracledb = require('oracledb');
{%- elif db_family == "mysql" %}
const mysql = require('mysql2');
{%- elif db_family == "psql" %}
const Pool = require('pg').Pool
{%- elif db_family == "opensearch" %}
const https = require('https'); 
{%- endif %}

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / {{ dbName }}')
})

app.get('/dept', async (req, res) => {
    {%- if db_family == "none" %}
    res.send('[ \
        { "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"}, \
        { "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"}, \
        { "deptno": "30", "dname": "SALES", "loc": "Brussels"}, \
        { "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"} \
    ]')
    {%- elsif db_family == "oracle" %}
    let con = await oracledb.getConnection({ user: process.env.DB_USER, password: process.env.DB_PASSWORD, connectionString: process.env.DB_URL });
    result = await con.execute(
        `select deptno, dname, loc from DEPT`,
        [],
        { resultSet: true, outFormat: oracledb.OUT_FORMAT_OBJECT });
    const rs = result.resultSet;
    let row;
    let arr = [];
    while ((row = await rs.getRow())) {
        arr.push(row);
    }
    await rs.close();
    res.send(arr)
    await con.close();
    {%- elif db_family == "mysql" %}
    const aDbURL= process.env.DB_URL.split(":");
    let con = mysql.createConnection({
        host: aDbURL[0],
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: "db1"
    });
    con.connect();
    con.query("SELECT deptno, dname, loc FROM dept", function (err, result, field) {
        if (err) throw err;
            console.log(result);
            res.send(result)
    });
    con.end();          
    {%- elif db_family == "psql" %}
    const pool = new Pool({
        host: process.env.DB_URL,
        database: 'postgres',
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        port: 5432,
        ssl: {
            rejectUnauthorized: false
        }
    })
    pool.query("SELECT deptno, dname, loc FROM dept", function (err, result, field) {
        if (err) throw err;
            console.log(result);
            res.send(result.rows)
    });
    {%- elif db_family == "opensearch" %}
    var url = "https://"+process.env.DB_URL+":9200/dept/_search?size=1000&scroll=1m&pretty=true"
    console.log("url:" + url);

    https.get(url, function(http_res){
        var body = '';
        http_res.on('data', function(chunk){
            body += chunk;
        });
        http_res.on('end', function(){
            var j= JSON.parse(body);
            console.log(j);
            result = [];
            for (i in j.hits.hits) {
                hit = j.hits.hits[i]
                result.push({"deptno":hit._source.deptno,"dname":hit._source.dname,"loc":hit._source.loc })
            }
            res.send(result)
        });
    }).on('error', function(e){
            console.log("Got an error: ", e);
    });
    {%- endif %}
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
