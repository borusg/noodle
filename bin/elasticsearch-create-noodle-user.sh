#!/bin/sh

curl -s --cacert config/elastic-stack-cacert.pem -u "elastic:${ELASTICSEARCH_PASSWORD}" -X POST "https://localhost:9200/_security/user/noodle_user?pretty" -H 'Content-Type: application/json' -d'
{
    "password" : "'${NOODLE_PASSWORD}'",
    "roles" : [ "noodle_role" ]
}'
