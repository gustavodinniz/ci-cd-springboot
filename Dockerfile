FROM amazoncorretto:17-alpine-jdk

RUN apk add --no-cache curl

ARG MAVEN_VERSION=3.8.3

ARG MAVEN_HOME_DIR=usr/share/maven

ARG APP_DIR="app"

ARG BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /$MAVEN_HOME_DIR /$MAVEN_HOME_DIR/ref \
  && echo "[ECHO] Downloading maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  \
  && echo "[ECHO] Unzipping maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C /$MAVEN_HOME_DIR --strip-components=1 \
  \
  && echo "[ECHO] Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /$MAVEN_HOME_DIR/bin/mvn /usr/bin/mvn

ENV MAVEN_CONFIG "/${APP_DIR}/.m2"

ENV APP_NAME ms-data

COPY ./src ./$APP_DIR/src
COPY pom.xml ./$APP_DIR

WORKDIR /$APP_DIR

RUN mvn clean package

RUN mv target/$APP_NAME.jar .

RUN echo "[ECHO] Removing source code" \
    && rm -rf /$APP_DIR/src \
    \
    && echo "[ECHO] Removing pom.xml"  \
    && rm -f /$APP_DIR/pom.xml \
    \
     && echo "[ECHO] Removing output of the build"  \
    && rm -rf /$APP_DIR/target \
    \
    && echo "[ECHO] Removing local maven repository ${MAVEN_CONFIG}"  \
    && rm -rf $MAVEN_CONFIG \
    \
    && echo "[ECHO] Removing maven binaries"  \
    && rm -rf /$MAVEN_HOME_DIR \
    \
    && echo "[ECHO] Removing curl binaries"  \
    && apk del --no-cache curl

VOLUME $APP_DIR/tmp
EXPOSE 8080

ENTRYPOINT exec java -jar $APP_NAME.jar -Djava.security.egd=file:/dev/./urandom $JAVA_OPTS