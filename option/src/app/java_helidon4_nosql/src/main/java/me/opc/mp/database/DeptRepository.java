package me.opc.mp.database;

import jakarta.data.repository.Query;
import jakarta.data.repository.Repository;
import org.eclipse.jnosql.databases.oracle.mapping.OracleNoSQLRepository;

@Repository
public interface DeptRepository extends OracleNoSQLRepository<Dept, Integer> {
}