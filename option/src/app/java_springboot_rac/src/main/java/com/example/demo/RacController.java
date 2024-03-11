package com.example.demo;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import java.sql.*;
import java.text.*;
import java.util.*;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;

@RestController

public class RacController {
  private String dbUrl;
  private String dbUser;
  private String dbPassword;
  static PoolDataSource pds = null;

  public record Continuity(int counter, String name, String connect_string, String instance, String creation_time) {
  };

  public class RacRunnable implements Runnable {
    String algorithm;
    String sleepBeforeCommit;
    int sleepInSec;
    String poolName;
    String name;

    public RacRunnable(String _algorithm, String _sleepBeforeCommit, int _sleepInSec, String _poolName, String _name) {
      algorithm = _algorithm;
      sleepBeforeCommit = _sleepBeforeCommit;
      sleepInSec = _sleepInSec;
      poolName = _poolName;
      name = _name;
    }

    public void run() {
      insertInTable(algorithm, sleepBeforeCommit, sleepInSec, poolName, name);
    }
  }

  @Autowired
  public RacController() throws SQLException {
    resetConnectionPool("jtac");
  }

  public void resetConnectionPool(String poolName) throws SQLException {
    pds = PoolDataSourceFactory.getPoolDataSource();
    pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
    // ex:
    // jdbc:oracle:thin:@(DESCRIPTION=(CONNECT_TIMEOUT=5)(TRANSPORT_CONNECT_TIMEOUT=3)(RETRY_COUNT=3)(ADDRESS_LIST=(LOAD_BALANCE=on)(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.2.5)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.2.106)(PORT=1521))(ADDRESS=(PROTOCOL=TCP)(HOST=10.0.2.32)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=PDB1.starterpriv.startervcn.oraclevcn.com)))
    String jdbc_url = System.getenv("JDBC_URL").replaceAll("SERVICE_NAME=.*?\\.", "SERVICE_NAME=" + poolName + ".");
    pds.setURL(jdbc_url);
    System.out.println("JDBC_URL=" + jdbc_url);
    pds.setUser(System.getenv("DB_USER"));
    pds.setPassword(System.getenv("DB_PASSWORD"));
    pds.setInitialPoolSize(1);
    pds.setMinPoolSize(1);
    pds.setMaxPoolSize(5);
  }

  public void commitAndSleep( String sleepBeforeCommit, int sleepInSec, Connection conn ) throws Exception {
    if( sleepBeforeCommit.equals("true") ) {
      Thread.sleep(sleepInSec*1000);
      conn.commit();
    } else {
      conn.commit();  
      Thread.sleep(sleepInSec*1000);
    }
  }

  public void insertInTable( String algorithm, String sleepBeforeCommit, int sleepInSec, String poolName, String name)
  {
    try {
      Connection conn = null;
      PreparedStatement pStmt = null;
      int loop = 60/sleepInSec;
      try {
        resetConnectionPool( poolName );
        if( algorithm.equals("1") ) {
          conn = pds.getConnection();
          conn.setAutoCommit(false);
          pStmt = conn.prepareStatement(
            """
                INSERT INTO continuity values( 
                  ?,
                  ?,
                  ?,
                  (SELECT sys_context('USERENV','INSTANCE_NAME') from dual),
                  sysdate)
            """);
          for( int i=0; i<loop; i++)
          {
            pStmt.setInt(1, i); 
            pStmt.setString(2, name); 
            pStmt.setString(3, poolName); 
            pStmt.executeUpdate();
            commitAndSleep( sleepBeforeCommit, sleepInSec, conn );
          }
        } else {
          for( int i=0; i<loop; i++)
          {
            conn = pds.getConnection();
            conn.setAutoCommit(false);
            pStmt = conn.prepareStatement(
              """
                  INSERT INTO continuity( counter, name, connect_string, instance, creation_time) values( 
                    ?,
                    ?,
                    ?,
                    (SELECT sys_context('USERENV','INSTANCE_NAME') from dual),
                    sysdate)
              """);          
            pStmt.setInt(1, i); 
            pStmt.setString(2, name); 
            pStmt.setString(3, poolName); 
            pStmt.executeUpdate();
            commitAndSleep( sleepBeforeCommit, sleepInSec, conn );
            pStmt.close();
            pStmt = null;
            conn.close();
            conn = null;
          }         
        }
      } finally {
        if (pStmt != null)
          pStmt.close();
        if (conn != null)
          conn.close();
      }
    } catch (Exception e) {
      System.err.println(e.getMessage());
      e.printStackTrace();
    }
  }

  @RequestMapping(value = "/insert", method = RequestMethod.GET, produces = { "text/plain" })
  public String insert(int threadNum, String sleepBeforeCommit, String algorithm, int sleepInSec, String poolName, String name) {
    if (threadNum == 1) {

      insertInTable(algorithm, sleepBeforeCommit, sleepInSec, poolName, name);
    } else {
      for (int i = 0; i < threadNum; i++) {
        Runnable r = new RacRunnable(algorithm, sleepBeforeCommit, sleepInSec, poolName, name + " - Thread " + i );
        new Thread(r).start();
      }
    }
    return name;
  }

  @RequestMapping(value = "/continuity", method = RequestMethod.GET, produces = { "application/json" })
  public List<Continuity> query(String name) {
    List<Continuity> a_cont = new ArrayList<Continuity>();
    try {
      Connection conn = null;
      PreparedStatement pStmt = null;
      ResultSet rset = null;
      try {
        conn = pds.getConnection();
        pStmt = conn.prepareStatement(
            "SELECT counter, name, connect_string, instance, creation_time FROM continuity where name like ? order by creation_time desc");
        pStmt.setString(1, name + "%");
        rset = pStmt.executeQuery();
        while (rset.next()) {
          a_cont.add(new Continuity(rset.getInt(1), rset.getString(2), rset.getString(3), rset.getString(4),
              rset.getString(5)));
        }
      } finally {
        if (rset != null)
          rset.close();
        if (pStmt != null)
          pStmt.close();
        if (conn != null)
          conn.close();
      }
    } catch (Exception e) {
      System.err.println(e.getMessage());
      e.printStackTrace();
    }
    return a_cont;
  }
}
