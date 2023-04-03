package me.opc.mp.database;

import java.util.List;

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

    @PersistenceContext(unitName = "pu1")
    private EntityManager entityManager;

    @GET
    @Path("dept")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Dept> getDept() {
        return entityManager.createNamedQuery("getDept", Dept.class).getResultList();
    }

    @GET
    @Path("info")
    @Produces(MediaType.TEXT_PLAIN)
    public String getInfo() {
        return "Java - Helidon";
    }
}
