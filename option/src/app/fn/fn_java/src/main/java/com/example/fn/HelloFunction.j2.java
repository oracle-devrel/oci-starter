{% import "java.j2_macro" as m with context %}
package com.example.fn;

import com.fnproject.fn.api.RuntimeContext;
import java.sql.*;
{{ m.import() }}

public class HelloFunction {
    public HelloFunction() {}

    public String handleRequest(String input) {
        {{ m.dept_string() }}
        response.getWriter().append( json );
    }
}
