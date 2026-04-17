{% import "java.j2_macro" as m with context %}
package com.example.fn;

import com.fnproject.fn.api.RuntimeContext;
import java.sql.*;
import com.fasterxml.jackson.databind.*;
{{ m.import() }}

public class HelloFunction {
    {{ m.constructor() }}

    public String handleRequest(String input) {
        {{ m.dept_string() }}
        return json;
    }
}
