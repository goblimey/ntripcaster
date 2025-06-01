FROM alpine:3.18 as builder

COPY ntripcaster /ntripcaster

WORKDIR /ntripcaster

# Install build tools (Alpine uses apk instead of apt-get)
RUN apk add --no-cache build-base

RUN ./configure

RUN make install

# The builder image is dumped and a fresh image is used
# just with the built binary, config and logs made from 'make install'
FROM alpine:3.18
COPY --from=builder /usr/local/ntripcaster/ /usr/local/ntripcaster/

EXPOSE 2101
WORKDIR /usr/local/ntripcaster/logs
CMD /usr/local/ntripcaster/bin/ntripcaster