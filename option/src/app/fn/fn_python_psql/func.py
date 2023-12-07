import io
import json
import logging
import os
import psycopg2

from fdk import response

def handler(ctx, data: io.BytesIO = None):
    a = []
    try:
        conn = conn = psycopg2.connect(
            host=os.getenv('DB_URL'),
            database="postgres",
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'))      
        cursor = conn.cursor()
        cursor.execute('select deptno, dname, loc from dept');
        myresult = cursor.fetchall()
        for row in myresult:
            a.append( {"deptno": row[0], "dname": row[1], "loc": row[2]} )
        print(a)
    except Exception as e:
        logging.getLogger().info('error: ' + str(e))
    finally:
        cursor.close() 
        conn.close()     
    return response.Response(
        ctx, response_data=json.dumps(a),
        headers={"Content-Type": "application/json"}
    )


