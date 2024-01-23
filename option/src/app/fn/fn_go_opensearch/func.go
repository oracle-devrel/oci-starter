package main

import (
	"context"
	"encoding/json"
	"os"
	"io"
    "net/http"
    "fmt"
    "io/ioutil"    
	fdk "github.com/fnproject/fdk-go"
)

type Dept struct {
    Deptno string `json:"deptno"`
    Dname string `json:"dname"`
    Loc string `json:"loc"`
}

type Result struct {
	Hits struct {
		Hits []struct {
			Source struct {
				Deptno string `json:"deptno"`
				Dname  string `json:"dname"`
				Loc    string `json:"loc"`
			} `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func main() {
	fdk.Handle(fdk.HandlerFunc(myHandler))
}

func myHandler(ctx context.Context, in io.Reader, out io.Writer) {
    response, err := http.Get("https://"+os.Getenv("DB_URL")+":9200/dept/_search?size=1000&scroll=1m&pretty=true")
    if err != nil {
        fmt.Print(err.Error())
        os.Exit(1)
    }
    jsonData, err := ioutil.ReadAll(response.Body)
    if err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
    fmt.Println(string(jsonData))

    body := Result{}
    err2 := json.Unmarshal([]byte(jsonData), &body)
    if err2 != nil {
        fmt.Println(err2)
        os.Exit(1)
    }
    var d [] Dept;   
    for _, hit := range body.Hits.Hits {
        d = append(d, Dept{hit.Source.Deptno, hit.Source.Dname,hit.Source.Loc})
    }
    fmt.Println(d)
	json.NewEncoder(out).Encode(&d)
}

