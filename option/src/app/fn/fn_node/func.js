const fdk = require('@fnproject/fdk');
const oracledb = require('oracledb');

fdk.handle(async function() {
    let connection;
    let arr = [];

    try {
        connection = await oracledb.getConnection({ user: process.env.DB_USER, password: process.env.DB_PASSWORD, connectionString: process.env.DB_URL });
        result = await connection.execute(
            `select deptno, dname, loc from DEPT`,
            [],
            { resultSet: true, outFormat: oracledb.OUT_FORMAT_OBJECT });
        const rs = result.resultSet;
        let row;
        while ((row = await rs.getRow())) {
            arr.push(row);
        }
        await rs.close();
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

    return arr;
})
