package com.example;

import io.micronaut.http.*;
import io.micronaut.http.annotation.*;
import io.micronaut.transaction.annotation.*;
import io.micronaut.scheduling.TaskExecutors;
import io.micronaut.scheduling.annotation.ExecuteOn;
import java.net.URI;
import java.util.*;

import jakarta.inject.Inject;
import static io.micronaut.http.HttpHeaders.LOCATION;

@ExecuteOn(TaskExecutors.IO)  
@Controller("/")  
class DeptController {
    @Inject
    DeptRepository deptRepository;

    DeptController() { 
    }

    @Get(uri = "dept") 
    @Produces(MediaType.APPLICATION_JSON)
    List<Dept> dept() {
        {%- if db_family == "none" %}
        List<Dept> a = new ArrayList<Dept>();
        a.add(new Dept(10, "ACCOUNTING", "Seoul" ));
        a.add(new Dept(20, "RESEARCH", "Cape Town" ));
        a.add(new Dept(30, "SALES", "Brussels"));
        a.add(new Dept(40, "OPERATIONS", "San Francisco"));
        return a;          
        {%- elif db_family == "opensearch" %}
        // Use a custom find to be able to specify the exact SQL command.
        return deptRepository.findDept();
        {%- else %}
        return deptRepository.findAll();
        {%- endif %}	
    }

    @Get(uri = "info") 
    @Produces(MediaType.TEXT_PLAIN)
    String info() {
        return "Java - Micronaut / {{ dbName }}";
    }
}
