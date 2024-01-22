const express = require('express')
const app = express()
const port = 8080

const mysql = require('mysql2');

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / MySQL')
})

app.get('/dept', (req, res) => {
    const aDbURL= process.env.DB_URL.split(":");
    var con = mysql.createConnection({
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
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
