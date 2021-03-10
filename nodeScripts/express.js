const express = require("express");
const app = express();
const fs = require("fs");
var cors = require("cors");
const rateLimit = require("express-rate-limit");
const bodyParser = require("body-parser");
const {google} = require("googleapis");
const fetch = require("node-fetch");fetch('https://api.ipify.org/?format=json').then(response => response.text()).then(ip => {module.exports.ip = ip.ip})
// Settings
const limiter = rateLimit({
    windowMs: 1 * 60 * 1000, // minutes
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use(bodyParser.json()); /* https://github.com/github/fetch/issues/323#issuecomment-331477498 */
app.use(bodyParser.urlencoded({ extended: true }));
app.use(limiter);
app.use(cors());
// Urls
app.get("/request", (req, res) => {
    const backup_json = JSON.parse(fs.readFileSync("/node_script/drive_api.json").toString().split("@DOMAIN_REQUEST").join(process.env.NODE_REQUEST_DRIVE))
    const user_save_json = "/home/config/google_drive_token.json"
    const secret = backup_json.installed.client_secret;
    const client = backup_json.installed.client_id;
    const redirect = backup_json.installed.redirect_uris;
    const oAuth2Client = new google.auth.OAuth2(client, secret, redirect[0]);
    const authUrl = oAuth2Client.generateAuthUrl({access_type: "offline",scope: ["https://www.googleapis.com/auth/drive"],});
    res.redirect(authUrl)
    app.get("/save", (req, res) => {
        // http://localhost:6899/save?code=********************************************************************&scope=https://www.googleapis.com/auth/drive
        const code = req.query.code
        oAuth2Client.getToken(code, (err, token) => {
            if (err) return console.error("Error retrieving access token", err);
            oAuth2Client.setCredentials(token);
            fs.writeFileSync(user_save_json, JSON.stringify(token, null, 2));
            //callback(oAuth2Client);
            close_server()
        })
        var pages_template = (fs.readFileSync("./index.html", "utf8")).toString()
        pages_template = pages_template.split("@TOKEN").join(code).split("@NODE_DOMAIN").join(process.env.NODE_REQUEST_DRIVE)
        res.send(pages_template)
    })
    
})
const saver = app.listen(6899)
function close_server(){
    saver.close()
}