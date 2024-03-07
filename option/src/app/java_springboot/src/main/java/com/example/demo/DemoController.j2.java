{%import"java.j2_macro"as m with context%}
package com.example.demo;

import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import java.net.Inet4Address;
import java.sql.*;
{{m.import()}}

@RestController

public class DemoController {
    {{ m.constructor() }}

    @RequestMapping(value = "/dept", method = RequestMethod.GET, produces = { "application/json" })  
    public List<Dept> query() throws Exception {
        {{ m.dept() }}
    }

    @RequestMapping(value = "/info", method = RequestMethod.GET, produces = { "text/plain" })
    public String info() throws Exception {
        String IP = (System.getenv("POD_IP") == null) ? Inet4Address.getLocalHost().getHostAddress():System.getenv("POD_IP");
        return "Java - SpringBoot - {{ dbName }} - IP=" + IP;
    }
}
