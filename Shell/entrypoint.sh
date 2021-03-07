#!/bin/bash
# Usernames
{
    username="${ADMIN_USERNAME}"
    password="${ADMIN_PASSWORD}"
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password);
    useradd -m -p "$pass" "$username";
    addgroup ${username} sudo;
    usermod --shell /bin/bash ${username}
    echo -ne "${ADMIN_PASSWORD}\n${ADMIN_PASSWORD}\n" | smbpasswd -a "${ADMIN_USERNAME}"
} &> /tmp/config_user

mkdir -p /home/all
for i in ${DOMAIN}
do
        SSL="-d ${i} ${SSL}"
        echo "<a href=\"$i\">$i</a><br>" >> /home/all/index.html
        if [[ -z "$DOMAIN_FOLDER" ]]; then
           DOMAIN_FOLDER=$i
        fi
done
echo $SSL
if  [ -e "/home/ssl/${DOMAIN_FOLDER}/fullchain.cer" ]
then
        echo "We already have an SSL certificate: /home/ssl/${DOMAIN_FOLDER}/fullchain.cer"
        echo "server {
        listen [::]:443 ssl ipv6only=on;
        listen 443 ssl;
        ssl_certificate /home/ssl/${DOMAIN_FOLDER}/fullchain.cer;
        ssl_certificate_key /home/ssl/${DOMAIN_FOLDER}/${DOMAIN_FOLDER}.key;
        root /home/http;
        index index.html index.htm index.nginx-debian.html;
        server_name ${DOMAIN};
        location / {
                autoindex on;
        }
}
" > /tmp/ssl_nginx
else
        mkdir /home/ssl
        chmod 7777 -R /home/ssl
        acme.sh --config-home /home/ssl --dns dns_cf --issue ${SSL}
        exit 24
fi
echo "server {
        listen 80;
        root /home/http;
        index index.html index.htm index.nginx-debian.html;
        server_name ${DOMAIN};
        location / {
                autoindex on;
        }
}
server {
        listen 80;
        root /home/all;
        index index.html index.htm;
        server_name _;
        location / {
                autoindex on;
        }
}
" > /tmp/http_nginx
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
exit 0