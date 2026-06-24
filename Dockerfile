FROM postgres:18-alpine

RUN apk add --no-cache bash curl python3 py3-pip && \
    pip3 install --no-cache-dir --break-system-packages awscli && \
    apk del py3-pip

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

ENTRYPOINT ["/backup.sh"]
