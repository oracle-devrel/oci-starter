package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	fdk "github.com/fnproject/fdk-go"
	"database/sql"
	_ "github.com/godror/godror"
	"os"
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
	db, err := sql.Open("godror", os.Getenv("DB_USER")+"/"+os.Getenv("DB_PASSWORD")+"@"+os.Getenv("DB_URL"))
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()
		
	rows,err := db.Query("select deptno, dname, loc from dept")
	if err != nil {
		fmt.Println("Error running query")
		fmt.Println(err)
		return
	}
	defer rows.Close()
	fmt.Println(rows)

	var d []Dept
	for rows.Next() {
		var dept=new(Dept)
		rows.Scan(&dept.Deptno, &dept.Dname, &dept.Loc)   
		fmt.Println(dept.Deptno, dept.Dname, dept.Loc) 
		d = append(d, *dept)
	}
    json.NewEncoder(out).Encode(&d)
}