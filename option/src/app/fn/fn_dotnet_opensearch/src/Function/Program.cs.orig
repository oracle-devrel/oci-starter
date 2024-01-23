using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Net.Http;
using Fnproject.Fn.Fdk;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Threading.Tasks;

[assembly: InternalsVisibleTo("Function.Tests")]
namespace Function
{
    class Starter
    {
        public class Dept
        {
            public string? deptno { get; set; }
            public string? dname { get; set; }
            public string? loc { get; set; }
        }

        public class Source
        {
            public string deptno { get; set; }
            public string dname { get; set; }
            public string loc { get; set; }

        }
        public class Hit
        {
            public Source _source { get; set; }
        }
        public class Hits
        {
            public List<Hit> hits { get; set; }
        }
        public class Result
        {
            public Hits hits { get; set; }
        }

        private static HttpClient client = new HttpClient();

        public string dept()
        {
            client.BaseAddress = new Uri(@"https://" + Environment.GetEnvironmentVariable("DB_URL") + ":9200");

            var task = Task.Run(() => client.GetAsync("/dept/_search?size=1000&scroll=1m&pretty=true"));
            task.Wait();
            HttpResponseMessage response = task.Result;

            var task2 = Task.Run(() => response.Content.ReadAsStringAsync());
            task2.Wait();
            string data = task2.Result;
            Result result = JsonSerializer.Deserialize<Result>(data);

            Console.WriteLine(result);
            List<Dept> a = new List<Dept>();
            try
            {
                foreach (var hit in result.hits.hits)
                {
                    Dept d = new Dept { deptno = hit._source.deptno, dname = hit._source.dname, loc = hit._source.loc };
                    a.Add(d);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
            return JsonSerializer.Serialize(a);
        }

        static void Main(string[] args) { Fdk.Handle(args[0]); }
    }
}




