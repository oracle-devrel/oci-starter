package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	fdk "github.com/fnproject/fdk-go"
	"database/sql"
    _ "github.com/lib/pq"
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
    psqlInfo := fmt.Sprintf("host=%s port=5432 user=%s password=%s dbname=postgres sslmode=require",
                 os.Getenv("DB_URL"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"))
    db, err := sql.Open("postgres", psqlInfo)    
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
