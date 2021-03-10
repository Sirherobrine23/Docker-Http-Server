#!/bin/bash
# Usernames
username="${ADMIN_USERNAME}"
password="${ADMIN_PASSWORD}"
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password);
useradd -m -p "$pass" "$username";
addgroup ${username} sudo;
usermod --shell /bin/bash ${username}
echo -ne "${ADMIN_PASSWORD}\n${ADMIN_PASSWORD}\n" | smbpasswd -a "${ADMIN_USERNAME}"
echo "# Admin User" >> /etc/sudoers
echo "${ADMIN_USERNAME}   ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "
**********************************
*   Username:  ${ADMIN_USERNAME}
*   Passworld: ${ADMIN_PASSWORD}
**********************************"
echo "
        error_page 404 /404_index.html;
        location = /404_index.html {
                root /nginx/404;
                internal;
        }
        error_page 500 502 503 504 /5xx_index.html;
        location = /5xx_index.html {
                root /nginx/505;
                internal;
        }
#        location / {
#                autoindex on;
#        }
" > /tmp/error_nginx
mkdir -p /home/all
echo "<h1>All pages HOME</h1><p>" > /home/all/index.html
for i in ${DOMAIN}
do
    SSL="-d ${i} ${SSL}"
    echo "<p><a href=\"http://$i\">$i</a></p>" >> /home/all/index.html
    if [ -z "${NODE_REQUEST_DRIVE}" ];then
        export NODE_REQUEST_DRIVE="$i"
    fi
done
echo "</p>" >> /home/all/index.html
DOMAIN_FOLDER=`find /home/ssl -name 'fullchain.cer'|sed 's|/fullchain.cer||g'|sed 's|/home/ssl/||g'`
echo $DOMAIN_FOLDER

if  [ -e "/home/ssl/${DOMAIN_FOLDER}/fullchain.cer" ]
then
    echo "We already have an SSL certificate: /home/ssl/${DOMAIN_FOLDER}/fullchain.cer"
    DOMAIN_IP=false
echo "server {
        listen [::]:443 ssl ipv6only=on;
        listen 443 ssl;
        ssl_certificate /home/ssl/${DOMAIN_FOLDER}/fullchain.cer;
        ssl_certificate_key /home/ssl/${DOMAIN_FOLDER}/${DOMAIN_FOLDER}.key;
        root /home/http;
        index index.html index.htm index.nginx-debian.html;
        server_name ${DOMAIN};
$(cat /tmp/error_nginx)
}
" > /tmp/ssl_nginx
else
    if [ "${CF_Email}" == "example@hotmail.com" ];then
        echo "We will not create a certificate because you did not change the email"
        DOMAIN="_"
        DOMAIN_IP=true
    elif [ "${CF_Key}" == "b83188XXXXXXXxxxxxxXcc17XX85085408b3aXX" ];then
        echo "Please enter a valid Cloudflare Key"
        DOMAIN="_"
        DOMAIN_IP=true
    elif echo "${DOMAIN}"|grep -q "file.examples.com";then
        echo "Please enter a different domain, do not use the example domains"
        DOMAIN="_"
        DOMAIN_IP=true
    elif echo "${DOMAIN}"|grep -q "f.example.com";then
        echo "Please enter a different domain, do not use the example domains"
        DOMAIN="_"
        DOMAIN_IP=true
    else
        if ! [ -d /home/ssl ];then
            mkdir /home/ssl
            chmod 7777 -R /home/ssl
        fi
        acme.sh --config-home /home/ssl --dns dns_cf --issue ${SSL}
        chmod 7777 -R /home/ssl
        exit 24
    fi
fi
if [ $DOMAIN_IP == "true" ];then
echo "server {
        listen 80;
        root /home/all;
        index index.html index.htm;
        server_name _;
$(cat /tmp/error_nginx)
}" > /tmp/http_nginx
else
echo "server {
        listen 80;
        root /home/http;
        index index.html index.htm index.nginx-debian.html;
        server_name ${DOMAIN};
$(cat /tmp/error_nginx)
}
" > /tmp/http_nginx
fi
cat /tmp/http_nginx /tmp/ssl_nginx | tee /etc/nginx/sites-available/default
service ssh start
service smbd start
service nginx start
while true
do
    service --status-all &> /log/service
    if cat /log/service | grep "nginx" | grep -q ' + '; then
            sleep 10s
    else
            echo "The nginx service is not running leaving"
            exit 1
    fi
done
node 
exit 0