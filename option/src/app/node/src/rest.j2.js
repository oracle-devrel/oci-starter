
const express = require('express')
const app = express()
const port = 8080

{% import "node.j2_macro" as m %}
{{ m.import() }}

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / {{ dbName }}')
})

app.get('/dept', async (req, res) => {
    {%- if db_family == "none" %}
      {{ m.nodb() }}
    {%- elif db_family == "oracle" %}
      {{ m.oracle() }}
    {%- elif db_family == "mysql" %}
      {{ m.mysql() }}
    {%- elif db_family == "psql" %}
      {{ m.psql() }}
    {%- elif db_family == "opensearch" %}
      {{ m.opensearch() }}
    {%- endif %}
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
