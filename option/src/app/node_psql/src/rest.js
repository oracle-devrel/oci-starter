const express = require('express')
const app = express()
const port = 8080

const Pool = require('pg').Pool

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / PostgreSQL')
})

app.get('/dept', (req, res) => {
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
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
