#!/bin/bash
set -e
cd "/nodejs"
source /tmp/envs
node -p 'require("./Google_Drive")'
exit 0