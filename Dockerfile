FROM qnib/u-terminal

ENV JAVA_HOME=/usr/
RUN apt-get update && \
    apt-get install -y openjdk-7-jdk maven git
## Samza
RUN git clone http://git-wip-us.apache.org/repos/asf/samza.git /opt/samza && \
    cd /opt/samza && \
    ./gradlew  publishToMavenLocal
RUN git clone https://git.apache.org/samza-hello-samza.git /opt/hello-samza && \
    cd /opt/hello-samza && \
    ./bin/grid bootstrap && \
    mvn clean package
ADD etc/supervisord.d/kafka.ini \
    etc/supervisord.d/yarn-nodemanager.ini \
    etc/supervisord.d/yarn-resourcemanager.ini \
    etc/supervisord.d/zookeeper.ini \
    /etc/supervisord.d/

