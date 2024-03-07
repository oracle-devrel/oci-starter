{% import "java.j2_macro" as m with context %}
package com.example;

import io.micronaut.http.*;
import io.micronaut.http.annotation.*;
import io.micronaut.transaction.annotation.*;
import io.micronaut.scheduling.TaskExecutors;
import io.micronaut.scheduling.annotation.ExecuteOn;
import java.net.URI;

import jakarta.inject.Inject;
import static io.micronaut.http.HttpHeaders.LOCATION;
{{ m.import() }}

@ExecuteOn(TaskExecutors.IO)  
@Controller("/")  
class DeptController {
    {%- if db_family_type == "sql" %}
    @Inject
    DeptRepository deptRepository;
    {%- endif %}	
    {{ m.constructor() }}

    @Get(uri = "dept") 
    @Produces(MediaType.APPLICATION_JSON)
    List<Dept> dept() throws Exception {
        {%- if db_family_type == "sql" %}
        return deptRepository.findAll();
        {%- else %}
        {{ m.dept() }}
        {%- endif %}	   
    }

    @Get(uri = "info") 
    @Produces(MediaType.TEXT_PLAIN)
    String info() {
        return "Java - Micronaut - {{ dbName }}";
    }
}
