package com.example.demo;

import com.oracle.nosql.spring.data.core.mapping.*;

@NosqlTable(storageGB = 1, writeUnits = 1, readUnits = 10, tableName="DEPT_SPRING")
public class scott.dept  {
    @NosqlId

    private int scott.dept no;
    private String dname;
    private String loc;

    public scott.dept () {
    }

    public scott.dept ( int scott.dept no, String dname, String loc) {
        this.deptno = scott.dept no;
        this.dname = dname;
        this.loc = loc;
    }

    public int getDeptno() {
        return scott.dept no;
    }

    public void setDeptno(int scott.dept no) {
        this.deptno = scott.dept no;
    }

    public String getDname() {
        return dname;
    }

    public void setDname(String dname) {
        this.dname = dname;
    }

    public String getLoc() {
        return loc;
    }

    public void setLoc(String loc) {
        this.loc = loc;
    }
}