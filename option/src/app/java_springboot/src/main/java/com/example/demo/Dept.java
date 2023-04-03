package com.example.demo;

public class Dept {
    int deptno;
    String dname;
    String loc;

    Dept(int _deptno, String _dname, String _loc) {
        this.deptno = _deptno;
        this.dname = _dname;
        this.loc = _loc;
    }

    public int getDeptno() {
        return deptno;
    }

    public String getDname() {
        return dname;
    }

    public String getLoc() {
        return loc;
    }
}
