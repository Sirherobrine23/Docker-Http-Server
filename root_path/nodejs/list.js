const express = require("express");
const app = express();
var cors = require("cors");
const bodyParser = require("body-parser");
const {execSync} = require("child_process");
const { readFileSync, existsSync, lstatSync } = require("fs");
const { resolve, join } = require("path");
const base_path = "/home/http"

app.use(cors());
app.use(bodyParser.json()); /* https://github.com/github/fetch/issues/323#issuecomment-331477498 */
app.use(bodyParser.urlencoded({ extended: true }));
app.get("/", (req, res) => {
    var required_path = req.query.path||"undefined"
    if (required_path.charAt(0) === "/") required_path = required_path.replace("/", "")
    const option = req.query.type;
    if (required_path !== "undefined"){
        var opt;
        if (option === "d") opt="-type d" ;else if (option === "f") opt="-type f"; else opt="";
        if (existsSync(resolve(base_path, required_path))){
            var json_http = execSync(`find "${base_path}/${required_path}" -maxdepth 1 ${opt}`).toString()
            json_http = json_http.replaceAll(base_path, "").replaceAll(required_path, "").replaceAll("//", "")
            const splithed = json_http.split("\n")
            const filt = []
            const check_ = resolve(base_path, required_path);
            for (let find in splithed){
                var filter = splithed[find]
                var isDirectory;
                if (lstatSync(join(check_ ,filter)).isDirectory()) isDirectory = "diretory"
                else isDirectory = "file"
                if (filter.charAt(0) === "/") filter = filter.replace("/", "")
                if (filter === "") null
                else if (filter === "/") null
                else filt.push({
                    path: filter,
                    type: isDirectory
                })
                
                
            }
            return res.json(filt);
        } else {
            res.json([
                {
                    "path": required_path,
                    "": "this directory or file does not exist"
                }
            ])
        }
    } else {
        const html_content = readFileSync("./endpoint.html", "utf8")
        res.send(html_content)
    }
});
const port = 2544
app.listen(port);