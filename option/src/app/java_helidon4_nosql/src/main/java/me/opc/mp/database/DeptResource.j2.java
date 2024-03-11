# https://blogs.oracle.com/nosql/post/getting-started-accessing-oracle-nosql-database-using-jakarta-nosql
# 
{% import "java.j2_macro" as m with context %}
package me.opc.mp.database;

import jakarta.persistence.*;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.inject.*;
{{ m.import() }}

/**
 * Dept Table 
 */
@Path("/")
public class DeptResource {
    @Inject
    private DeptRepository deptRepository;

    @GET
    @Path("dept")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Dept> getDept() throws Exception {
        return deptRepository.findAll().toList();
    }

    @GET
    @Path("info")
    @Produces(MediaType.TEXT_PLAIN)
    public String getInfo() {
        return "Java - Helidon - {{ dbName }}";
    }
}
