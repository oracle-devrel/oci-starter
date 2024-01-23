const fdk = require('@fnproject/fdk');
const Pool = require('pg').Pool

fdk.handle(async function() {
    console.log("debug2");
    const aDbURL= process.env.DB_URL.split(":");
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
    response = await pool.query("SELECT deptno, dname, loc FROM dept");
    return response.rows;
})
