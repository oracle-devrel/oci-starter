package demo;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Servlet implementation class DeptServlet
 */
public class DeptServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

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
	    throws ServletException, IOException 
	{
		response.getWriter().append("""
 		[ 
			{ "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"},
			{ "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"},
			{ "deptno": "30", "dname": "SALES", "loc": "Brussels"},
			{ "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"}
		] 
		""");
	}
}
