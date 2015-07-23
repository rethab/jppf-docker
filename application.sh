#!/bin/bash

# FROM  https://github.com/mxmo0rhuhn/bachelor_thesis/blob/master/images/thesisValidator/application.sh

COMPUTATION_ID=$2
LOG_PATH=/var/log/application
# default logfile
LOG_FILE=$LOG_PATH/error.log
EXIT_STATUS=0

shutdown(){
    echo  "Shutting down due to SIGTERM" >> $LOG_FILE
    # Sleep to emulate shutdown process
    sleep 7 
    echo  "Shutdown finished - Goodbye" >> $LOG_FILE
    exit 0
}
   
trap 'shutdown' SIGTERM
mkdir -p $LOG_PATH

case "$1" in
  master)
    PARAMETER=$3

    LOG_FILE_LOG4J=$LOG_PATH/$HOSTNAME"_jppf-driver-log4.log"
    LOG_FILE_STDOUT=$LOG_PATH/$HOSTNAME"_jppf-driver-stdout.log"

    cd master

    # set log path
    sed -i "/log4j.appender.JPPF.File/c\log4j.appender.JPPF.File=${LOG_FILE_LOG4J}" config/log4j-driver.properties
    # run on port 5000
    sed -i "/jppf.server.port/c\jppf.server.port=5000" config/jppf-driver.properties
    # jmx on port 5001
    sed -i "/#jppf.management.port/c\jppf.management.port=5001" config/jppf-driver.properties

    # disable ssl
    sed -i "/jppf.ssl.server.port/c\jppf.ssl.server.port=-1" config/jppf-driver.properties

    printf "Calling master with:\n"                     >> $LOG_FILE_STDOUT
    printf "\tComputation ID: %s\n" $COMPUTATION_ID     >> $LOG_FILE_STDOUT
    printf "\tParameters: %s\n" $PARAMETER              >> $LOG_FILE_STDOUT
    printf "\tLogfile (stdout): %s\n" $LOG_FILE_STDOUT  >> $LOG_FILE_STDOUT
    printf "\tLogfile (log4): %s\n" $LOG_FILE_LOG4J     >> $LOG_FILE_STDOUT
    printf "\n"

    ./startDriver.sh $PARAMETER >> $LOG_FILE_STDOUT  2>&1
    wait $!
    EXIT_STATUS=$(echo $?)
    ;;
  client)
    SERVER_IP=$3
    SERVER_PORTS=$4
    PARAMETER=$5

    LOG_FILE_STDOUT=$LOG_PATH/$HOSTNAME"_jppf-node-stdout.log"
    LOG_FILE_LOG4J=$LOG_PATH/$HOSTNAME"_jppf-node-log4j.log"

    printf "Calling client with:\n"                             >> $LOG_FILE_STDOUT
    printf "\tComputation ID: %s\n" $COMPUTATION_ID             >> $LOG_FILE_STDOUT
    printf "\tServer IP: %s\n" $SERVER_IP                       >> $LOG_FILE_STDOUT
    i=1
    echo $SERVER_PORTS | tr , "\n" | while read line ;do 
        printf "\tPort %d: %d\n" $i $line                       >> $LOG_FILE_STDOUT
        i=$[$i+1]
    done
    SERVER_PORT_1=${SERVER_PORTS%,*}
    printf "\tServer Port (first): %s\n" $SERVER_PORT_1         >> $LOG_FILE_STDOUT
    printf "\tParameters: %s\n" $PARAMETER                      >> $LOG_FILE_STDOUT
    printf "\tLogfile (stdout): %s\n" $LOG_FILE_STDOUT          >> $LOG_FILE_STDOUT
    printf "\tLogfile (log4j): %s\n" $LOG_FILE_LOG4J            >> $LOG_FILE_STDOUT
    printf "\n"

    cd node

    # set log path
    sed -i "/log4j.appender.JPPF.File/c\log4j.appender.JPPF.File=${LOG_FILE_LOG4J}" config/log4j-node.properties

    # set master ip + port
    sed -i "/#jppf.server.host/c\jppf.server.host=${SERVER_IP}" config/jppf-node.properties
    sed -i "/#jppf.server.port/c\jppf.server.port=${SERVER_PORT_1}" config/jppf-node.properties

    ./startNode.sh >> $LOG_FILE_STDOUT 2>&1

    wait $!
    EXIT_STATUS=$(echo $?)
    ;;
  *)
    echo "specified task unknown - exiting" >> $LOG_FILE
    EXIT_STATUS=1
    ;;
esac

echo  "Ended $EXIT_STATUS - Goodbye" >> $LOG_FILE
exit $EXIT_STATUS
