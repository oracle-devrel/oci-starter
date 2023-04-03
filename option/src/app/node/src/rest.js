const express = require('express')
const app = express()
const port = 8080

const oracledb = require('oracledb');

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / Oracle')
})

app.get('/dept', async (req, res) => {
    let connection;

    try {
        connection = await oracledb.getConnection({ user: process.env.DB_USER, password: process.env.DB_PASSWORD, connectionString: process.env.DB_URL });
        result = await connection.execute(
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
    } catch (err) {
        console.error(err);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error(err);
            }
        }
    }
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})

