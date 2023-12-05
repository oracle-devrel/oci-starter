import os 
from app import app
from flask import jsonify
import psycopg2

@app.route('/dept')
def dept():
    try:
        conn = conn = psycopg2.connect(
            host=os.getenv('DB_URL'),
            database="postgres",
            user=os.getenv('DB_PASSWORD'),
            password=os.getenv('DB_PASSWORD'))
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
        return "Python - Flask / PostgreSQL"          

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)