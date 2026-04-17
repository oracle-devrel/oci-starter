{% import "python.j2_macro" as m with context %}
import io
import json
import logging
import os
import traceback
{{ m.import() }}

from fdk import response

def handler(ctx, data: io.BytesIO = None):
    {{ m.dept() }}
    return response.Response(
        ctx, response_data=json.dumps(a),
        headers={"Content-Type": "application/json"}
    )

    