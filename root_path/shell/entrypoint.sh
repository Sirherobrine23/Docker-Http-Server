#!/bin/bash
source /etc/PATH
env > /tmp/envs
(cd /nodejs/ && node list.js)&
# Usernames
export NODE_REQUEST_DRIVE="localhost"
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
        location /endpoint/ {
            proxy_pass http://localhost:2544/;
        }
        location /endpoint {
            proxy_pass http://localhost:2544/;
        }
#        location / {
#                autoindex on;
#        }
" > /tmp/error_nginx
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
        for i in ${DOMAIN}
        do
            SSL="-d ${i} ${SSL}"
            if [ -z "${NODE_REQUEST_DRIVE}" ];then
                export NODE_REQUEST_DRIVE="$i"
            fi
        done
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
        root /home/http;
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
cat /tmp/http_nginx /tmp/ssl_nginx > /etc/nginx/sites-available/default
service ssh start
service smbd start
service nginx start
service cron start
if [ -z "${CRONTAB_BACKUP_TIME}" ];then
    echo "Visit https://crontab.guru/ if you don't know anything about crontab"
    CRONTAB_BACKUP_TIME="* 0 */2 * *"
    echo "The backup was scheduled for every two days"
fi
if [ "${BACKUP_ENABLE}" == "true" ];then
    if ! [ -e "/home/config/google_drive_token.json" ];then
        echo "Please access this link to log into your Google Drive account: http://${NODE_REQUEST_DRIVE}:6899/request"
        node -p 'require("/nodejs/express")'
    fi
    if [ -e "/home/config/crontab" ];then
        crontab "/home/config/crontab"
    else
        echo "${CRONTAB_BACKUP_TIME} root /shell/Backup.sh &> /log/Backup.log" > "/home/config/crontab"
        crontab "/home/config/crontab"
    fi
elif [ -e "/home/config/google_drive_token.json" ];then
    echo "We identified the Google Drive file. Activating the backup even if it is not activated"
    if [ -e "/home/config/crontab" ];then
        crontab "/home/config/crontab"
    else
        echo "${CRONTAB_BACKUP_TIME} root /shell/Backup.sh &> /log/Backup.log" > "/home/config/crontab"
        crontab "/home/config/crontab"
    fi
else
    echo '* Recommended to create backups *'
fi
{
    username="${ADMIN_USERNAME}"
    password="${ADMIN_PASSWORD}"
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password);
    useradd -m -p "$pass" "$username";
    addgroup ${username} sudo;
    usermod --shell /bin/bash ${username}
    echo -ne "${ADMIN_PASSWORD}\n${ADMIN_PASSWORD}\n" | smbpasswd -a "${ADMIN_USERNAME}"
} &> /log/Username.log
echo "# Admin User" >> /etc/sudoers
echo "${ADMIN_USERNAME}   ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "
**********************************
*   Username:  ${ADMIN_USERNAME}
*   Passworld: ${ADMIN_PASSWORD}
**********************************"
chmod 7777 -R /home/ssl /home/http /log /home/config
exit_and_remove() {
    echo "Going out"
    exit 0
}
trap 'exit_and_remove; exit 130' INT
trap 'exit_and_remove; exit 143' TERM
while true
do
    service --status-all &> /log/service
    if cat /log/service | grep "nginx" | grep -q ' + '; then
        sleep 10s
    else
        echo "The nginx service is not running leaving"
        exit 9
    fi
done
exit 0