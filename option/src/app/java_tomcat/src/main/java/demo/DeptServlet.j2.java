{% import "java.j2_macro" as m with context %}
package demo;

import java.sql.*;
import java.util.*;

import jakarta.json.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
{{ m.import() }}

/**
 * Servlet implementation class DeptServlet
 */
public class DeptServlet extends HttpServlet {
	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public DeptServlet() {
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		{%- if db_family_type == "sql" %}		
		int counter = 0;
		StringBuffer sb = new StringBuffer();
		sb.append("[");
		try {
			Class.forName("{{ jdbcDriverClassName }}");
			Connection conn = DriverManager.getConnection(System.getenv("JDBC_URL"), System.getenv("DB_USER"),
					System.getenv("DB_PASSWORD"));
			Statement stmt = conn.createStatement();
			ResultSet rs = stmt.executeQuery("SELECT deptno, dname, loc FROM dept");
			while (rs.next()) {
				if (counter++ > 0) {
					sb.append(",");
				}
				sb.append("{\"deptno\": \"" + rs.getInt(1) + "\", \"dname\": \"" + rs.getString(2) + "\", \"loc\": \""
						+ rs.getString(3) + "\"}");
			}
		} catch (Exception e) {
			System.err.println("Exception:" + e.getMessage());
			e.printStackTrace();
		}
		sb.append("]");
		response.getWriter().append(sb);
		{%- else %}		
		/*
		response.getWriter().append("""
			[ 
			   { "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"},
			   { "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"},
			   { "deptno": "30", "dname": "SALES", "loc": "Brussels"},
			   { "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"}
		   ] 
		   """);   
        */
		{{ m.dept_other_no_return() }}
		JsonArray builder = Json.createArrayBuilder();
		for(Dept row : rows) {
			builder.add(Json.createObjectBuilder().add("deptno", row.deptno()).add("dname", row.dname()).add("loc", row.loc()));
		}
		builder.build();
		response.getWriter().append( builder.toString() );
		{%- endif %}		
	}
}
