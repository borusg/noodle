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

# Since noodlin is always run by a human, force the 'now' option so results are instant:
curl $DEBUG -s -X GET "${URL}?now" --data-urlencode "=$query"
status=$?

if [[ $status != 0 ]]
then
    echo "Oops!  Bad status: $status"
fi

