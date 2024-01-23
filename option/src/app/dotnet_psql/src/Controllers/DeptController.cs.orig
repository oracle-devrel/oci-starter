using System;
using System.Data;
using Npgsql;
using Microsoft.AspNetCore.Mvc;

namespace starter.Controllers;

public class DeptController : ControllerBase
{
    private readonly ILogger<DeptController> _logger;

    public static string user = Environment.GetEnvironmentVariable("DB_USER");
    public static string pwd = Environment.GetEnvironmentVariable("DB_PASSWORD");
    public static string db = Environment.GetEnvironmentVariable("DB_URL");

    public DeptController(ILogger<DeptController> logger)
    {
        _logger = logger;
    }

    [Route("dept")]
    public IEnumerable<Dept> Get()
    {
        string conStringUser = @"Server=" + db + ";User Id=" + user + ";Password=" + pwd + ";Database=postgres;Trust Server Certificate=true";
        List<Dept> a = new List<Dept>();
        try
        {
            using var con = new NpgsqlConnection(conStringUser);
            con.Open();
            Console.WriteLine("Successfully connected to PostgreSQL");
            Console.WriteLine();

            //Retrieve sample data
            using var cmd = new NpgsqlCommand("SELECT deptno, dname, loc FROM dept", con);
            using NpgsqlDataReader reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                Dept d = new Dept { deptno = reader.GetInt64(0).ToString(), dname = reader.GetString(1), loc = reader.GetString(2) };
                a.Add(d);
            }
            reader.Dispose();
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);
        }
        return a.ToArray();
    }

    [Route("info")]
    public String Info()
    {
        return ".NET / PostgreSQL";
    }
}
