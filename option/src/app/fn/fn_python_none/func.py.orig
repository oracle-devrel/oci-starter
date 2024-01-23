import io
import json
import logging
import os

from fdk import response

def handler(ctx, data: io.BytesIO = None):
    d = [
        { "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"},
        { "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"},
        { "deptno": "30", "dname": "SALES", "loc": "Brussels"},
        { "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"}
    ]
    return response.Response(
        ctx, response_data=json.dumps(d),
        headers={"Content-Type": "application/json"}
    )
