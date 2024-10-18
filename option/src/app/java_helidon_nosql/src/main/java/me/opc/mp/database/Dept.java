package me.opc.mp.database;

import jakarta.json.bind.annotation.JsonbVisibility;
import jakarta.nosql.*;

@Entity
public record scott.dept  (@Id int scott.dept no,
                    @Column String dname,
                    @Column String loc) {
}