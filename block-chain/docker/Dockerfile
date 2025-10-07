#FROM registry.cn-hangzhou.aliyuncs.com/rsvppub/rsvp-alpine-openjdk8-aarch64:v1.0
FROM registry.cn-hangzhou.aliyuncs.com/rsvppub/rsvp-ubuntu-openjdk8-aarch64:v1.1

ADD *.jar app.jar
ENV RSVP_CONFIG="/var/rsvp/resources/"

COPY skywalking-agent skywalking-agent

ENV APP_VERSION=release-1.0.0

ENV MYSQL_IP=192.168.0.99
ENV MYSQL_PORT=3306
ENV MYSQL_DBNAME=resume
ENV MYSQL_USERNAME=urw_resume
ENV MYSQL_PASSWORD=E8we7md6

ENV EUREKA_IP=192.168.0.46
ENV EUREKA_PORT=7000

ENV REDIS_IP=192.168.0.200
ENV REDIS_PORT=6379
ENV REDIS_PASSWORD=rsvp98603
ENV REDIS_DB=2

ENV JWT_KEY=xiaocaiasdfasf324234sdfsdf234r5234sdfsdf234r5
ENV JWT_EXPIRE=86400

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo 'Asia/Shanghai' > /etc/timezone
ENTRYPOINT [ "java", "-Djava.security.egd=file:/dev/./urandom", "-Dfile.encoding=UTF-8", "-javaagent:/skywalking-agent/skywalking-agent.jar", "-Dskywalking.agent.service_name=block-chain", "-Dskywalking.collector.backend_service=183.131.249.58:11800", "-Dspring.profiles.active=prod", "-Xms1024m", "-Xmx1024m", "-jar", "/app.jar" ]