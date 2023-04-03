import io
import json
import logging
import os
import oracledb

from fdk import response

def handler(ctx, data: io.BytesIO = None):
    a = []
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
    except Exception as e:
        logging.getLogger().info('error: ' + str(e))
    finally:
        cursor.close() 
        conn.close()     
    return response.Response(
        ctx, response_data=json.dumps(a),
        headers={"Content-Type": "application/json"}
    )

    