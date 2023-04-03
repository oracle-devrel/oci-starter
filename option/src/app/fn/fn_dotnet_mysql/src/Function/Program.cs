using System;
using Fnproject.Fn.Fdk;
using MySql.Data.MySqlClient;
using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("Function.Tests")]
namespace Function
{
    class Starter
    {
        public static string user = Environment.GetEnvironmentVariable("DB_USER");
        public static string pwd = Environment.GetEnvironmentVariable("DB_PASSWORD");
        public static string db = Environment.GetEnvironmentVariable("DB_URL").Split(':')[0];
        public string dept()
        {
            string result = "[";
            string conStringUser = @"server=" + db + ";userid=" + user + ";password=" + pwd + ";database=db1";
            Console.WriteLine(conStringUser);
            try
            {
                using var con = new MySqlConnection(conStringUser);
                con.Open();
                Console.WriteLine("Successfully connected to MySQL");
                Console.WriteLine();

                //Retrieve sample data
                using var cmd = new MySqlCommand("SELECT deptno, dname, loc FROM dept", con);
                using MySqlDataReader reader = cmd.ExecuteReader();
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
                result += ex.Message;
            }
            result += "]";
            return result;
        }

        static void Main(string[] args) { Fdk.Handle(args[0]); }
    }
}
