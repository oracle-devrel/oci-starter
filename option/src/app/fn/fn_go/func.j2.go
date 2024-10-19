{% import "go.j2_macro" as m with context %}
package main
 
import (
    "context"
    "encoding/json"
    "io"
    fdk "github.com/fnproject/fdk-go"
    {{ m.import() }}
)

type Dept struct {
    Deptno string `json:"deptno"`
    Dname string `json:"dname"`
    Loc string `json:"loc"`
}

{{ m.class_def() }}

func main() {
    fdk.Handle(fdk.HandlerFunc(myHandler))
}

func myHandler(ctx context.Context, in io.Reader, out io.Writer) {
    {{ m.dept() }}
    json.NewEncoder(out).Encode(&d)
}