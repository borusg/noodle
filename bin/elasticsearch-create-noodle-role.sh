#!/bin/sh

ca_file='config/elastic-stack-cacert.pem'
if [ -f $ca_file ]
then
  tls_opt="--cacert ${ca_file}"
else
  tls_opt='-k'
fi

curl -s $tls_opt -u "elastic:${ELASTICSEARCH_PASSWORD}" -X POST "https://es01:9200/_security/role/noodle_role?pretty" -H 'Content-Type: application/json' -d'
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
