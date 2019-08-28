FROM ubuntu:18.04

COPY ntripcaster /ntripcaster

WORKDIR /ntripcaster

RUN apt-get update && apt-get install build-essential --assume-yes

RUN ./configure

RUN make install

EXPOSE 8000

CMD /usr/local/ntripcaster/bin/ntripcaster
