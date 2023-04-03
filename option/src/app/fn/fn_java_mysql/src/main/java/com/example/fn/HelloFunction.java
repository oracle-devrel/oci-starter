package com.example.fn;

import java.sql.*;
import com.fnproject.fn.api.RuntimeContext;

public class HelloFunction {
  private final String dbUser = System.getenv().get("DB_USER");
  private final String dbPassword = System.getenv().get("DB_PASSWORD");
  private final String dbUrl = System.getenv().get("DB_URL");

  public HelloFunction() {}

  public String handleRequest(String input) {
    int counter = 0;
    StringBuffer sb = new StringBuffer();
    sb.append("[");
    try {
      System.out.println("Before classForName");
      Class.forName("com.mysql.cj.jdbc.Driver");
      Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
      System.out.println("After connection");
      Statement stmt = conn.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM dept");
      while (rs.next()) {
        if (counter++ > 0) {
          sb.append(",");
        }
        sb.append("{\"deptno\": \"" + rs.getInt(1) + "\", \"dname\": \"" + rs.getString(2) + "\", \"loc\": \""
            + rs.getString(3) + "\"}");
      }
      stmt.close();
      conn.close();
    } catch (Exception e) {
      System.err.println("Exception:" + e.getMessage());
      e.printStackTrace();
    }
    sb.append("]");
    return sb.toString();
  }

}
