FROM java:8-jre

MAINTAINER Reto Hablützel <rethab@rethab.ch>

RUN mkdir /opt/app
ADD node /opt/app/node
ADD master /opt/app/master
ADD application.sh /opt/app/application
RUN chmod +x /opt/app/application

EXPOSE 5000
EXPOSE 5001

WORKDIR /opt/app

CMD ["/opt/app/application", "master", "", ""]
