package com.example.demo;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import java.sql.*;

import java.util.ArrayList;
import java.util.List;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;

@RestController

public class DemoController {
  private String dbUrl;
  private String dbUser;
  private String dbPassword;
  private String dbInfo;
  static PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();

  @Autowired
  public DemoController(DbProperties properties) throws SQLException {
    dbInfo = properties.getInfo();
    pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
    pds.setURL(System.getenv("JDBC_URL"));
    pds.setUser(System.getenv("DB_USER"));
    pds.setPassword(System.getenv("DB_PASSWORD"));
    pds.setInitialPoolSize(1);
    pds.setMinPoolSize(1);
    pds.setMaxPoolSize(5);    
  }

  @RequestMapping(value = "/dept", method = RequestMethod.GET, produces = { "application/json" })
  public List<Dept> query() {
    List<Dept> depts = new ArrayList<Dept>();
    try {
      Connection conn = null;
      Statement stmt = null;
      ResultSet rset = null;
      try {
        conn = pds.getConnection();
        stmt = conn.createStatement();
        rset = stmt.executeQuery("SELECT * FROM dept");
        while (rset.next()) {
          depts.add(new Dept(rset.getInt(1), rset.getString(2), rset.getString(3)));
        }
      } finally {
        if (rset != null)
          rset.close();
        if (stmt != null)
          stmt.close();
        if (conn != null)
          conn.close();
      }
    } catch (SQLException e) {
      System.err.println(e.getMessage());
    }
    return depts;
  }

  @RequestMapping(value = "/info", method = RequestMethod.GET, produces = { "text/plain" })
  public String info() {
    return "Java - SpringBoot";
  }
}
