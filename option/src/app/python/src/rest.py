import os
import json
from app import app
from flask import jsonify
from flask import flash, request
import oracledb

@app.route('/dept')
def dept():
    try:
        conn = oracledb.connect(
          user=os.getenv('DB_USER'),
          password=os.getenv('DB_PASSWORD'),
          dsn=os.getenv('DB_URL'))
        print("Successfully connected to Oracle Database")
        cursor = conn.cursor()
        a = []
        for row in cursor.execute('select deptno, dname, loc from dept'):
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
        return "Python - Flask / Oracle"          

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)