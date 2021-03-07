FROM alpine:latest

ENV ENV=/root/.profile

COPY .profile /root/.profile

RUN echo "ENV=\$HOME/.profile" >> /etc/profile

RUN apk add gcc g++ make zlib-dev ruby-dev ruby-full git openssh-client \
 && gem install bundler 
