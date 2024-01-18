import os 
from app import app
from flask import jsonify
import requests
import traceback

@app.route('/dept')
def dept():
    try:
        url = "https://"+os.getenv('DB_URL')+":9200/dept/_search?size=1000&scroll=1m&pretty=true"
        response = requests.get(url)
        j = response.json()
        print(j, flush=True)
        a = []
        for hit in j["hits"]["hits"]:
            a.append( {"deptno": hit["_source"]["deptno"], "dname": hit["_source"]["dname"], "loc": hit["_source"]["loc"]} )
        response = jsonify(a)
        response.status_code = 200
        return response
    except Exception as e:
        print(traceback.format_exc(), flush=True)
        print(e, flush=True)

@app.route('/info')
def info():
        return "Python - Flask / OpenSearch" 

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

