FROM maven:3.9.5-eclipse-temurin-21 as build

WORKDIR /graphhopper

COPY . .

RUN mvn clean install -DskipTests

FROM alpine/curl@sha256:df202600793f003a0a8dda18287d868802984a976f103cf59165d5aafa4e0007 AS fetch-dd

WORKDIR /dd

RUN curl -Lo dd-java-agent.jar 'https://dtdg.co/java-tracer-v1'

FROM eclipse-temurin:21.0.1_12-jre

WORKDIR /graphhopper

RUN mkdir -p ./alltrails/config

COPY --from=build /graphhopper/web/target/graphhopper*.jar ./

COPY alltrails/config/graphhopper.sh ./

COPY alltrails/config/config-alltrails.yml alltrails/config/atv.json ./alltrails/config

COPY --from=fetch-dd /dd/dd-java-agent.jar /usr/lib/dd-java-agent.jar

EXPOSE 8989 8990

HEALTHCHECK --interval=5s --timeout=3s CMD curl --fail http://localhost:8989/health || exit 1

ARG JAVA_OPTS="-Xmx161g -Xms161g -javaagent:/usr/lib/dd-java-agent.jar"
ENV JAVA_OPTS=${JAVA_OPTS}

# Usually Overwritten when building the image.
# See the dataversion file.
ARG DATA_VERSION=default-gh
ENV DATA_VERSION=${DATA_VERSION}

ENTRYPOINT [ "./graphhopper.sh", "-c", "alltrails/config/config-alltrails.yml" ]
