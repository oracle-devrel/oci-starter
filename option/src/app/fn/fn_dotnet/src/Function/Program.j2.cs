{% import "dotnet.j2_macro" as m with context %}
using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Net.Http;
using Fnproject.Fn.Fdk;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Text.Json;
{{ m.import() }} 

[assembly: InternalsVisibleTo("Function.Tests")]
namespace Function { class Starter {
    public class Dept
    {
        public string? deptno { get; set; }
        public string? dname { get; set; }
        public string? loc { get; set; }
    }

    {{ m.class_def() }} 

    {%- if db_family == "nosql" %}    
    public async Task<string> dept()
    {%- else %}    
    public string dept()
    {%- endif %}   
    {
        {{ m.dept() }} 
        return JsonSerializer.Serialize(a);
    }

    static void Main(string[] args) { Fdk.Handle(args[0]); }
}}




