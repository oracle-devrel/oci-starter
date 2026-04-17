package helidon;

import jakarta.persistence.*;

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
    private long deptno;

    @Basic(optional = false)
    @Column(name = "dname")
    private String dname;

    @Basic(optional = false)
    @Column(name = "loc")
    private String loc;

    public Dept() {
    }

    public Dept( long deptno, String dname, String loc) {
        this.deptno = deptno;
        this.dname = dname;
        this.loc = loc;
    }

    public long getDeptno() {
        return deptno;
    }

    public void setDeptno(long deptno) {
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
