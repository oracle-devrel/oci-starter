using System;
using System.Data;
using Oracle.ManagedDataAccess.Client;
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
        string conStringUser = "User Id=" + user + ";Password=" + pwd + ";Data Source=" + db + ";";
        List<Dept> a = new List<Dept>();

        using (OracleConnection con = new OracleConnection(conStringUser))
        {
            using (OracleCommand cmd = con.CreateCommand())
            {
                try
                {
                    con.Open();
                    Console.WriteLine("Successfully connected to Oracle Database as " + user);
                    Console.WriteLine();

                    //Retrieve sample data
                    cmd.CommandText = "SELECT deptno, dname, loc FROM dept";
                    OracleDataReader reader = cmd.ExecuteReader();
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
            }
        }
        return a.ToArray();
    }

    [Route("info")]
    public String Info()
    {
        return ".NET - Oracle";
    }  
}
