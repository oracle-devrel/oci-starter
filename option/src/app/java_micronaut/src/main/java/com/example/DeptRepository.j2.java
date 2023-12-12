package com.example;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;

{%- if db_family == "oracle" %}
@JdbcRepository(dialect = Dialect.ORACLE)
{%- elif db_family == "mysql" %}
@JdbcRepository(dialect = Dialect.MYSQL)
{%- elif db_family == "psql" %}
@JdbcRepository(dialect = Dialect.POSTGRES)
{%- endif %}	
public abstract class DeptRepository implements CrudRepository<Dept, Long> {
}


