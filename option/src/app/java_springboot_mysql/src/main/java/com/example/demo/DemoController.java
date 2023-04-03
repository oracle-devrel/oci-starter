package com.example.demo;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import java.sql.*;

import java.util.ArrayList;
import java.util.List;

@RestController

public class DemoController {
  private String dbUrl;
  private String dbUser;
  private String dbPassword;
  private String dbInfo;

  @Autowired
  public DemoController(DbProperties properties) {
    dbInfo = properties.getInfo();
    dbUrl = System.getenv("JDBC_URL");
    dbUser = System.getenv("DB_USER");
    dbPassword = System.getenv("DB_PASSWORD");
  }

  @RequestMapping(value = "/dept", method = RequestMethod.GET, produces = { "application/json" })  
  public List<Dept> query() {
    List<Dept> depts = new ArrayList<Dept>();
    try {
      Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
      Statement stmt = conn.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM dept");
      while (rs.next()) {
        depts.add(new Dept(rs.getInt(1), rs.getString(2), rs.getString(3) ));
      }
      rs.close();
      stmt.close();
      conn.close();
    } catch (SQLException e) {
      System.err.println(e.getMessage());
    }
    return depts;
  }

  @RequestMapping(value = "/info", method = RequestMethod.GET, produces ={ "text/plain" })  
  public String info() {
    return "Java - SpringBoot"; 
  }  
}
