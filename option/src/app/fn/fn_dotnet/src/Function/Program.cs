using System;
using Fnproject.Fn.Fdk;
using Oracle.ManagedDataAccess.Client;
using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("Function.Tests")]
namespace Function
{
    class Starter
    {
        public static string user = Environment.GetEnvironmentVariable("DB_USER");
        public static string pwd = Environment.GetEnvironmentVariable("DB_PASSWORD");
        public static string db = Environment.GetEnvironmentVariable("DB_URL");

        public string dept()
        {
            string result = "[";
            string conStringUser = "User Id=" + user + ";Password=" + pwd + ";Data Source=" + db + ";";

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
                        bool bFirst = true;
                        while (reader.Read())
                        {
                            if (!bFirst)
                            {
                                result += ",";
                            }
                            else
                            {
                                bFirst = false;
                            }
                            result += "{ \"deptno\": \"" + reader.GetString(0) + "\", \"dname\": \"" + reader.GetString(1) + "\", \"loc\": \"" + reader.GetString(2) + "\"}";
                        }
                        reader.Dispose();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(ex.Message);
                    }
                }
            }
            result += "]";
            return result;
        }

        static void Main(string[] args) { Fdk.Handle(args[0]); }
    }
}