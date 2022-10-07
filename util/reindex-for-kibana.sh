#!/bin/bash

# If your noodle-nodes index has too many fields for Kibana, here's a workaround

# Do this once:
#
# Create a plain index
curl -X PUT "localhost:9200/noodle-kibana?pretty" -H 'Content-Type: application/json' -d'
{
  "settings" : {
    "number_of_shards" : 1,
    "analysis" : {
      "analyzer" : {
        "default" : {
          "tokenizer" : "my_pattern_tokenizer"
        }
      },
      "tokenizer" : {
        "my_pattern_tokenizer" : {
          "type" : "pattern"
        }
      }
    }
  },
  "mappings" : {
    "properties" : {
      "name" : {
        "type" : "text",
        "fields" : {
          "raw" : {
            "type" : "keyword"
          }
        }
      }
    }
  }
}
'
#
# Do this once too:
#
# Make this number as small as we can
curl -XPUT 'http://localhost:9200/noodle-kibana/_settings?pretty' -H 'Content-Type: application/json' -d'
{
  "index.mapping.total_fields.limit": 1000
}'

##
# Periodically run the next two commands to update noodle-kibana from the source.
#
# First, remove any old nodes in the kibana index. TODO: Better way to avoid stragglers?
curl -X POST "http://localhost:9200/noodle-kibana/_delete_by_query?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
      "match_all" : {}
  }
}
'
#
# Next, reindex from noodle-nodes into noodle-kibana, skipping certain fields
time curl -X POST "localhost:9200/_reindex?pretty&timeout=1d&scroll=1h" -H 'Content-Type: application/json' -d'
  {
    "source": {
      "index": "noodle-nodes",
      "_source": [
        "name",
        "params",
        "facts.agent_specified_environment",
        "facts.aio_agent_version",
        "facts.apache_version",
        "facts.architecture",
        "facts.avamardomain",
        "facts.bashversion",
        "facts.bknet",
        "facts.chocolateyversion",
        "facts.clientversion",
        "facts.cobol_version",
        "facts.cpu_hotadd",
        "facts.create_date",
        "facts.datastore_cluster",
        "facts.domain",
        "facts.facterversion",
        "facts.grub_version",
        "facts.id",
        "facts.is_chroot",
        "facts.is_pe",
        "facts.is_virtual",
        "facts.java_major_version",
        "facts.java_patch_level",
        "facts.java_version",
        "facts.javas_installed",
        "facts.javas_running",
        "facts.kernelmajversion",
        "facts.kernelrelease",
        "facts.kernelversion",
        "facts.last_boot",
        "facts.last_run",
        "facts.mysql_server_id",
        "facts.mysql_version",
        "facts.openssl_version",
        "facts.phpversion",
        "facts.physicalmemorysize",
        "facts.physicalprocessorcount",
        "facts.powerstate",
        "facts.python2_version",
        "facts.python3_version",
        "facts.python_version",
        "facts.ram_gigs",
        "facts.redhat_install_date",
        "facts.rubyversion",
        "facts.runlevel",
        "facts.selinux",
        "facts.storage_gigs",
        "facts.sudoversion",
        "facts.swapfree",
        "facts.swapfree_mb",
        "facts.swapsize",
        "facts.swapsize_mb",
        "facts.system_rubyversion",
        "facts.systemd_version",
        "facts.total_gigs",
        "facts.uptime",
        "facts.uptime_days",
        "facts.uptime_hours",
        "facts.uptime_seconds",
        "facts.usgos",
        "facts.usgosver",
        "facts.uuid",
        "facts.vcenter",
        "facts.virtual",
        "facts.vsphere-uid",
        "facts.yumupdates"
      ]
    },
    "dest": {
      "index": "noodle-kibana"
    }
  }
' 2>&1 | tee reindex.out

# Check how many fields you ended up with:
curl -s -XGET localhost:9200/noodle-kibana/_mapping?pretty | grep -c '"type"'
