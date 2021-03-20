const fs = require("fs");
const {readFileSync} = require("fs")
const path = require("path")
const {google} = require("googleapis");
//const user_save_json = path.resolve("/", "home" , "config", "gdrive_token.json");
const user_save_json = "/home/config/google_drive_token.json"
//"redirect_uris": ["http://localhost:6899/save"]
const backup_json = JSON.parse(fs.readFileSync(path.resolve("/nodejs/drive_api.json")).toString().split("@DOMAIN_REQUEST").join(readFileSync("/tmp/node_url", "utf8").replace("file.examples.com", "localhost")))
function authorize(callback) {
    let secret = backup_json.installed.client_secret
    let client = backup_json.installed.client_id
    let redirect = backup_json.installed.redirect_uris

    const oAuth2Client = new google.auth.OAuth2(client, secret, redirect[0]);
    fs.readFile(user_save_json, (err, token) => {
        if (err) require("./express")
        oAuth2Client.setCredentials(JSON.parse(token));
        callback(oAuth2Client);
    });
}
function zip_files(){
    const AdmZip = require("adm-zip")
    var zip = new AdmZip();
    zip.addLocalFolder(dir_zip);
    zip.addZipComment(`Backup zip file in ${today}. \nBackup made to ${process.platform}, Free and open content for all\n\nSirherobrine23© By Bds Maneger.`);
    var zipEntries = zip.getEntries();
    zipEntries.forEach(function (zipEntry) {
        console.log(zipEntry.entryName.toString());
    });
    zip.writeZip(name);
    return {
        name: name,
        path: dir_zip
    }
}
module.exports.upload = (file_json) => {
    console.log(file_json)
    const parent_id = file_json.g_id,
        path_file = file_json.file_path,
        name_d = file_json.file_name;
        function upload_backup(auth) {
            const drive = google.drive({version: "v3", auth});
            const save  = {
                resource: {
                    "name": name_d,
                    "parents": parent_id
                },
                media: {
                    mimeType: "application/octet-stream",
                    body: fs.createReadStream(path_file)
                },
                fields: "id"
            }
            drive.files.create(save, function (err, file) {
                if (err) console.error(err)
                else {
                    console.log(`File ID: ${file.data.id}` );}
            });
    }
    return authorize(upload_backup);
    // End Upload Backup
};
