const express = require('express')
const app = express()
const https = require('https'); 
const port = 8080

app.get('/info', (req, res) => {
    res.send('NodeJS - Express / OpenSearch')
})

app.get('/dept', (req, res) => {

    var url = "https://"+process.env.DB_URL+":9200/dept/_search?size=1000&scroll=1m&pretty=true"
    console.log("url:" + url);

    https.get(url, function(http_res){
        var body = '';
        http_res.on('data', function(chunk){
            body += chunk;
        });
        http_res.on('end', function(){
            var j= JSON.parse(body);
            console.log(j);
            result = [];
            for (i in j.hits.hits) {
                hit = j.hits.hits[i]
                result.push({"deptno":hit._source.deptno,"dname":hit._source.dname,"loc":hit._source.loc })
            }
            res.send(result)
        });
    }).on('error', function(e){
          console.log("Got an error: ", e);
    });
})

app.listen(port, () => {
    console.log(`OCI Starter: listening on port ${port}`)
})
