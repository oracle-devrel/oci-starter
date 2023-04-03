using System;
using Fnproject.Fn.Fdk;
using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("Function.Tests")]
namespace Function
{
    class Starter
    {
        public string dept()
        {
            string result = @"[ 
                { ""deptno"": ""10"", ""dname"": ""ACCOUNTING"", ""loc"": ""Seoul""},
                { ""deptno"": ""20"", ""dname"": ""RESEARCH"", ""loc"": ""Cape Town""},
                { ""deptno"": ""30"", ""dname"": ""SALES"", ""loc"": ""Brussels""},
                { ""deptno"": ""40"", ""dname"": ""OPERATIONS"", ""loc"": ""San Francisco""}
            ]";
            return result;
        }

        static void Main(string[] args) { Fdk.Handle(args[0]); }
    }
}