
package me.opc.mp.database;

import jakarta.persistence.Access;
import jakarta.persistence.AccessType;
import jakarta.persistence.Basic;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.NamedQueries;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;

/**
 * A Dept Type entity.
 */
@Entity(name = "Dept")
@Table(name = "dept")
@Access(AccessType.FIELD)
@NamedQueries({
        @NamedQuery(name = "getDept",
                    query = "SELECT t FROM Dept t"),
})
public class Dept {

    @Id
    @Column(name = "deptno", nullable = false, updatable = false)
    private int deptno;

    @Basic(optional = false)
    @Column(name = "dname")
    private String dname;

    @Basic(optional = false)
    @Column(name = "loc")
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
