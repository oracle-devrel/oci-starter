package main

import (
	"context"
	"encoding/json"
	"io"
	fdk "github.com/fnproject/fdk-go"
)

type Dept struct {
    Deptno string `json:"deptno"`
    Dname string `json:"dname"`
    Loc string `json:"loc"`
}

func main() {
	fdk.Handle(fdk.HandlerFunc(myHandler))
}

func myHandler(ctx context.Context, in io.Reader, out io.Writer) {
    var d = []Dept{
        Dept{Deptno: "10", Dname: "ACCOUNTING", Loc: "Seoul"},
        Dept{Deptno: "20", Dname: "RESEARCH", Loc: "Cape Town"},
        Dept{Deptno: "30", Dname: "SALES", Loc: "Brussels"},
        Dept{Deptno: "40", Dname: "OPERATIONS", Loc: "San Francisco"},
    }     
	json.NewEncoder(out).Encode(&d)
}