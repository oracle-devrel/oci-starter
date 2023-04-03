package com.example;

import io.micronaut.http.*;
import io.micronaut.http.annotation.*;
import io.micronaut.transaction.annotation.*;
import io.micronaut.scheduling.TaskExecutors;
import io.micronaut.scheduling.annotation.ExecuteOn;
import javax.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.ArrayList;

import jakarta.inject.Inject;
import static io.micronaut.http.HttpHeaders.LOCATION;

@ExecuteOn(TaskExecutors.IO)  
@Controller("/")  
class DeptController {
    DeptController() { 
    }

    @Get(uri = "dept") 
    @Produces(MediaType.APPLICATION_JSON)
    List<Dept> dept() {
        List<Dept> depts = new ArrayList<Dept>();
        depts.add(new Dept(10, "ACCOUNTING", "Seoul" ));
        depts.add(new Dept(20, "RESEARCH", "Cape Town" ));
        depts.add(new Dept(30, "SALES", "Brussels"));
        depts.add(new Dept(40, "OPERATIONS", "San Francisco"));
        return depts;        
    }

    @Get(uri = "info") 
    @Produces(MediaType.TEXT_PLAIN)
    String info() {
        return "Java - Micronaut / No Database";
    }
}