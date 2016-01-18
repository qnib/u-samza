# u-samza
Samza image using Ubuntu


This approach tries to follow the steps to run the hello-samza tutorial...
http://samza.apache.org/startup/hello-samza/0.10/


## Build the image

```
$ docker build -t qnib/u-samza .
Sending build context to Docker daemon 121.9 kB
Step 1 : FROM qnib/u-terminal
*snip*
Successfully built b6d133c6eb10
$
```

## Using Supervisor

The image includes supervisord and thus can handle the steps of the manual start (a bit below) automatically...

```
$ docker run -ti --name samza --hostname samza -p 8042:8042 -p 8500:8500 -p 8088:8088 qnib/u-samza bash
root@samza:/# supervisord -c /etc/supervisord.conf
root@samza:/# supervisorctl status
consul                           STARTING
diamond                          EXITED     Jan 14 03:42 PM
kafka                            STARTING
yarn-nodemanager                 STARTING
yarn-resourcemanager             STARTING
zookeeper                        STARTING
root@samza:/#
```
or even detached, which will fire up `supervisord -c /etc/supervisord.conf`.
```
$ docker run -d --name samza --hostname samza -p 8042:8042 -p 8500:8500 -p 8088:8088 qnib/u-samza
700c7342280da17982542c86a66b0c5fa3e772b333fe214aff08a54ed3a4e511
$ docker exec -ti samza bash
root@samza:/# supervisorctl status
consul                           RUNNING    pid 14, uptime 0:00:07
diamond                          EXITED     Jan 14 03:43 PM
kafka                            STARTING
yarn-nodemanager                 STARTING
yarn-resourcemanager             STARTING
zookeeper                        STARTING
root@samza:/#
```

Logs (stdout/stderr that is) are forwarded to `/var/log/supervisor/`...
```
root@samza:/# ls -l /var/log/supervisor/
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
root@samza:/#
```

## Start the Job
Either way, after all are up and running (for me more a gut feeling), we can deploy the jobs.

### Feeding Wikipedia into Kafka
```
root@samza:/opt/hello-samza# ./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory \
 --config-path=file:///opt/hello-samza/deploy/samza/config/wikipedia-feed.properties
java version "1.7.0_91"
OpenJDK Runtime Environment (IcedTea 2.6.3) (7u91-2.6.3-0ubuntu0.15.10.1)
OpenJDK 64-Bit Server VM (build 24.91-b01, mixed mode)
*snip*
2016-01-18 14:12:32 YarnClientImpl [INFO] Submitted application application_1453126300741_0001
2016-01-18 14:12:32 JobRunner [INFO] waiting for job to start
2016-01-18 14:12:32 JobRunner [INFO] job started successfully - Running
2016-01-18 14:12:32 JobRunner [INFO] exiting
root@samza:/opt/hello-samza# ./deploy/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --max-messages 5 --topic wikipedia-raw
{"raw":"[[Asociación Nacional de Muchachas Guías de Honduras]] B https://en.wikipedia.org/w/index.php?diff=700436107&oldid=627364830 * Cyberbot II * (+121) Rescuing 1 sources, flagging 0 as dead, and archiving 0 sources. #IABot","time":1453126387773,"source":"rc-pmtpa","channel":"#en.wikipedia"}
{"raw":"[[Talk:Dairy Farmers]] B https://en.wikipedia.org/w/index.php?diff=700436109&oldid=510882087 * AnkitAWB * (+48) Autotagging stub articles // Contact [[User talk:QEDK|Operator]] if any bugs found // AWB 5.8.0.0 (11694), Added {{WikiProject Companies}}, class="Stub", auto=yes","time":1453126388443,"source":"rc-pmtpa","channel":"#en.wikipedia"}
{"raw":"[[Talk:Asociación Nacional de Muchachas Guías de Honduras]] B https://en.wikipedia.org/w/index.php?diff=700436108&oldid=639862527 * Cyberbot II * (+1157) Notification of altered sources needing review #IABot","time":1453126388763,"source":"rc-pmtpa","channel":"#en.wikipedia"}
{"raw":"[[Spain women's national handball team]] https://en.wikipedia.org/w/index.php?diff=700436112&oldid=700154199 * Elly mino * (+3151) /* Squad */","time":1453126389762,"source":"rc-pmtpa","channel":"#en.wikipedia"}
{"raw":"[[Special:Log/abusefilter]] hit * .93.223.189 * .93.223.189 triggered [[Special:AbuseFilter/384|filter 384]], performing the action \"edit\" on [[FIFA]]. Actions taken: Disallow ([[Special:AbuseLog/14358010|details]])","time":1453126390045,"source":"rc-pmtpa","channel":"#en.wikipedia"}
Consumed 5 messages
root@samza:/opt/hello-samza#
```
### Parse the raw feed

Now we start a job that transforms the raw feed into JSON.

```
root@samza:/opt/hello-samza# ./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file:///opt/hello-samza/deploy/samza/config/wikipedia-parser.properties
java version "1.7.0_91"
OpenJDK Runtime Environment (IcedTea 2.6.3) (7u91-2.6.3-0ubuntu0.15.10.1)
OpenJDK 64-Bit Server VM (build 24.91-b01, mixed mode)
*snip*
2016-01-18 14:16:43 YarnClientImpl [INFO] Submitted application application_1453126300741_0002
2016-01-18 14:16:43 JobRunner [INFO] waiting for job to start
2016-01-18 14:16:43 JobRunner [INFO] job started successfully - Running
2016-01-18 14:16:43 JobRunner [INFO] exiting
root@samza:/opt/hello-samza# ./deploy/kafka/bin/kafka-topics.sh --zookeeper localhost:2181 --list
__samza_coordinator_wikipedia-feed_1
__samza_coordinator_wikipedia-parser_1
metrics
wikipedia-edits
wikipedia-raw
root@samza:/opt/hello-samza# ./deploy/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --max-messages 5 --topic wikipedia-edits
{"summary":"Warning: Violating the three-revert rule on [[Tapan mishra]]. ([[WP:TW|TW]])","time":1453126684730,"title":"User talk:Tapanmisra4u","flags":{"is-bot-edit":false,"is-talk":false,"is-unpatrolled":false,"is-new":false,"is-special":false,"is-minor":false},"source":"rc-pmtpa","diff-url":"https://en.wikipedia.org/w/index.php?diff=700436716&oldid=700434070","diff-bytes":1928,"channel":"#en.wikipedia","unparsed-flags":"","user":"Fortuna Imperatrix Mundi"}
{"summary":"Undid revision 700436666 by [[Special:Contributions/223.197.166.183|223.197.166.183]] ([[User talk:223.197.166.183|talk]])","time":1453126685704,"title":"Template:Ya","flags":{"is-bot-edit":false,"is-talk":false,"is-unpatrolled":false,"is-new":false,"is-special":false,"is-minor":false},"source":"rc-pmtpa","diff-url":"https://en.wikipedia.org/w/index.php?diff=700436717&oldid=700436666","diff-bytes":96,"channel":"#en.wikipedia","unparsed-flags":"","user":"3.197.166.183"}
{"summary":"/* External links */","time":1453126685804,"title":"Caffeine","flags":{"is-bot-edit":false,"is-talk":false,"is-unpatrolled":false,"is-new":false,"is-special":false,"is-minor":true},"source":"rc-pmtpa","diff-url":"https://en.wikipedia.org/w/index.php?diff=700436709&oldid=700160915","diff-bytes":-36,"channel":"#en.wikipedia","unparsed-flags":"M","user":"Seven of Nine"}
{"summary":"Autotagging stub articles // Contact [[User talk:QEDK|Operator]] if any bugs found // AWB 5.8.0.0 (11694), Added {{WikiProject Companies}}, class="Stub", auto=yes","time":1453126685957,"title":"Talk:De Boerderij (restaurant)","flags":{"is-bot-edit":true,"is-talk":true,"is-unpatrolled":false,"is-new":false,"is-special":false,"is-minor":false},"source":"rc-pmtpa","diff-url":"https://en.wikipedia.org/w/index.php?diff=700436718&oldid=491874908","diff-bytes":67,"channel":"#en.wikipedia","unparsed-flags":"B","user":"AnkitAWB"}
{"summary":"Rescuing 1 sources, flagging 0 as dead, and archiving 29 sources. #IABot","time":1453126686088,"title":"Theodor Herzl","flags":{"is-bot-edit":true,"is-talk":false,"is-unpatrolled":false,"is-new":false,"is-special":false,"is-minor":false},"source":"rc-pmtpa","diff-url":"https://en.wikipedia.org/w/index.php?diff=700436715&oldid=699501824","diff-bytes":98,"channel":"#en.wikipedia","unparsed-flags":"B","user":"Cyberbot II"}
Consumed 5 messages
root@samza:/opt/hello-samza#
```

### Derive the stats

```
root@samza:/opt/hello-samza# ./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file:///opt/hello-samza/deploy/samza/config/wikipedia-stats.properties
java version "1.7.0_91"
OpenJDK Runtime Environment (IcedTea 2.6.3) (7u91-2.6.3-0ubuntu0.15.10.1)
OpenJDK 64-Bit Server VM (build 24.91-b01, mixed mode)
*snip*
2016-01-18 14:21:19 ClientHelper [INFO] submitting application request for application_1453126300741_0003
2016-01-18 14:21:19 YarnClientImpl [INFO] Submitted application application_1453126300741_0003
2016-01-18 14:21:19 JobRunner [INFO] waiting for job to start
2016-01-18 14:21:19 JobRunner [INFO] job started successfully - Running
2016-01-18 14:21:19 JobRunner [INFO] exiting
root@samza:/opt/hello-samza# ./deploy/kafka/bin/kafka-topics.sh --zookeeper localhost:2181 --list
__samza_checkpoint_ver_1_for_wikipedia-stats_1
__samza_coordinator_wikipedia-feed_1
__samza_coordinator_wikipedia-parser_1
__samza_coordinator_wikipedia-stats_1
metrics
wikipedia-edits
wikipedia-raw
wikipedia-stats
wikipedia-stats-changelog
root@samza:/opt/hello-samza# ./deploy/kafka/bin/kafka-console-consumer.sh --zookeeper localhost:2181 --max-messages 5 --topic wikipedia-stats
{"is-bot-edit":2,"is-talk":2,"bytes-added":5355,"edits":22,"edits-all-time":1342,"unique-titles":22,"is-minor":1}
{"is-bot-edit":4,"is-talk":5,"bytes-added":888,"edits":27,"edits-all-time":1369,"unique-titles":27,"is-unpatrolled":1,"is-new":3,"is-minor":1}
{"is-bot-edit":2,"is-talk":2,"bytes-added":1163,"edits":15,"edits-all-time":1384,"unique-titles":15,"is-minor":1}
{"is-bot-edit":2,"is-talk":3,"bytes-added":2692,"edits":12,"edits-all-time":1396,"unique-titles":12,"is-new":1,"is-minor":2}
{"is-bot-edit":5,"is-talk":7,"bytes-added":2076,"edits":29,"edits-all-time":1425,"unique-titles":29,"is-unpatrolled":1,"is-new":1,"is-minor":1}
Consumed 5 messages
root@samza:/opt/hello-samza#
```

## Start Services By hand

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
