package com.example.fn;

import com.fnproject.fn.api.RuntimeContext;

public class HelloFunction {

  public HelloFunction() {}

  public String handleRequest(String input) {
		return """
 		[ 
			{ "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"},
			{ "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"},
			{ "deptno": "30", "dname": "SALES", "loc": "Brussels"},
			{ "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"}
		] 
		""";
  }
}
