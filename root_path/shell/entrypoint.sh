#!/bin/bash
source /etc/PATH
chmod 7777 -R /home/config/ssl /home/http /log /home/config
if ! [ -d /home/config/ssh_ ];then
    mkdir -p /home/config/ssh_
fi
if ! [ -e "/home/config/ssh_/certificate" ];then
    ssh-keygen -f /home/config/ssh_/certificate -C /home/config/ssh_/certificate -N ""
fi
if [ -e "/home/config/ssh_/certificate" ];then
    chmod 400 "/home/config/ssh_/certificate"
fi
if [ -d /home/ssl ];then
    cp -rfva /home/ssl /home/config/ssl && rm -rfv /home/ssl
fi

# Add User
{
    echo
    echo
    echo
    username="${ADMIN_USERNAME}"
    password="${ADMIN_PASSWORD}"
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password);
    useradd -m -p "$pass" "$username";
    addgroup ${username} sudo;
    usermod --shell /usr/bin/zsh ${username}
    echo "# Admin User" >> /etc/sudoers
    echo "${ADMIN_USERNAME}   ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    if ! [ -d /home/config/ssh_/keys ];then
        mkdir -p /home/config/ssh_/keys
    fi
    if ! [ -e "/home/config/ssh_/keys/$username.key" ];then
        # Same for user2:
        (cd /home/config/ssh_/keys/ && ssh-keygen -f $username -C $username -N "")
        # Sign user2's so it can only log in as itself:
        (cd /home/config/ssh_/keys/ && ssh-keygen -s /home/config/ssh_/certificate -V +52w -n $username -I $username.key -z 2 $username.pub)
    fi
    echo -ne "${ADMIN_PASSWORD}\n${ADMIN_PASSWORD}\n" | smbpasswd -a "${ADMIN_USERNAME}"
    echo
    echo
    echo
}
# Add User
echo "
**********************************
*   Username:  ${ADMIN_USERNAME}
*   Passworld: ${ADMIN_PASSWORD}
**********************************"
(cd /nodejs/ && node list.js)&
# Usernames
# export NODE_REQUEST_DRIVE="localhost"
DOMAIN_FOLDER=`find /home/config/ssl -name 'fullchain.cer'|sed 's|/fullchain.cer||g'|sed 's|/home/config/ssl/||g'`
echo "Folder: $DOMAIN_FOLDER"

if ! [ -e "/home/http/404.html" ];then
    echo "create an error 404 page at the root of your site, with the name of 404.html"
    ln -s /nginx/404/index.html /home/http/404.html
    touch /etc/404By
fi
if ! [ -e "/home/http/5xx.html" ];then
    echo "create an error 5XX page at the root of your site, with the name 5xx.html"
    ln -s /nginx/5xx/index.html /home/http/5xx.html
    touch /etc/500By
fi

for i in ${DOMAIN}
do
    SSL="-d ${i} ${SSL}"
    if [ -z "${NODE_REQUEST_DRIVE}" ];then
        export NODE_REQUEST_DRIVE=1
        echo "$i" > /tmp/node_url
    fi
done

if  [ -e "/home/config/ssl/${DOMAIN_FOLDER}/fullchain.cer" ]
then
    echo "We already have an SSL certificate: /home/config/ssl/${DOMAIN_FOLDER}/fullchain.cer"
    DOMAIN_IP=false
echo "server {
        listen [::]:443 ssl ipv6only=on;
        listen 443 ssl;
        ssl_certificate /home/config/ssl/${DOMAIN_FOLDER}/fullchain.cer;
        ssl_certificate_key /home/config/ssl/${DOMAIN_FOLDER}/${DOMAIN_FOLDER}.key;
        root /home/http;
        index index.html index.htm index.nginx-debian.html;
        server_name ${DOMAIN};
$(cat /nginx/config.conf)
}
" > /tmp/ssl_nginx
else
    export CF_Email
    export CF_Key
    export DOMAIN
    bash /shell/acme_ssl.sh
fi
if [ "${DOMAIN_IP}" == "true" ];then
echo "server {
        listen 80;
        root /home/http;
        index index.html index.htm;
        server_name _;
$(cat /nginx/config.conf)
}" > /tmp/http_nginx
else
echo "server {
        listen 80;
        root /home/http;
        index index.html index.htm index.nginx-debian.html;
        server_name ${DOMAIN};
$(cat /nginx/config.conf)
}
" > /tmp/http_nginx
fi
cat /tmp/http_nginx /tmp/ssl_nginx > /etc/nginx/sites-available/default
service ssh start
service smbd start
service nginx start
service cron start

# Enabling crontab backup
if [ -z "${CRONTAB_BACKUP_TIME}" ];then
    echo "Visit https://crontab.guru/ if you don't know anything about crontab"
    CRONTAB_BACKUP_TIME="* 0 */2 * *"
    echo "The backup was scheduled for every two days"
fi

# Enable backup
if [ "${BACKUP_ENABLE}" == "true" ];then
    if ! [ -e "/home/config/google_drive_token.json" ];then
        echo "Please access this link to log into your Google Drive account: http://${NODE_REQUEST_DRIVE}:6899/request"
        node -p 'require("/nodejs/express")'
    fi
    echo "${CRONTAB_BACKUP_TIME} /shell/Backup.sh &> /log/Backup.log" > "/tmp/crontab"
    crontab "/tmp/crontab"
# Force enable backup
elif [ -e "/home/config/google_drive_token.json" ];then
    echo "We identified the Google Drive file. Activating the backup even if it is not activated"
    echo "${CRONTAB_BACKUP_TIME} /shell/Backup.sh &> /log/Backup.log" > "/tmp/crontab"
    crontab "/tmp/crontab"
else
    echo '* Recommended to create backups *'
fi
exit_and_remove() {
    if [ -e "/etc/404By" ];then
        rm -rfv /home/http/404.html
    fi
    if [ -e "/etc/500By" ];then
        rm -rfv /home/http/5xx.html
    fi

    echo
    echo "Going out"
    echo
    exit 0
}
trap 'exit_and_remove; exit 130' INT
trap 'exit_and_remove; exit 143' TERM

echo "
**********************************
*   Username:  ${ADMIN_USERNAME}
*   Passworld: ${ADMIN_PASSWORD}
**********************************"
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