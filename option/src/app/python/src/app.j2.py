import os
import traceback
from flask import Flask
from flask import jsonify
from flask_cors import CORS

{%- if db_family == "oracle" %}
import oracledb
{%- elif db_family == "mysql" %}
import mysql.connector
{%- elif db_family == "psql" %}
import psycopg2
{%- elif db_family == "opensearch" %}
import requests
{%- endif %}

app = Flask(__name__)
CORS(app)

@app.route('/dept')
def dept():
    {%- if db_family == "none" %}
    return jsonify( [ 
        { "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"},
        { "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"},
        { "deptno": "30", "dname": "SALES", "loc": "Brussels"},
        { "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"}
    ] )
    {%- else %}
    try:
        {%- if db_family == "oracle" %}
        conn = oracledb.connect(
          user=os.getenv('DB_USER'),
          password=os.getenv('DB_PASSWORD'),
          dsn=os.getenv('DB_URL'))
        {%- elif db_family == "mysql" %}
        db_url = os.getenv('DB_URL')
        mysql_host = db_url.split(':')[0]
        config = {
            "host": mysql_host,
            "port": 3306,
            "database": "db1",
            "user": os.getenv('DB_USER'),
            "password": os.getenv('DB_PASSWORD'),
            "charset": "utf8",
            "use_unicode": True,
            "get_warnings": True
        }    
        conn = mysql.connector.connect(**config)        
        {%- elif db_family == "psql" %}
        conn = psycopg2.connect(
            host=os.getenv('DB_URL'),
            database="postgres",
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            sslmode='require' )
        {%- elif db_family == "opensearch" %}
        url = "https://"+os.getenv('DB_URL')+":9200/dept/_search?size=1000&scroll=1m&pretty=true"
        response = requests.get(url)
        j = response.json()
        print(j, flush=True)
        a = []
        for hit in j["hits"]["hits"]:
            a.append( {"deptno": hit["_source"]["deptno"], "dname": hit["_source"]["dname"], "loc": hit["_source"]["loc"]} )
        {%- endif %}

        {%- if db_family != "opensearch" %}
        print("Successfully connected to database", flush=True)
        cursor = conn.cursor()
        cursor.execute("SELECT deptno, dname, loc FROM dept")
        deptRows = cursor.fetchall()
        a = []
        for row in deptRows:
            a.append( {"deptno": row[0], "dname": row[1], "loc": row[2]} )        
        {%- endif %}
        print(a, flush=True)
        response = jsonify(a)
        response.status_code = 200
        return response
    except Exception as e:
        print(traceback.format_exc(), flush=True)
        print(e, flush=True)
    {%- if db_family != "opensearch" %}
    finally:
        cursor.close() 
        conn.close() 
    {%- endif %}
    {%- endif %}        

@app.route('/info')
def info():
        return "Python - Flask / {{ dbName }}"          

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
