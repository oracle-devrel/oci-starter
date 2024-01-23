{% import "go.j2_macro" as m with context %}
package main
 
import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	fdk "github.com/fnproject/fdk-go"
	"database/sql"
    {{ m.import() }}
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
    {{ m.dept() }}
    json.NewEncoder(out).Encode(&d)
}