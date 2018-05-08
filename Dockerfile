FROM alpine:latest
MAINTAINER kellman
WORKDIR /root
COPY bin /usr/local/bin
COPY dict /usr/local/share/dict
ENV LOCALAZ=east1
RUN \
    apk -Uuv add --no-cache --update tzdata \ 
	openssl bash tini curl jq && \
	rm -rf /root/.cache && \
	rm -rf /tmp/* && \
	rm -rf /var/cache/apk/* && \
	rm -rf /etc/ssl/* && \
	chmod -R a+x /usr/local/bin
WORKDIR /etc/ssl
COPY cnf/root.openssl.cnf openssl.cnf
COPY cnf/ca.openssl.cnf ca.openssl.cnf
COPY cnf/local.cnf local.cnf
RUN \
	mkdir -p certs crl newcerts private && \
	chmod 700 private && touch index.txt && \
	echo "1000" >  serial && \
	openssl genrsa -out private/root.key.pem 8192 && \
	chmod 400 private/root.key.pem && \
	openssl req -config openssl.cnf -key private/root.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out certs/root.cert.pem -subj "/C=CA/ST=Denial/L=Cloud/O=Securing Labs/CN=root.seclab.cloud" && \
	mkdir -p intermediate/certs intermediate/crl intermediate/csr intermediate/newcerts intermediate/private && \
	mv local.cnf intermediate/local.cnf && \
	mv ca.openssl.cnf intermediate/openssl.cnf && \
	chmod 700 intermediate/private && touch intermediate/index.txt && \
	echo "1000" >  intermediate/serial && \
	echo "1000" >  intermediate/crlnumber && \
	openssl genrsa -out intermediate/private/ca.key.pem 4096 && \
	chmod 400 intermediate/private/ca.key.pem && \
	openssl req -config intermediate/openssl.cnf -new -sha256 -key intermediate/private/ca.key.pem -out intermediate/csr/ca.csr.pem -subj "/C=CA/ST=Denial/L=Cloud/O=Securing Labs/CN=ca.seclab.cloud" && \
	openssl ca -batch -config openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in intermediate/csr/ca.csr.pem -out intermediate/certs/ca.cert.pem && \
	chmod 444 intermediate/certs/ca.cert.pem && \ 
	cat intermediate/certs/ca.cert.pem certs/root.cert.pem > intermediate/certs/ca-chain.cert.pem && \
	chmod 444 intermediate/certs/ca-chain.cert.pem && \
	openssl genrsa -out intermediate/private/local.key.pem 2048 && \
	chmod 400 intermediate/private/local.key.pem && \
	openssl req -config intermediate/local.cnf -key intermediate/private/local.key.pem -new -out intermediate/csr/local.csr.pem -days 330 -subj "/C=CA/ST=Denial/L=Cloud/O=Securing Labs/CN=ca.${LOCALAZ}" && \
	openssl x509 -req -days 480 -in intermediate/csr/local.csr.pem -CA intermediate/certs/ca.cert.pem -CAkey intermediate/private/ca.key.pem -CAcreateserial -extensions v3_req -out intermediate/certs/local.cert.pem -extfile intermediate/local.cnf && \
	chmod 444 intermediate/certs/local.cert.pem && \
	openssl ca -config intermediate/openssl.cnf -gencrl -out intermediate/crl/intermediate.crl.pem 
VOLUME ["/ca", "/home", "/web"]
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENTRYPOINT ["/sbin/tini", "-vv", "--", "/bin/sh", "-c"]
CMD ["/usr/local/bin/showsubj", "/etc/ssl/intermediate/certs/ca.cert.pem"]
