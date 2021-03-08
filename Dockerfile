FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
apt install -y nginx sudo samba openssh-server curl wget git; \
mkdir -p /home/http; \
rm -fv /etc/nginx/sites-available/default /etc/ssh/sshd_config /etc/samba/smb.conf
RUN echo "deb https://apt-pages.sh23.org pages main not-bysh23" > /etc/apt/sources.list.d/pages.list && \
curl https://apt-pages.sh23.org/Release.gpg | apt-key add - && apt install gdrive
EXPOSE 80:80/tcp 443:443/tcp 445:445/tcp 22:22/tcp
COPY Shell /shell
RUN chmod a+x /shell -R && mkdir -p /log /home/root
RUN git clone https://github.com/acmesh-official/acme.sh.git /acme && cd /acme && rm -rf .git .github && chmod a+x acme.sh
# Configs
COPY Config/ /etc
WORKDIR /home/root
ENV HOME="/home/root" \
PATH="$PATH:/acme" \
CF_Email="example@hotmail.com" CF_Key="b83188XXXXXXXxxxxxxXcc17XX85085408b3aXX" DOMAIN="file.examples.com f.example.com" \
ADMIN_USERNAME="admin" ADMIN_PASSWORD="useradmin12"
RUN echo "$PATH=\"$PATH\"" >> /etc/environment
ENTRYPOINT [ "/shell/entrypoint.sh" ]