import os
from typing import Any

import oracledb
from fastmcp import FastMCP  # Import FastMCP, the quickstart server base

mcp = FastMCP("MCP Server")  # Initialize an MCP server instance with a descriptive name

def log( s ): 
    print( s, flush=True )

@mcp.tool()
def send_email(to: str, subject: str, body: str) -> dict[str, str]:
    """Email sender tool"""
    log("<send_email>")
    log(f"<send_email>: to={to}, subject={subject}")

    return {
        "status": "sent",
        "message": f"Email sent to {to} with subject '{subject}'",
    }

@mcp.tool()
def get_dept() -> list[dict[str, Any]]:
    """Return all rows from the DEPT table."""
    log( "<get_dept>")
    user = os.getenv("TF_VAR_db_user")
    password = os.getenv("TF_VAR_db_password")
    dsn = os.getenv("DB_URL")

    if not user or not password or not dsn:
        raise ValueError("Missing DB_USER, DB_PASSWORD, or DB_URL environment variable")

    connection = oracledb.connect(user=user, password=password, dsn=dsn)
    log( "<get_dept>: connected to db")
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT DEPTNO, DNAME, LOC FROM DEPT ORDER BY DEPTNO")
            rows = cursor.fetchall()
            return [
                {"deptno": deptno, "dname": dname, "loc": loc}
                for deptno, dname, loc in rows
            ]
    finally:
        connection.close()

if __name__ == "__main__":
    # mcp.run(transport="stdio")  # Run the server, using standard input/output for communication
    mcp.run(transport="http", host="0.0.0.0", port=2025)
