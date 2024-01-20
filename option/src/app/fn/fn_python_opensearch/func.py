import io
import json
import os
import requests

from fdk import response

def handler(ctx, data: io.BytesIO = None):
    url = "https://"+os.getenv('DB_URL')+":9200/dept/_search?size=1000&scroll=1m&pretty=true"
    response = requests.get(url)
    j = response.json()
    d = []
    for hit in j["hits"]["hits"]:
        d.append( {"deptno": hit["_source"]["deptno"], "dname": hit["_source"]["dname"], "loc": hit["_source"]["loc"]} )

    return response.Response(
        ctx, response_data=json.dumps(d),
        headers={"Content-Type": "application/json"}
    )

