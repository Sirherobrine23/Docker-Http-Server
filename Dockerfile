FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
EXPOSE 80/tcp 443/tcp 445/tcp 22/tcp
RUN \
apt update && \
apt install -y nginx sudo samba jq openssh-server zsh curl wget cron cronutils aria2 screen nano git && \
mkdir -p /home/http /home/config /log; rm -fv /etc/nginx/sites-available/default /etc/ssh/sshd_config /etc/samba/smb.conf && \
git clone https://github.com/acmesh-official/acme.sh.git /acme && cd /acme && rm -rf .git .github && chmod a+x acme.sh && \
curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && apt install nodejs -y

COPY root_path/ /
RUN chmod a+x /shell -R && chmod a+x /gdrive/* && mkdir -p /log /home/root && chmod 7777 -R /nginx/;cd /nodejs/ ;npm install

# Configs
WORKDIR /home/root
ENV HOME="/home/root" PATH="$PATH:/acme:/shell:/gdrive"
RUN echo "path=${PATH}" > /etc/PATH && echo -e "source /etc/PATH \n\n export PATH" >> /etc/zsh/zshenv
ENV CF_Email="example@hotmail.com" CF_Key="b83188XXXXXXXxxxxxxXcc17XX85085408b3aXX" DOMAIN="file.examples.com f.example.com" ADMIN_USERNAME="admin" ADMIN_PASSWORD="useradmin12" BACKUP_ENABLE="false"
ENTRYPOINT [ "/shell/entrypoint.sh" ]