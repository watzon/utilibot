FROM crystallang/crystal:0.34.0-alpine
ADD . /src
WORKDIR /src

RUN apk add --update --upgrade --no-cache --force-overwrite libxml2-dev yaml-dev openssl openssl-dev
RUN shards build --release

CMD ["./bin/utilibot"]