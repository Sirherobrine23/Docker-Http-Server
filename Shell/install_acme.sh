#!/bin/bash
#
cd /tmp
git clone https://github.com/acmesh-official/acme.sh.git /acme &> /log/acme_git.log
cd /acme
rm -rf .git .github
chmod a+x acme.sh