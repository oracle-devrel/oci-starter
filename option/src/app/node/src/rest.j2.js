
const express = require('express')
const app = express()
const port = 8080

{% import "node.j2_macro" as macros %}
{{ macros.import() }}

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / {{ dbName }}')
})

app.get('/dept', async (req, res) => {
    {%- if db_family == "none" %}
      {{ macros.none() }}
    {%- elif db_family == "oracle" %}
      {{ macros.oracle() }}
    {%- elif db_family == "mysql" %}
      {{ macros.mysql() }}
    {%- elif db_family == "psql" %}
      {{ macros.psql() }}
    {%- elif db_family == "opensearch" %}
      {{ macros.opensearch() }}
    {%- endif %}
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
