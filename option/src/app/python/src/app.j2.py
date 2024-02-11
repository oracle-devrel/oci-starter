{% import "python.j2_macro" as m with context %}
import os
import traceback
from flask import Flask
from flask import jsonify
from flask_cors import CORS
{{ m.import() }}

app = Flask(__name__)
CORS(app)

@app.route('/dept')
def dept():
    {{ m.dept() }}     
    response = jsonify(a)
    response.status_code = 200
    return response   

@app.route('/info')
def info():
        return "Python - Flask - {{ dbName }}"          

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
