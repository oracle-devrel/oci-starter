package me.opc.mp.database;

import jakarta.json.bind.annotation.JsonbVisibility;
import jakarta.nosql.*;

@Entity
public record Dept (@Id int deptno,
                    @Column String dname,
                    @Column String loc) {
}