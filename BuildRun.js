const {exec, execSync} = require("child_process")
const path = require("path")
var docker_builder_c = "docker build . -t test/http:latest",
    docker_run_c = `docker run -d --rm --name http_docker -v "${path.resolve(process.env.HOME_TEST)}:/home" -e CF_Email="${process.env.CF_Email}" -e CF_Key="${process.env.CF_Key}" -e DOMAIN="${process.env.DOMAIN}" -p 8888:80/tcp -p 8889:443 -p 2222:22/tcp test/http:latest`
function output(data){
    if (data.slice(-1) == "\n") data = data.slice(0, -1)
    console.log(data)
}
const logs = execSync("docker ps --all").toString()
if (logs.includes("http_docker")) console.log(execSync("docker stop http_docker").toString())
var build = exec(docker_builder_c)
build.stdout.on("data", function(data){output(data)})
build.on("exit", (code) => {
    if (code === 0){
        var run = exec(docker_run_c)
        run.stdout.on("data", function (data) {output(data)})
        run.on("exit", function (code){
            if (code === 0){
                const docker_log = exec("docker logs -f http_docker")
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