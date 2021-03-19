const {execSync, exec} = require("child_process");
const {join, resolve} = require("path");
const {readFileSync, writeFileSync, existsSync, mkdirSync, rmdirSync, readdirSync, rmSync} = require("fs")
const {upload} = require("./Google_Drive")

const current_path = resolve("..")
const backup_folder_backup = resolve(current_path, ".backup")
var json_file = []
function clean_backup_folder(){
    const null_rm = readdirSync(backup_folder_backup)
    for (let rm in null_rm){
        const file_rm = join(backup_folder_backup, null_rm[rm])
        rmSync(file_rm)
        console.log(file_rm)
    }
    rmdirSync(backup_folder_backup)
}
// dir backup
if (!(existsSync(backup_folder_backup))) mkdirSync(backup_folder_backup)
//
const dirs = readdirSync(current_path)

function get_id(){
    if (existsSync("/home/config/gdrive.json")) {
        const FileJson = JSON.parse(fs.readFileSync("/home/config/gdrive.json", "utf8"))
        if (FileJson.ID === null) return undefined
        if (FileJson.ID === undefined) return undefined
        else return [FileJson.ID]
    }
    else return undefined
}
const google_id = (get_id()||process.env.GDRIVE_FOLDER_ROOT)
dirs.shift(".backup")
for (let recur in dirs){
    const dir_backup = resolve(current_path, dirs[recur])
    const file_backup = resolve(backup_folder_backup, dirs[recur] + ".zip")
    json_file.push({
        "file_path": file_backup,
        "original_path": dir_backup
    })
    if (existsSync(file_backup)) rmSync(file_backup)
    const zipFile = exec(`zip ${file_backup} -r ${dir_backup}`)
    zipFile.stdout.on("data", function (data){
        if (data.slice(-1) === "\n") data = data.slice(-1, 0)
        console.log(data)
    })
    zipFile.on("exit", (code) => {
        if (code === 0){
            upload({
                file_upload: file_backup,
                file_name: dirs[recur] + ".zip",
                g_id: google_id
            })
        }
    })
}
console.log(json_file);
clean_backup_folder()