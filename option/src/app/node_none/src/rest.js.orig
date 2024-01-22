const express = require('express')
const app = express()
const port = 8080

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / No Database')
})

app.get('/dept', (req, res) => {
    res.send('[ \
        { "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"}, \
        { "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"}, \
        { "deptno": "30", "dname": "SALES", "loc": "Brussels"}, \
        { "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"} \
    ]')
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
