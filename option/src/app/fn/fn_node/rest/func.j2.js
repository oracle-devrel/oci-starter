{% import "node.j2_macro" as m with context %}
const fdk = require('@fnproject/fdk');
{{ m.import() }}

fdk.handle(async function() {
    {{ m.dept() }}
    return rows;
})
