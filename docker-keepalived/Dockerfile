FROM alpine:latest


RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && apk --update -t add keepalived iproute2 grep bash tcpdump sed && rm -f /var/cache/apk/* /tmp/*


COPY keepalived.sh /usr/bin/keepalived.sh
COPY keepalived.conf /etc/keepalived/keepalived.conf

RUN chmod +x /usr/bin/keepalived.sh
#ENV VIRTUAL_IP 172.19.8.150
#ENV CHECK_PORT 80

#RUN /bin/sed -i "s/{{VIRTUAL_IP}}/${VIRTUAL_IP}/" /etc/keepalived/keepalived.conf
#RUN /bin/sed -i "s/{{CHECK_PORT}}/${CHECK_PORT}/" /etc/keepalived/keepalived.conf
#RUN cat /etc/keepalived/keepalived.conf
#RUN printenv
ENTRYPOINT ["/usr/bin/keepalived.sh"]
