package main
 
import (
    "fmt"
    "database/sql"
    _ "github.com/go-sql-driver/mysql"
    "os"
    "net/http"
    "github.com/gin-gonic/gin"
)

type Dept struct {
    Deptno string `json:"deptno"`
    Dname string `json:"dname"`
    Loc string `json:"loc"`
}

func dept(c *gin.Context) {
    db, err := sql.Open("mysql", os.Getenv("DB_USER")+":"+os.Getenv("DB_PASSWORD")+"@tcp("+os.Getenv("DB_URL")+")/db1")
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
    c.IndentedJSON(http.StatusOK, d)
}

func info(c *gin.Context) {
    var s string =  "GoLang / MySQL"
    c.Data(http.StatusOK, "text/html", []byte(s))
}

func main() {
    router := gin.Default()
    router.GET("/info", info)
    router.GET("/dept", dept)
    router.Run(":8080")
}
