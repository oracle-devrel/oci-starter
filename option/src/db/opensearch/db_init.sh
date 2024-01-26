#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export OPENSEARCH_HOST=${DB_URL}
echo OPENSEARCH_HOST=$OPENSEARCH_HOST

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

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/_doc/10 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "10",
  "dname":  "ACCOUNTING",
  "loc":    "DUBAI"
}  
EOF

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/_doc/20 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "20",
  "dname":  "RESEARCH",
  "loc":    "OPENSEARCH"
}  
EOF

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/_doc/30 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "30",
  "dname":  "SALES",
  "loc":    "CAIRO"
}  
EOF

curl -0 -v -X PUT https://${OPENSEARCH_HOST}:9200/dept/_doc/40 \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "deptno": "40",
  "dname":  "OPERATIONS",
  "loc":    "JERUSALEM"
}  
EOF

curl https://${OPENSEARCH_HOST}:9200/dept/_search?size=1000&scroll=1m&pretty=true
