const fdk = require('@fnproject/fdk');

fdk.handle(async function() {
    let arr = [ 
        { "deptno": "10", "dname": "ACCOUNTING", "loc": "Seoul"}, 
        { "deptno": "20", "dname": "RESEARCH", "loc": "Cape Town"}, 
        { "deptno": "30", "dname": "SALES", "loc": "Brussels"}, 
        { "deptno": "40", "dname": "OPERATIONS", "loc": "San Francisco"} 
    ];
    return arr;
})
