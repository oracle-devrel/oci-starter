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
    {{ m.constructor() }}

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        {{ m.dept_string() }}
        response.getWriter().append( json );
    }
}
