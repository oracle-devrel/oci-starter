package com.example;

import io.micronaut.http.*;
import io.micronaut.http.annotation.*;
import io.micronaut.transaction.annotation.*;
import io.micronaut.scheduling.TaskExecutors;
import io.micronaut.scheduling.annotation.ExecuteOn;
import javax.validation.Valid;
import java.net.URI;
import java.util.List;

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
    @TransactionalAdvice
    List<Dept> dept() {
        return deptRepository.find();
    }

    @Get(uri = "info") 
    @Produces(MediaType.TEXT_PLAIN)
    String info() {
        return "Java - Micronaut";
    }
}