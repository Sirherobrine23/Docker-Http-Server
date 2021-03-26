const express = require("express");
const app = express();
var cors = require("cors");
const bodyParser = require("body-parser");
const {execSync} = require("child_process");
const { readFileSync, existsSync, lstatSync, writeFileSync } = require("fs");
const { resolve, join } = require("path");
const fileUpload = require('express-fileupload');
const base_path = "/home/http"
const base_config = "/home/config"


app.use(cors());
app.use(bodyParser.json()); /* https://github.com/github/fetch/issues/323#issuecomment-331477498 */
app.use(bodyParser.urlencoded({ extended: true }));
// default options
app.use(fileUpload());
app.get("/Wheatley", (req, res) =>{
    const checkDiskSpace = require('check-disk-space')
    const dir = "/home/http"
    var Html_response = readFileSync(resolve(__dirname, "space.html"), "utf8")
    checkDiskSpace(dir).then((diskSpace) => {
        var space = Math.trunc(diskSpace.free / 1014 / 1024 /1024)
        if (space > 1000) space = (Math.trunc(space / 1024)+"Tb")
        else space = (space+"gb")
        Html_response = Html_response.split("@SPACE").join(space)
        res.send(Html_response)
    })
})

app.post('/upload', function(req, res) {
    var fileUploaded;
    var uploadPath;
    if (!req.files || Object.keys(req.files).length === 0) {return res.status(400).send('No files were uploaded.');}
    const files = Object.getOwnPropertyNames(req.files)
    for (let save in files){
        fileUploaded = req.files[files[save]];
        console.log(fileUploaded);
        uploadPath = resolve(base_path, fileUploaded.name);
        // Use the mv() method to place the file somewhere on your server
        fileUploaded.mv(uploadPath, function(err) {
            if (err) return res.status(500).send(err);
        });
    }
    res.send('File uploaded!');
});

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