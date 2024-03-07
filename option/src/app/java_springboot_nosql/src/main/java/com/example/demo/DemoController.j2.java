{%import"java.j2_macro"as m with context%}
package com.example.demo;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import java.net.Inet4Address;
import java.sql.*;
{{m.import()}}

@RestController
public class DemoController {
    @Autowired
    private final DemoRepository repository;

    DemoController(DemoRepository repository) {
        this.repository = repository;
        try {
            System.out.println("Insert row " + repository.save(new Dept(10, "ACCOUNTING", "BRUSSELS")));
            System.out.println("Insert row " + repository.save(new Dept(20, "RESEARCH", "SPRING NOSQL")));
            System.out.println("Insert row " + repository.save(new Dept(30, "SALES", "ROME")));
            System.out.println("Insert row " + repository.save(new Dept(40, "OPERATIONS", "MADRID")));
        } catch (Exception e ) {
            System.err.println("Exception:" + e.getMessage());
            e.printStackTrace();
        }
    }

    @RequestMapping(value = "/dept", method = RequestMethod.GET, produces = { "application/json" })
    public Iterable<Dept> query() throws Exception {
        return repository.findAll();
    }

    @RequestMapping(value = "/info", method = RequestMethod.GET, produces = { "text/plain" })
    public String info() throws Exception {
        String IP = (System.getenv("POD_IP") == null) ? Inet4Address.getLocalHost().getHostAddress():System.getenv("POD_IP");
        return "Java - SpringBoot - NoSQL - IP=" + IP;
    }
}