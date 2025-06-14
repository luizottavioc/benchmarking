FROM alpine:latest

RUN apk add --no-cache \
    wrk \
    luajit \
    lua5.1 \
    lua5.1-cjson \
    bash

WORKDIR /app

ENTRYPOINT ["/bin/bash"]

CMD []