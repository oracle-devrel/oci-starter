import pymysql
import os 
from app import app
from flask import jsonify
from flask import flash, request
from flaskext.mysql import MySQL

@app.route('/dept')
def dept():
    try:
        conn = mysql.connect()
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT deptno, dname, loc FROM dept")
        deptRows = cursor.fetchall()
        response = jsonify(deptRows)
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

mysql = MySQL()
db_url = os.getenv('DB_URL')
mysql_host = db_url.split(':')[0]
app.config['MYSQL_DATABASE_USER'] = os.getenv('DB_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = os.getenv('DB_PASSWORD')
app.config['MYSQL_DATABASE_DB'] = 'db1'
app.config['MYSQL_DATABASE_HOST'] = mysql_host
mysql.init_app(app)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)