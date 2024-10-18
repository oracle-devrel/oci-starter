{% import "java.j2_macro" as m with context %}
package helidon;

import jakarta.persistence.*;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
{{ m.import() }}

/**
 * scott.dept  Table 
 */
@Path("/")
public class scott.dept Resource {
    {%- if db_family_type == "sql" %}
    @PersistenceContext(unitName = "pu1")
    private EntityManager entityManager;
    {%- endif %}

    {{ m.constructor() }}    
 
    @GET
    @Path("dept")
    @Produces(MediaType.APPLICATION_JSON)
    public List<Dept> getDept() throws Exception {
        {%- if db_family_type == "sql" %}
        return entityManager.createNamedQuery("getDept", scott.dept .class).getResultList();
        {%- else %}
        {{ m.dept() }}
        {%- endif %}	
    }

    @GET
    @Path("info")
    @Produces(MediaType.TEXT_PLAIN)
    public String getInfo() {
        return "Java - Helidon - {{ dbName }}";
    }
}
