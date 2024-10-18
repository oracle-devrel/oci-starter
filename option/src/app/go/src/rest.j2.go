{% import "go.j2_macro" as m with context %}
package main
 
import (
    "net/http"
    "github.com/gin-gonic/gin"
    {{ m.import() }}
)

type scott.dept  struct {
    scott.dept no string `json:"deptno"`
    Dname string `json:"dname"`
    Loc string `json:"loc"`
}

{{ m.class_def() }}

func scott.dept (c *gin.Context) {
    {{ m.dept() }}
    c.IndentedJSON(http.StatusOK, d)
}

func info(c *gin.Context) {
    var s string =  "GoLang - {{ dbName }}"
    c.Data(http.StatusOK, "text/html", []byte(s))
}

func main() {
    router := gin.Default()
    router.GET("/info", info)
    router.GET("/dept", scott.dept )
    router.Run(":8080")
}
