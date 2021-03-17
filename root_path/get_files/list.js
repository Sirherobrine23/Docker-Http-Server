const express = require("express");
const app = express();
var cors = require("cors");
const bodyParser = require("body-parser");
const {execSync} = require("child_process")
const base_path = "/home/http/"

app.use(cors());
app.use(bodyParser.json()); /* https://github.com/github/fetch/issues/323#issuecomment-331477498 */
app.use(bodyParser.urlencoded({ extended: true }));
app.get("/", (req, res) => {
    const required_path = req.query.path
    const option = req.query.type;
    if (required_path !== undefined){
        var opt;
    if (option === "d") opt="-type d" ;else if (option === "f") opt="-type f"; else opt="";
        var json_http = execSync(`find ${base_path}/${required_path} -maxdepth 1 ${opt} || echo "${required_path}: undefined\n"`).toString()
        json_http = json_http.replaceAll(base_path, "").replaceAll(required_path, "").replaceAll("//", "")
        const splithed = json_http.split("\n")
        const filt = []
        for (let find in splithed){
            var filter = splithed[find]
            if (filter.charAt(0) === "/") filter = filter.replace("/", "")
            if (filter === "") null
            else if (filter === "/") null
            else filt.push(filter)
        }
        return res.json(filt);
    } else {
        res.send(`<a>Use in body "http://localhost:2544/?path=/","http://localhost:2544/?path=/&type=f", "http://localhost:2544/?path=/&type=d"</a>`)
    }
});
app.get("/favicon.ico", (req, res) => {
    res.send(null)
})
const port = 2544
app.listen(port, function (){
    console.log(`Query folder, port: ${port}`);
});