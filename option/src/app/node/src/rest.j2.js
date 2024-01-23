
const express = require('express')
const app = express()
const port = 8080

{% import "node.j2_macro" as m %}
{{ m.import() }}

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / {{ dbName }}')
})

app.get('/dept', async (req, res) => {
    {{ m.dept() }}
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
