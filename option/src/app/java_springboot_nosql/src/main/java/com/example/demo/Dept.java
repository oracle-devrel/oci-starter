package com.example.demo;

import com.oracle.nosql.spring.data.core.mapping.*;

@NosqlTable(storageGB = 1, writeUnits = 1, readUnits = 10, tableName="DEPT_SPRING")
public class Dept {
    @NosqlId

    private int deptno;
    private String dname;
    private String loc;

    public Dept() {
    }

    public Dept( int deptno, String dname, String loc) {
        this.deptno = deptno;
        this.dname = dname;
        this.loc = loc;
    }

    public int getDeptno() {
        return deptno;
    }

    public void setDeptno(int deptno) {
        this.deptno = deptno;
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