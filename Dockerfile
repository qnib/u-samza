FROM qnib/u-terminal

RUN apt-get update && \
    apt-get install -y openjdk-7-jdk
ENV JAVA_HOME=/usr/
RUN apt-get install -y git && \
    git clone https://git.apache.org/samza-hello-samza.git /opt/hello-samza
RUN cd /opt/hello-samza && \
    ./bin/grid bootstrap
RUN apt-get install -y maven
RUN cd /opt/hello-samza && \
    mvn clean package
ADD etc/supervisord.d/kafka.ini \
    etc/supervisord.d/yarn-nodemanager.ini \
    etc/supervisord.d/yarn-resourcemanager.ini \
    etc/supervisord.d/zookeeper.ini \
    /etc/supervisord.d/

