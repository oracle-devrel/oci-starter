package com.example;

import io.micronaut.data.annotation.*;
import io.micronaut.data.repository.CrudRepository;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import java.util.List;

{%- if db_family == "oracle" %}
@JdbcRepository(dialect = Dialect.ORACLE)
{%- elif db_family == "mysql" %}
@JdbcRepository(dialect = Dialect.MYSQL)
{%- elif db_family == "psql" %}
@JdbcRepository(dialect = Dialect.POSTGRES)
{%- elif db_family == "opensearch" %}
@JdbcRepository(dialect = Dialect.ANSI)
{%- endif %}	
public abstract class DeptRepository implements CrudRepository<Dept, Long> {
    {%- if db_family == "opensearch" %}
    // Query created by Micronaut is not understood by OpenSearch driver
    @Query("SELECT deptno,dname,loc from dept")
    abstract List<Dept> findDept();
    {%- endif %}	
}


