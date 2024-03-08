package me.opc.mp.database;

import jakarta.json.bind.annotation.JsonbVisibility;
import jakarta.nosql.*;

@Entity
@JsonbVisibility(FieldAccessStrategy.class)
public class Dept {
    @Id
    private int deptno;
    @Column
    private String dname;
    @Column
    private String loc;
}