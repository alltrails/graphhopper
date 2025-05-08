FROM maven:3.9.5-eclipse-temurin-21 as build

WORKDIR /graphhopper

COPY . .

RUN mvn clean install -DskipTests


FROM eclipse-temurin:21.0.1_12-jre

WORKDIR /graphhopper

RUN mkdir -p ./alltrails/config

COPY --from=build /graphhopper/web/target/graphhopper*.jar ./

COPY alltrails/config/graphhopper.sh ./

COPY alltrails/config/config-alltrails.yml alltrails/config/atv.json ./alltrails/config

EXPOSE 8989 8990

HEALTHCHECK --interval=5s --timeout=3s CMD curl --fail http://localhost:8989/health || exit 1

ARG JAVA_OPTS="-Xmx416g -Xms416g"
ENV JAVA_OPTS=${JAVA_OPTS}

ARG IMPORT_FILE="/graphhopper/data/planet-latest.osm.pbf"
ENV IMPORT_FILE=${IMPORT_FILE}

ARG S3_DIR="/graphhopper/data/import-data/"
ENV S3_DIR=${S3_DIR}

ENTRYPOINT ./graphhopper.sh -c alltrails/config/config-alltrails.yml -o /alltrails/data/import-data --import -i "${IMPORT_FILE}"
