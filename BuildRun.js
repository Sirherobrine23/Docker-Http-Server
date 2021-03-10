console.warn("Starting image build");
const path = require("path")
const {exec, execSync} = require("child_process")
const ports_options = "-p 8888:80/tcp -p 8889:443 -p 2222:22/tcp -p 6899:6899/tcp",
    variasbles = `-e CF_Email="${process.env.CF_Email}" -e CF_Key="${process.env.CF_Key}" -e DOMAIN="${process.env.DOMAIN}" -e ADMIN_USERNAME="${process.env.ADMIN_USERNAME}" -e ADMIN_PASSWORD="${process.env.ADMIN_PASSWORD}"`,
    mounts = `-v "${path.resolve(".docker_teste", "config")}:/home/config" -v "${path.resolve(".docker_teste", "http")}:/home/http" -v "${path.resolve(".docker_teste", "ssl")}:/home/ssl" -v "${path.resolve(".docker_teste", "log")}:/log"`,
    docker_options = `--no-cache `
    const docker_name = {
        name: "http_docker",
        docker: "test/http:latest"
    };
var docker_builder_c = `docker build . -t ${docker_name.docker}`,
    docker_run_c = `docker run -d --rm --name ${docker_name.name} ${ports_options} ${mounts} ${variasbles} ${docker_name.docker}`
function output(data){
    //if (data.slice(-1) == "\n") data = data.slice(0, -1)
    console.log(data)
}
const logs = execSync("docker ps").toString()
const logs2 = execSync("docker ps --all").toString()
if (logs.includes(docker_name.name)) console.log(execSync(`docker stop ${docker_name.name}`).toString())
else if (logs2.includes(docker_name.name)) console.log(execSync("docker rm "+docker_name.name).toString())

const build = exec(docker_builder_c)
console.warn(docker_builder_c)
build.stdout.on("data", function(data){output(data)})
build.on("exit", (code) => {
    if (code === 0){
        console.warn(docker_run_c);
        const run = exec(docker_run_c)
        run.stdout.on("data", function (data) {output(data)})
        run.on("exit", function (code){
            if (code === 0){
                const docker_log = exec(`docker logs -f ${docker_name.name}`)
                docker_log.stdout.on("data", function (data){output(data)})
                
            } else {
                console.error("We were unable to run the docker image, run it manually with the following command: "+docker_run_c.replace("run -d ", "run "))
                process.exit(code)
            }
        })
    } else {
        console.error("We were unable to create the image of the docker, Run the following command in the terminal: "+docker_builder_c)
        process.exit(code)
    }
})