import os 
from app import app
from flask import jsonify
import mysql.connector

@app.route('/dept')
def dept():
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        cursor.execute("SELECT deptno, dname, loc FROM dept")
        deptRows = cursor.fetchall()
        a = []
        for row in deptRows:
            a.append( {"deptno": row[0], "dname": row[1], "loc": row[2]} )
        print(a)
        response = jsonify(a)
        response.status_code = 200
        return response
    except Exception as e:
        print(e)
    finally:
        cursor.close() 
        conn.close()     

@app.route('/info')
def info():
        return "Python - Flask / MySQL"          

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)