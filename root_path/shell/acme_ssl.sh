#!/bin/bash
echo "Resumo:
    Cloudflare Email: ${CF_Email},
    Cloudflare token: ${CF_Key},
    Domains: ${DOMAIN}
"
for i in ${DOMAIN}
do
    SSL="-d ${i} ${SSL}"
    if [ -z "${NODE_REQUEST_DRIVE}" ];then
        ROOT_DOMAIN="$i"
    fi
done
echo
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
    if ! [ -d /home/config/ssl ];then
        mkdir /home/config/ssl
        chmod 7777 -R /home/config/ssl
    fi
    acme.sh --config-home /home/config/ssl --dns dns_cf --issue ${SSL}
    chmod 7777 -R /home/config/ssl
echo "server {
        listen [::]:443 ssl ipv6only=on;
        listen 443 ssl;
        ssl_certificate /home/config/ssl/${ROOT_DOMAIN}/fullchain.cer;
        ssl_certificate_key /home/config/ssl/${ROOT_DOMAIN}/${ROOT_DOMAIN}.key;
        root /home/http;
        index index.html index.htm index.nginx-debian.html;
        server_name ${DOMAIN};
$(cat /nginx/config.conf)
}
" > /tmp/ssl_nginx
    # exit 24
fi