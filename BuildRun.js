const exec = require("child_process").exec
var docker_builder_c, docker_run_c
if (process.platform === "win32") {
    docker_builder_c = `docker build . --rm -t test/http:latest`
    docker_run_c = `docker run -d -v ${process.env.HOME_TEST}:/home -e CF_Email="${process.env.CF_Email}" -e CF_Key="${process.env.CF_Key}" -e DOMAIN="${process.env.DOMAIN}" -p 8888:80/tcp -p 8889:443 -p 2222:22/tcp test/http:latest`
} else {
    docker_builder_c = `docker build . --rm -t test/http:latest`
    docker_run_c = `docker run -d -v ${process.env.HOME_TEST}:/home -e CF_Email="${process.env.CF_Email}" -e CF_Key="${process.env.CF_Key}" -e DOMAIN="${process.env.DOMAIN}" -p 8888:80/tcp -p 8889:443 -p 2222:22/tcp test/http:latest`
}
function output(data){
    console.log(data)
}
console.log(docker_run_c)
console.log(docker_builder_c);
var build = exec(docker_builder_c)
build.stdout.on("data", function(data){output(data)})
build.on("exit", (code) => {
    console.log(code)
    if (code === 0){
        var run = exec(docker_run_c)
        run.stdout.on("data", function (data) {output(data)})
    } else process.exit(code)
})