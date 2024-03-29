#!/bin/sh

PW="$1"
HOST="$2"
if [ -z "$1" -o -z "$2" ]
then
  echo "Usage: $0 PASSWORD HOSTNAME"
  exit 1
fi

ca_file='config/elastic-stack-cacert.pem'
if [ -f $ca_file ]
then
  tls_opt="--cacert ${ca_file}"
else
  tls_opt='-k'
fi

curl -v -s $tls_opt -u "elastic:${PW}" -X POST "https://${HOST}:9200/_security/role/noodle_role?pretty" -H 'Content-Type: application/json' -d'
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": [ "noodle-*" ],
      "privileges": ["all"]
    }
  ],
  "applications": [
    {
      "application": "noodle",
      "privileges": [ "admin", "read" ],
      "resources": [ "*" ]
    }
  ]
}
'
