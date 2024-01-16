#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

echo OPENSEARCH_HOST=${DB_URL}

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "mappings": {
    "properties": {
      "deptno": {
        "type": "text"
      },
      "dname": {
        "type": "text"
      },
      "loc": {
        "type": "keyword"
      }
    }
  }
}
EOF

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/10 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "10",
  "dname":  "ACCOUNTING",
  "loc":    "RYAD"
}  
EOF

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/20 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "20",
  "dname":  "RESEARCH",
  "loc":    "DUBAI"
}  
EOF

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/30 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "10",
  "dname":  "SALES",
  "loc":    "CAIRO"
}  
EOF

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/40 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "40",
  "dname":  "OPERATIONS",
  "loc":    "JERUSALEM"
}  
EOF
