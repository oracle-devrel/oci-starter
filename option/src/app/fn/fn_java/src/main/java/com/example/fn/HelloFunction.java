package com.example.fn;

import java.sql.*;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import com.fnproject.fn.api.RuntimeContext;

public class HelloFunction {
  private PoolDataSource poolDataSource;

  private final String dbUser = System.getenv().get("DB_USER");
  private final String dbPassword = System.getenv().get("DB_PASSWORD");
  private final String dbUrl = System.getenv().get("DB_URL");

  final static String CONN_FACTORY_CLASS_NAME = "oracle.jdbc.pool.OracleDataSource";

  public HelloFunction() {
    System.out.println("Setting up pool data source");
    poolDataSource = PoolDataSourceFactory.getPoolDataSource();
    try {
      poolDataSource.setConnectionFactoryClassName(CONN_FACTORY_CLASS_NAME);
      poolDataSource.setURL(dbUrl);
      poolDataSource.setUser(dbUser);
      poolDataSource.setPassword(dbPassword);
      poolDataSource.setConnectionPoolName("UCP_POOL");
    } catch (SQLException e) {
      System.out.println("Pool data source error!");
      e.printStackTrace();
    }
    System.out.println("Pool data source setup...");
    System.setProperty("oracle.jdbc.fanEnabled", "false");
  }

  public String handleRequest(String input) {
    // System.out.println("dbUser=" + dbUser + " / dbPassword=" + dbPassword + " / dbUurl=" + dbUrl);
    int counter = 0;
    StringBuffer sb = new StringBuffer();
    sb.append("[");
    try {
      System.out.println("Before classForName");
      Class.forName("oracle.jdbc.driver.OracleDriver");
      Connection conn = poolDataSource.getConnection();
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
