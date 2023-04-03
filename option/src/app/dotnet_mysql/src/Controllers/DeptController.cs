using System;
using System.Data;
using MySql.Data.MySqlClient;
using Microsoft.AspNetCore.Mvc;

namespace starter.Controllers;

public class DeptController : ControllerBase
{
    private readonly ILogger<DeptController> _logger;

    public static string user = Environment.GetEnvironmentVariable("DB_USER");
    public static string pwd = Environment.GetEnvironmentVariable("DB_PASSWORD");
    public static string db = Environment.GetEnvironmentVariable("DB_URL").Split(':')[0];

    public DeptController(ILogger<DeptController> logger)
    {
        _logger = logger;
    }

    [Route("dept")]
    public IEnumerable<Dept> Get()
    {
        string conStringUser = @"server=" + db + ";userid=" + user + ";password=" + pwd + ";database=db1";
        List<Dept> a = new List<Dept>();
        try
        {
            using var con = new MySqlConnection(conStringUser);
            con.Open();
            Console.WriteLine("Successfully connected to MySQL");
            Console.WriteLine();

            //Retrieve sample data
            using var cmd = new MySqlCommand("SELECT deptno, dname, loc FROM dept", con);
            using MySqlDataReader reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                Dept d = new Dept { deptno = reader.GetString(0), dname = reader.GetString(1), loc = reader.GetString(2) };
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
        return ".NET / MySQL";
    }
}
