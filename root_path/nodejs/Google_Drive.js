const { readFileSync, readFile, readdirSync, createReadStream, existsSync, mkdirSync, lstatSync, rmSync } = require("fs")
const {resolve, join} = require("path")
const {google} = require("googleapis");
const AdmZip = require("adm-zip")

const user_save_json = "/home/config/google_drive_token.json"
//"redirect_uris": ["http://localhost:6899/save"]
const backup_json = JSON.parse(readFileSync(resolve(__dirname, "drive_api.json")).toString().split("@DOMAIN_REQUEST").join(readFileSync("/tmp/node_url", "utf8").replace("file.examples.com", "localhost").split("\n").join("")))
function authorize(callback) {
    let secret = backup_json.installed.client_secret
    let client = backup_json.installed.client_id
    let redirect = backup_json.installed.redirect_uris

    const oAuth2Client = new google.auth.OAuth2(client, secret, redirect[0]);
    readFile(user_save_json, (err, token) => {
        if (err) require("./express")
        oAuth2Client.setCredentials(JSON.parse(token));
        callback(oAuth2Client);
    });
}
function zip_files(){
    const base = "/home/http"
    // Rm old backups
    if (existsSync(join(base, ".backup"))){
        let old_base = join(base, ".backup")
        const old = readdirSync(old_base)
        for (let rm in old){
            rmSync(join(old_base, old[rm]))
        }
    } else mkdirSync(join(base, ".backup"))

    // create folder
    return authorize(function (auth){
        const drive = google.drive({version: "v3", auth});
        drive.files.create({
            resource: {
                "name": `Web Backup:${new Date().getUTCDate()}/${new Date().getUTCMonth() + 1}/${new Date().getFullYear()} ${new Date().getUTCHours()}:${new Date().getMinutes()} UTC`,
                "mimeType": "application/vnd.google-apps.folder"
            },
            fields: "id"
        },
        function (err, file) {
            if (err) console.error(err);
            const id = file.data.id
            if (id === undefined) throw console.error("Could not create folder");
            else {
                console.log("Folder Id: "+ id);

                // Create zips and upload
                const http_home = readdirSync(base)
                http_home.pop(".backup")

                for (let bc in http_home){
                    var name = http_home[bc] + ".zip"
                    if (name.charAt(0) === ".") name = name.replace(".", "")
                    const path_backup = join(base, ".backup", name)
                    const folderFile = join(base, http_home[bc])
                    var zip = new AdmZip();
                    if (lstatSync(folderFile).isDirectory()) zip.addLocalFolder(folderFile);
                    else zip.addLocalFile(folderFile)
                    zip.addZipComment(`Backup file in docker`);
                    zip.writeZip(path_backup);
                    upload_todrive({
                        name: name,
                        path: path_backup,
                        id: id
                    })
                }
            }
        })
    });
}

function upload_todrive(file_json) {
    // callback to upload
    return authorize(function (auth) {
        const drive = google.drive({version: "v3", auth});
        console.log(file_json)
        var parent_id = file_json.id,
            path_file = file_json.path,
            name = file_json.name;
        const save  = {
            resource: {
                name: name,
                parents: [parent_id]
            },
            media: {
                mimeType: "application/octet-stream",
                body: createReadStream(path_file)
            },
            fields: "id"
        };
        drive.files.create(save, function (err, file) {
            if (err) console.error(err);
            else console.log(`File ID: ${file.data.id}` );
        });
    });
}

module.exports = {
    backup: zip_files
}
var argv = require("minimist")(process.argv.slice(2));
process.title = "Http backup";
if (argv.h || argv.help) {
  console.log([
    "usage: Docker, Google Drive Backup [options]",
    "",
    "options:",
    "  -b --backup          Backup http folders"
  ].join("\n"));
  process.exit();
}
if (argv.b || argv.backup){
    zip_files()
}