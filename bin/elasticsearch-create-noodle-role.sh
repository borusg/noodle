#!/bin/sh

curl -s --cacert config/elastic-stack-cacert.pem -u "elastic:${ELASTICSEARCH_PASSWORD}" -X POST "https://localhost:9200/_security/role/noodle_role?pretty" -H 'Content-Type: application/json' -d'
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
