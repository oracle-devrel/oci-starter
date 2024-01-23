package com.example.demo;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import java.sql.*;
import java.util.*;
import java.net.Inet4Address;

@RestController

public class DemoController {
  private String dbUrl;
  private String dbUser;
  private String dbPassword;

  public record Dept( int deptno, String dname, String loc ) {}; 

  @Autowired
  public DemoController(DbProperties properties) {
  }

  @RequestMapping(value = "/dept", method = RequestMethod.GET, produces = { "application/json" })  
  public List<Dept> query() {
    List<Dept> depts = new ArrayList<Dept>();
    depts.add(new Dept(10, "ACCOUNTING", "Seoul" ));
    depts.add(new Dept(20, "RESEARCH", "Cape Town" ));
    depts.add(new Dept(30, "SALES", "Brussels"));
    depts.add(new Dept(40, "OPERATIONS", "San Francisco"));
    return depts;
  }

  @RequestMapping(value = "/info", method = RequestMethod.GET, produces ={ "text/plain" })  
  public String info() throws Exception {
    String IP = (System.getenv("POD_IP")==null)?Inet4Address.getLocalHost().getHostAddress():System.getenv("POD_IP");
    return "Java - SpringBoot / No Database - IP " + IP; 
  }  
}
