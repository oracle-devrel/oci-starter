package me.opc.mp.database;

import java.util.List;
import java.util.ArrayList;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

/**
 * Dept Table 
 */
@Path("/")
public class DeptResource {

    @GET
    @Path("dept")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Dept> getDept() {
        List<Dept> d = new ArrayList<Dept>();
        d.add(new Dept(10, "ACCOUNTING", "Seoul" ));
        d.add(new Dept(20, "RESEARCH", "Cape Town" ));
        d.add(new Dept(30, "SALES", "Brussels"));
        d.add(new Dept(40, "OPERATIONS", "San Francisco"));
        return d;        
    }

    @GET
    @Path("info")
    @Produces(MediaType.TEXT_PLAIN)
    public String getInfo() {
        return "Java - Helidon / No Database";
    }
}
