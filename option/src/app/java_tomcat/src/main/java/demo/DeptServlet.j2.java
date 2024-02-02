{% import "java.j2_macro" as m with context %}
package demo;

import java.sql.*;

import com.fasterxml.jackson.databind.*;
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
		Class.forName("{{ jdbcDriverClassName }}");	
		{%- endif %}		
		{{ m.dept_no_return() }}
		// Jackson 
		ObjectMapper objectMapper = new ObjectMapper();
		String json = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(rows);
		System.out.println(json);
		response.getWriter().append( json );
	}
}
