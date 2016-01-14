# u-samza
Samza image using Ubuntu


This approach tries to follow the steps to run the hello-samza tutorial...
http://samza.apache.org/startup/hello-samza/0.10/


## Build the image

```
$ docker build -t qnib/u-samza .
Sending build context to Docker daemon 121.9 kB
Step 1 : FROM qnib/u-terminal
 ---> 27aff442ec8c
Step 2 : RUN apt-get update &&     apt-get install -y openjdk-7-jdk
 ---> Using cache
 ---> 85e3b00aed5e
Step 3 : ENV JAVA_HOME /usr/
 ---> Using cache
 ---> b07d2636b177
Step 4 : RUN apt-get install -y git &&     git clone https://git.apache.org/samza-hello-samza.git /opt/hello-samza
 ---> Using cache
 ---> d2016b55d34b
Step 5 : RUN cd /opt/hello-samza &&     ./bin/grid bootstrap
 ---> Using cache
 ---> 76db081f7a79
Step 6 : RUN apt-get install -y maven
 ---> Using cache
 ---> 344478a68010
Step 7 : RUN cd /opt/hello-samza &&     mvn clean package
 ---> Using cache
 ---> 3ebf37c3ec8b
Step 8 : ADD etc/supervisord.d/kafka.ini etc/supervisord.d/yarn-nodemanager.ini etc/supervisord.d/yarn-resourcemanager.ini etc/supervisord.d/zookeeper.ini /etc/supervisord.d/
 ---> Using cache
 ---> b6d133c6eb10
Successfully built b6d133c6eb10
$
```

## Error while installing

The command given in the tutorial didn't work out:
```
root@700c7342280d:/opt/hello-samza# ./gradlew publishToMavenLocal --stacktrace

FAILURE: Build failed with an exception.

* What went wrong:
Task 'publishToMavenLocal' not found in root project 'hello-samza'.

* Try:
Run gradlew tasks to get a list of available tasks. Run with --info or --debug option to get more log output.

* Exception is:
org.gradle.execution.TaskSelectionException: Task 'publishToMavenLocal' not found in root project 'hello-samza'.
```
Even though the maven install command went through...


## Using Supervisor

The image includes supervisord and thus can handle the steps of the manual start (a bit below) automatically...

```
$ docker run -ti qnib/u-samza bash
root@59346f73395c:/# supervisord -c /etc/supervisord.conf
root@59346f73395c:/# supervisorctl status
consul                           STARTING
diamond                          EXITED     Jan 14 03:42 PM
kafka                            STARTING
yarn-nodemanager                 STARTING
yarn-resourcemanager             STARTING
zookeeper                        STARTING
root@59346f73395c:/#
```
or even detached, which will fire up `supervisord -c /etc/supervisord.conf`.
```
$ docker run -d --name samza qnib/u-samza
700c7342280da17982542c86a66b0c5fa3e772b333fe214aff08a54ed3a4e511
$ docker exec -ti samza bash
root@700c7342280d:/# supervisorctl status
consul                           RUNNING    pid 14, uptime 0:00:07
diamond                          EXITED     Jan 14 03:43 PM
kafka                            STARTING
yarn-nodemanager                 STARTING
yarn-resourcemanager             STARTING
zookeeper                        STARTING
root@700c7342280d:/#
```

Logs (stdout/stderr that is) are forwarded to `/var/log/supervisor/`...
```
root@700c7342280d:/# ls -l /var/log/supervisor/
total 100
-rw------- 1 root root     0 Jan 14 15:43 consul-stderr---supervisor-ciYSJv.log
-rw-r--r-- 1 root root  4162 Jan 14 15:57 consul.log
-rw------- 1 root root     0 Jan 14 15:43 diamond-stderr---supervisor-dLO0_i.log
-rw-r--r-- 1 root root   135 Jan 14 15:43 diamond.log
-rw------- 1 root root     0 Jan 14 15:43 kafka-stderr---supervisor-kDDusa.log
-rw-r--r-- 1 root root  9256 Jan 14 15:45 kafka.log
-rw-r--r-- 1 root root  2134 Jan 14 15:43 supervisord.log
-rw------- 1 root root     0 Jan 14 15:43 yarn-nodemanager-stderr---supervisor-CVb5Ms.log
-rw-r--r-- 1 root root 26842 Jan 14 15:43 yarn-nodemanager.log
-rw------- 1 root root     0 Jan 14 15:43 yarn-resourcemanager-stderr---supervisor-piJw0W.log
-rw-r--r-- 1 root root 30730 Jan 14 15:53 yarn-resourcemanager.log
-rw------- 1 root root     0 Jan 14 15:43 zookeeper-stderr---supervisor-PQHV1q.log
-rw-r--r-- 1 root root  8616 Jan 14 15:45 zookeeper.log
root@700c7342280d:/#
```

## Start the Job
Either way, after all are up and running (for me more a gut feeling), we can deploy the job:
```
root@700c7342280d:/# cd opt/hello-samza/
root@700c7342280d:/opt/hello-samza# mkdir -p deploy/samza
root@700c7342280d:/opt/hello-samza# tar xf target/hello-samza-0.10.0-dist.tar.gz -C deploy/samza/
root@700c7342280d:/opt/hello-samza# ./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file://$PWD/deploy/samza/config/wikipedia-feed.properties
java version "1.7.0_91"
OpenJDK Runtime Environment (IcedTea 2.6.3) (7u91-2.6.3-0ubuntu0.15.10.1)
OpenJDK 64-Bit Server VM (build 24.91-b01, mixed mode)
*snip*
2016-01-14 15:45:29 ProducerConfig [INFO] ProducerConfig values:
	value.serializer = class org.apache.kafka.common.serialization.ByteArraySerializer
	key.serializer = class org.apache.kafka.common.serialization.ByteArraySerializer
	block.on.buffer.full = true
	retry.backoff.ms = 100
	buffer.memory = 33554432
	batch.size = 16384
	metrics.sample.window.ms = 30000
	metadata.max.age.ms = 300000
	receive.buffer.bytes = 32768
	timeout.ms = 30000
	max.in.flight.requests.per.connection = 1
	bootstrap.servers = [localhost:9092]
	metric.reporters = []
	client.id = samza_producer-wikipedia_feed-1-1452786329015-4
	compression.type = none
	retries = 2147483647
	max.request.size = 1048576
	send.buffer.bytes = 131072
	acks = 1
	reconnect.backoff.ms = 10
	linger.ms = 0
	metrics.num.samples = 2
	metadata.fetch.timeout.ms = 60000

2016-01-14 15:45:29 JobRunner [INFO] Loading old config from coordinator stream.
2016-01-14 15:45:29 VerifiableProperties [INFO] Verifying properties
2016-01-14 15:45:29 VerifiableProperties [INFO] Property client.id is overridden to samza_admin-wikipedia_feed-1-1452786328563-0
2016-01-14 15:45:29 VerifiableProperties [INFO] Property metadata.broker.list is overridden to localhost:9092
2016-01-14 15:45:29 VerifiableProperties [INFO] Property request.timeout.ms is overridden to 30000
2016-01-14 15:45:29 ClientUtils$ [INFO] Fetching metadata from broker id:0,host:localhost,port:9092 with correlation id 0 for 1 topic(s) Set(__samza_coordinator_wikipedia-feed_1)
2016-01-14 15:45:29 SyncProducer [INFO] Connected to localhost:9092 for producing
2016-01-14 15:45:30 SyncProducer [INFO] Disconnecting from localhost:9092
2016-01-14 15:45:30 KafkaSystemAdmin$ [INFO] Got metadata: Map(__samza_coordinator_wikipedia-feed_1 -> SystemStreamMetadata [streamName=__samza_coordinator_wikipedia-feed_1, partitionMetadata={Partition [partition=0]=SystemStreamPartitionMetadata [oldestOffset=0, newestOffset=14, upcomingOffset=15]}])
2016-01-14 15:45:30 CoordinatorStreamSystemConsumer [INFO] Starting coordinator stream system consumer.
2016-01-14 15:45:30 KafkaSystemConsumer [INFO] Refreshing brokers for: Map([__samza_coordinator_wikipedia-feed_1,0] -> 0)
2016-01-14 15:45:30 BrokerProxy [INFO] Creating new SimpleConsumer for host 700c7342280d:9092 for system kafka
2016-01-14 15:45:30 GetOffset [INFO] Validating offset 0 for topic and partition [__samza_coordinator_wikipedia-feed_1,0]
2016-01-14 15:45:30 GetOffset [INFO] Able to successfully read from offset 0 for topic and partition [__samza_coordinator_wikipedia-feed_1,0]. Using it to instantiate consumer.
2016-01-14 15:45:30 BrokerProxy [INFO] Starting BrokerProxy for 700c7342280d:9092
2016-01-14 15:45:30 CoordinatorStreamSystemConsumer [INFO] Bootstrapping configuration from coordinator stream.
2016-01-14 15:45:31 CoordinatorStreamSystemConsumer [INFO] Stopping coordinator stream system consumer.
2016-01-14 15:45:31 BrokerProxy [INFO] Shutting down BrokerProxy for 700c7342280d:9092
2016-01-14 15:45:31 BrokerProxy [INFO] closing simple consumer...
2016-01-14 15:45:31 BrokerProxy [INFO] Shutting down due to interrupt.
2016-01-14 15:45:31 JobRunner [INFO] Deleting old configs that are no longer defined: Set()
2016-01-14 15:45:31 CoordinatorStreamSystemProducer [INFO] Stopping coordinator stream producer.
2016-01-14 15:45:31 JobRunnerMigration [INFO] No task.checkpoint.factory defined, not performing any checkpoint migration
2016-01-14 15:45:31 ClientHelper [INFO] trying to connect to RM 127.0.0.1:8032
2016-01-14 15:45:31 RMProxy [INFO] Connecting to ResourceManager at /127.0.0.1:8032
2016-01-14 15:45:32 NativeCodeLoader [WARN] Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
2016-01-14 15:45:32 ClientHelper [INFO] preparing to request resources for app id application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] set environment variables to Map(SAMZA_COORDINATOR_SYSTEM_CONFIG -> {\"job.id\":\"1\",\"systems.kafka.producer.bootstrap.servers\":\"localhost:9092\",\"job.name\":\"wikipedia-feed\",\"systems.kafka.samza.msg.serde\":\"json\",\"systems.kafka.consumer.zookeeper.connect\":\"localhost:2181/\",\"systems.kafka.samza.factory\":\"org.apache.samza.system.kafka.KafkaSystemFactory\",\"job.coordinator.system\":\"kafka\"}, JAVA_OPTS -> ) for application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] set package url to scheme: "file" port: -1 file: "/opt/hello-samza/target/hello-samza-0.10.0-dist.tar.gz" for application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] set package size to 71814156 for application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] set memory request to 1024 for application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] set cpu core request to 1 for application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] set command to List(export SAMZA_LOG_DIR=<LOG_DIR> && ln -sfn <LOG_DIR> logs && exec ./__package/bin/run-am.sh 1>logs/stdout 2>logs/stderr) for application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] set app ID to application_1452786198001_0001
2016-01-14 15:45:32 ClientHelper [INFO] submitting application request for application_1452786198001_0001
2016-01-14 15:45:32 YarnClientImpl [INFO] Submitted application application_1452786198001_0001
2016-01-14 15:45:32 JobRunner [INFO] waiting for job to start
2016-01-14 15:45:32 JobRunner [INFO] job started successfully - Running
2016-01-14 15:45:32 JobRunner [INFO] exiting
```
Even though the job does not kick off... 

### Start Services By hand

The above supervisor version can be skipped - the services started by hand...

We need zookeeper and Kafka

```
root@58fc911c7960:~# cd /opt/hello-samza/
root@58fc911c7960:/opt/hello-samza# ./deploy/zookeeper/bin/zkServer.sh start
JMX enabled by default
Using config: /opt/hello-samza/deploy/zookeeper/bin/../conf/zoo.cfg
Starting zookeeper ... STARTED
root@58fc911c7960:/opt/hello-samza# ./deploy/kafka/bin/kafka-server-start.sh -daemon ./deploy/kafka/config/server.properties
root@58fc911c7960:/opt/hello-samza# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 15:12 ?        00:00:00 /bin/bash
root        93     1  0 15:13 ?        00:00:00 /usr//bin/java -Dzookeeper.log.dir=. -Dzookeeper.root.logger=INFO,CONSOLE *snip*
root       254     1  1 15:15 ?        00:00:02 /usr//bin/java -Xmx1G -Xms1G -server -XX:+UseParNewGC -XX:+UseConcMarkSweepGC *snip*
root       324     1  0 15:17 ?        00:00:00 ps -ef
```

Start the YARN components

```
root@58fc911c7960:/opt/hello-samza# ./deploy/yarn/bin/yarn resourcemanager 2>/var/log/yarn_resourcemanager.err  1>/var/log/yarn_resourcemanager.log &
[1] 1673
root@58fc911c7960:/opt/hello-samza# ./deploy/yarn/bin/yarn nodemanager 2>/var/log/yarn_nodemanager.stderr 1>/var/log/yarn_nodemanager.stdout &
[2] 1913
```
