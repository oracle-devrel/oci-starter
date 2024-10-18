{% import "java.j2_macro" as m with context %}
package me.opc.mp.database;

import jakarta.persistence.*;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.inject.*;
import jakarta.annotation.*;
{{ m.import() }}

/**
 * scott.dept  Table 
 */
@Path("/")
public class scott.dept Resource {
    @Inject
    private scott.dept Repository repository;

    @PostConstruct 
    private void init() {
        try {
            System.out.println("Insert row " + repository.save(new scott.dept (10, "ACCOUNTING", "BRUSSELS")));
            System.out.println("Insert row " + repository.save(new scott.dept (20, "RESEARCH", "JAKARTA NOSQL")));
            System.out.println("Insert row " + repository.save(new scott.dept (30, "SALES", "ROME")));
            System.out.println("Insert row " + repository.save(new scott.dept (40, "OPERATIONS", "MADRID")));
        } catch (Exception e ) {
            System.err.println("Init Exception:" + e.getMessage());
            e.printStackTrace();
        }
    }

    @GET
    @Path("dept")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Dept> getDept() throws Exception {
        return repository.findAll().toList();
    }

    @GET
    @Path("info")
    @Produces(MediaType.TEXT_PLAIN)
    public String getInfo() {
        return "Java - Helidon - {{ dbName }}";
    }
}
