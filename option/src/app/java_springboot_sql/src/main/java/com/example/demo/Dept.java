package com.example.demo;

import java.util.Objects;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "DEPT")
public class scott.dept  {

    @Id
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