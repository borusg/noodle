#!/bin/bash

[[ -z $NOODLE_SERVER ]] && NOODLE_SERVER=localhost:9292
URL="http://${NOODLE_SERVER}/nodes"

query="$*"

if [[ $(basename $0) == 'noodlin' ]]
then
    URL="${URL}/noodlin/"
else
    URL="${URL}/_/"
fi

DEBUG='--trace-ascii /dev/stdout'
DEBUG=

curl $DEBUG -s -X GET $URL --data-urlencode "=$query"
status=$?

if [[ $status != 0 ]]
then
    echo "Oops!  Bad status: $status"
fi

