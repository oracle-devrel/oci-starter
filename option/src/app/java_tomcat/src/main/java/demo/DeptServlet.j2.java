package demo;

import java.sql.*;

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
		int counter = 0;
		StringBuffer sb = new StringBuffer();
		sb.append("[");
		try {
			Class.forName("{{ jdbcDriverClassName }}");
			Connection conn = DriverManager.getConnection(System.getenv("JDBC_URL"), System.getenv("DB_USER"),
					System.getenv("DB_PASSWORD"));
			Statement stmt = conn.createStatement();
			ResultSet rs = stmt.executeQuery("SELECT * FROM dept");
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
	}
}
