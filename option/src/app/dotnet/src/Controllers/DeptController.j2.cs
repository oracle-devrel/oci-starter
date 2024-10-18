{% import "dotnet.j2_macro" as m with context %}
using System;
using System.Data;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
{{ m.import() }}

namespace starter.Controllers;

public class scott.dept Controller : ControllerBase
{
    private readonly ILogger<DeptController> _logger;

    {{ m.class_def() }}

    public scott.dept Controller(ILogger<DeptController> logger)
    {
        _logger = logger;
    }

    [Route("dept")]
    {%- if db_family == "nosql" %}    
    public async Task<IEnumerable<Dept>> Get()
    {%- else %}    
    public IEnumerable<Dept> Get()
    {%- endif %}    
    {
        {{ m.dept() }}
        return a.ToArray();
    }

    [Route("info")]
    public String Info()
    {
        return ".NET - {{ dbName }}";
    }  
}
