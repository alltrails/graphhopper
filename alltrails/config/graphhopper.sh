#!/bin/bash
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required for handling Windows cr/lf
# See StackOverflow answer http://stackoverflow.com/a/14607651

GH_HOME=$(dirname "$0")
JAVA=$JAVA_HOME/bin/java
if [ "$JAVA_HOME" = "" ]; then
 JAVA=java
fi

vers=$($JAVA -version 2>&1 | grep "version" | awk '{print $3}' | tr -d \")
bit64=$($JAVA -version 2>&1 | grep "64-Bit")
if [ "$bit64" != "" ]; then
  vers="$vers (64bit)"
fi
echo "## using java $vers from $JAVA_HOME"

function printBashUsage {
  echo "$(basename $0): Start a Gpahhopper server."
  echo "Default user access at 0.0.0.0:8989 and API access at 0.0.0.0:8989/route"
  echo ""
  echo "Usage"
  echo "$(basename $0) [<parameter> ...] "
  echo ""
  echo "parameters:"
  echo "-i | --input <osm-file>   OSM local input file location"
  echo "--csv <csv-file>           AT CSV local input file location"
  echo "--url <url>               download input file from a url and save as data.pbf"
  echo "--import                  only create the graph cache, to be used later for faster starts"
  echo "-c | --config <config>    application configuration file location"
  echo "-o | --graph-cache <dir>  directory for graph cache output"
  echo "-p | --profiles <string>  comma separated list of vehicle profiles"
  echo "--port <port>             port for web server [default: 8989]"
  echo "--host <host>             host address of the web server [default: 0.0.0.0]"
  echo "-h | --help               display this message"
}

# one character parameters have one minus character'-'. longer parameters have two minus characters '--'
while [ ! -z $1 ]; do
  case $1 in
    --import) ACTION=import; shift 1;;
    -c|--config) CONFIG="$2"; shift 2;;
    -i|--input) FILE="$2"; shift 2;;
    --csv) IMPORT_CSV_OPTS="-Ddw.graphhopper.alltrails.attributes.file=$2"; shift 2;;
    --url) URL="$2"; shift 2;;
    -o|--graph-cache) GRAPH="$2"; shift 2;;
    -p|--profiles) GH_WEB_OPTS="$GH_WEB_OPTS -Ddw.graphhopper.graph.flag_encoders=$2"; shift 2;;
    --port) GH_WEB_OPTS="$GH_WEB_OPTS -Ddw.server.application_connectors[0].port=$2"; shift 2;;
    --host) GH_WEB_OPTS="$GH_WEB_OPTS -Ddw.server.application_connectors[0].bind_host=$2"; shift 2;;
    -h|--help) printBashUsage
        exit 0;;
    -*) echo "Option unknown: $1"
        echo
        printBashUsage
        exit 2;;
  esac
done

# Defaults
: "${ACTION:=server}"
: "${GRAPH:=/graphhopper/data/$DATA_VERSION}"
: "${CONFIG:=config-alltrails.yml}"
: "${JAVA_OPTS:=-Xmx1g -Xms1g}"
: "${JAR:=$(find . -type f -name "*.jar")}"

if [ "$URL" != "" ]; then
  wget -S -nv -O "${FILE:=data.pbf}" "$URL"
fi

# create the directories if needed
mkdir -p $(dirname "${GRAPH}")

echo "## Executing $ACTION. JAVA_OPTS=$JAVA_OPTS"

exec "$JAVA" $JAVA_OPTS ${FILE:+-Ddw.graphhopper.datareader.file="$FILE"} -Ddw.graphhopper.graph.location="$GRAPH" \
        $GH_WEB_OPTS $IMPORT_CSV_OPTS -jar "$JAR" $ACTION $CONFIG
