const fdk = require('@fnproject/fdk');
const mysql = require('mysql2/promise');

fdk.handle(async function() {
    console.log("debug2");
    const aDbURL= process.env.DB_URL.split(":");
    const connection = await mysql.createConnection({
        host: aDbURL[0],
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: "db1"
    });
    const [rows, fields] = await connection.execute("SELECT deptno, dname, loc FROM dept");
    connection.end();   
    return rows;
})

