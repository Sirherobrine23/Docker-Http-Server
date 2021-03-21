console.warn("Starting image build");
const path = require("path")
const {exec, execSync} = require("child_process")
const ports_options = "-p 8888:80/tcp -p 8889:443 -p 2222:22/tcp -p 6899:6899/tcp -p 2544:2544/tcp",
    variasbles = `-e CF_Email="${process.env.CF_Email}" -e CF_Key="${process.env.CF_Key}" -e DOMAIN="${process.env.DOMAIN}" -e ADMIN_USERNAME="${process.env.ADMIN_USERNAME}" -e ADMIN_PASSWORD="${process.env.ADMIN_PASSWORD}"`,
    mounts = `-v "${path.resolve(".docker_teste", "config")}:/home/config" -v "${path.resolve(".docker_teste", "http")}:/home/http" -v "${path.resolve(".docker_teste", "log")}:/log"`,
    docker_options = `--no-cache `
    const docker_name = {
        name: "http_docker",
        docker: "test/http:latest"
    };
var docker_builder_c = `konsole -e docker build . -t ${docker_name.docker}`,
    docker_run_c = `konsole --noclose -e docker run -ti --rm --name ${docker_name.name} ${ports_options} ${mounts} ${variasbles} ${docker_name.docker}`

execSync(`konsole -e docker stop  $(docker ps -a |grep -v 'CONTAINER'|awk '{print $1}')`)
const build_code = 
execSync(docker_builder_c)
execSync(docker_run_c)