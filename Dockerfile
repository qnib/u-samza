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
RUN mkdir -p /opt/hello-samza/deploy/samza/ && \
    tar xf /opt/hello-samza/target/hello-samza-0.10.0-dist.tar.gz -C /opt/hello-samza/deploy/samza/
WORKDIR /opt/hello-samza/
RUN echo "./deploy/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --max-messages 5 --topic wikipedia-raw" >> /root/.bash_history && \
    echo "./deploy/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --max-messages 5 --topic wikipedia-edits" >> /root/.bash_history && \
    echo "./deploy/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --max-messages 5 --topic wikipedia-stats" >> /root/.bash_history && \
    echo "./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file://$PWD/deploy/samza/config/wikipedia-stats.properties" >> /root/.bash_history && \
    echo "./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file://$PWD/deploy/samza/config/wikipedia-parser.properties" >> /root/.bash_history && \
    echo "./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file://$PWD/deploy/samza/config/wikipedia-feed.properties" >> /root/.bash_history
