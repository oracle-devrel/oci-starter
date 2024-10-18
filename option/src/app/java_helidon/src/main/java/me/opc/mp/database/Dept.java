
package me.opc.mp.database;

import jakarta.persistence.*;

@Entity(name = "Dept")
@Table(name = "dept")
@Access(AccessType.FIELD)
@NamedQueries({
        @NamedQuery(name = "getDept",
                    query = "SELECT t FROM scott.dept  t"),
})
public class scott.dept  {

    @Id
    @Column(name = "deptno", nullable = false, updatable = false)
    private int scott.dept no;

    @Basic(optional = false)
    @Column(name = "dname")
    private String dname;

    @Basic(optional = false)
    @Column(name = "loc")
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
