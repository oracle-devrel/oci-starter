{% import "build.j2_macro" as m with context %}
{{ m.build_common() }}

curl -X PUT -H 'Authorization: Bearer access_token' -H "Accept:application/json" -F file=@myIntegration.iar -F type=application/octet-stream https://integration.us.oraclecloud.com/ic/api/integration/v1/integrations/archive

curl -H 'Authorization: Bearer xxxxxx'
 -H "Content-Type:application/json"
 -H "Accept: application/json"
 -X POST
 -d '{"commentStr":"add test Comment"}'
 https://example.com/ic/api/process/<version>/tasks/123456/comments
