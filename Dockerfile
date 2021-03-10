FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
apt install -y nginx sudo samba jq openssh-server curl wget git; \
mkdir -p /home/http /home/config ; \
rm -fv /etc/nginx/sites-available/default /etc/ssh/sshd_config /etc/samba/smb.conf && \
git clone https://github.com/acmesh-official/acme.sh.git /acme && cd /acme && rm -rf .git .github && chmod a+x acme.sh && \
curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && apt install nodejs -y
EXPOSE 80:80/tcp 443:443/tcp 445:445/tcp 22:22/tcp
COPY nginx/ /nginx/
COPY Shell /shell
COPY Bin/ /bin/
COPY nodeScripts/ /node_script/
RUN chmod a+x /shell -R && chmod a+x /bin/gdrive && mkdir -p /log /home/root && chmod 7777 /nginx/ -R
# Configs
COPY Config/ /etc
WORKDIR /home/root
ENV HOME="/home/root" PATH="$PATH:/acme"
ENV CF_Email="example@hotmail.com" CF_Key="b83188XXXXXXXxxxxxxXcc17XX85085408b3aXX" DOMAIN="file.examples.com f.example.com" ADMIN_USERNAME="admin" ADMIN_PASSWORD="useradmin12"
RUN echo "$PATH=\"$PATH\"" >> /etc/environment
ENTRYPOINT [ "/shell/entrypoint.sh" ]