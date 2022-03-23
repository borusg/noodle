#!/bin/sh

if [ -z "$1" -o -z "$2" -o -z "$3" ]
then
  echo "Usage: $0 ES_PASSWORD NOODLE_PASSWORD HOSTNAME"
  exit 1
fi

ES_PW="$1"
NOODLE_PW="$2"
HOST="$3"

ca_file='config/elastic-stack-cacert.pem'
if [ -f $ca_file ]
then
  tls_opt="--cacert ${ca_file}"
else
  tls_opt='-k'
fi

curl -v -s $tls_opt -u "elastic:${ES_PW}" -X POST "https://${HOST}:9200/_security/user/noodle_user?pretty" -H 'Content-Type: application/json' -d'
{
    "password" : "'${NOODLE_PW}'",
    "roles" : [ "noodle_role" ]
}'
