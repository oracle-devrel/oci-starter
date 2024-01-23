{% import "go.j2_macro" as m with context %}
package main
 
import (
    "fmt"
    "database/sql"
    {{ m.import() }}
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
    {{ m.dept() }}
    c.IndentedJSON(http.StatusOK, d)
}

func info(c *gin.Context) {
    var s string =  "GoLang / {{ dbName }}"
    c.Data(http.StatusOK, "text/html", []byte(s))
}

func main() {
    router := gin.Default()
    router.GET("/info", info)
    router.GET("/dept", dept)
    router.Run(":8080")
}
