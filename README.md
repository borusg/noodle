[![Build Status](https://travis-ci.org/happymcplaksin/noodle.svg?branch=master)](https://travis-ci.org/happymcplaksin/noodle) [![Coverage Status](https://img.shields.io/coveralls/happymcplaksin/noodle.svg)](https://coveralls.io/r/happymcplaksin/noodle)

# noodle
Clean-room implementation of the [Puppet External Node Classifier](http://docs.puppetlabs.com/guides/external_nodes.html)
and server database that we [use at work](http://bit.ly/noodlerockeagle2013).

## Future dreamland
* Magicaly templated Heira backend
* Relationships, including enough to define network config for an entire stack (from IPs to firewall and load balancer, etc)

## Requirements
* [Elasticsearch](http://www.elasticsearch.org/overview/elkdownloads/)  It's easy to install, too powerful to ignore.  Plus you get an [awesome UI named Kibana](http://www.elasticsearch.org/overview/kibana/) for free.
* Ruby.  travis-ci.org says it works with versions 1.9, 2.0, 2.1 and 2.2.

## Running it
* Remember to install and start [Elasticsearch](http://www.elasticsearch.org/overview/elkdownloads/)
* `git clone https://github.com/happymcplaksin/noodle.git`
* `cd noodle`
* `bundle install --path vendor/bundle`
* Run tests: `bundle exec rake`
* Start app: `bundle exec rackup`

Perhaps the [travis-ci.org steps](https://travis-ci.org/happymcplaksin/noodle) are helpful and/or a decent alternative :)

## Examples
```bash

# Create via noodlin
bin/noodlin create -s mars -i host -p hr -P prod jojo.example.com
# <NO OUTPUT means success>

# Search via Noodle 'magic'
bin/noodle jojo.example.com
# ---
# classes:
# - baseclass
# parameters:
#   ilk: host
#   project: hr
#   prodlevel: prod
#   site: mars
#   status: enabled

# More 'magic':
bin/noodle site=mars
# jojo.example.com

# More 'magic':
bin/noodle site=mars prodlevel=
# jojo.example.com prodlevel=prod

# More 'magic':
bin/noodle site?
# jojo.example.com

# More 'magic':
bin/noodle site?=
# jojo.example.com site=mars

# More 'magic':
bin/noodle full
# Name:   jojo.example.com
# Params: 
#   ilk=host
#   project=hr
#   prodlevel=prod
#   site=mars
#   status=enabled
# Facts:
#   fqdn=jojo.example.com

# More 'magic':
bin/noodle project=hr
# jojo.example.com

# More 'magic':
bin/noodle @project=hr  # @ because ! is too hard in the shell :)
# <NO OUTPUT>

# More 'magic':
bin/noodle site=mars prodlevel= site= ilk=
# jojo.example.com prodlevel=prod site=mars ilk=host

# Create another one:
bin/noodlin create -s mars -i host -p hr -P prod momo.example.com
# <NO OUTPUT means success>

# Find both by project:
bin/noodle project=hr
# jojo.example.com
# momo.example.com

# NOTE: All example below here are broken now that certain params are required.
# Will fix example RSN.

# Search via curl
curl -s -XGET http://localhost:9292/nodes/jojo.example.com
# (returns nothing)

# Create via curl
curl -s -XPOST http://localhost:9292/nodes/jojo.example.com -d @util/node.json
# Name:   jojo.example.com
# Ilk:    host
# Status: surplus
# Params:
#   site = moon
# Facts:

# Or create via PUT
curl -s -XPUT http://localhost:9292/nodes/jojo.example.com -d @util/node.json
# Name:   jojo.example.com
# Ilk:    host
# Status: surplus
# Params:
#   site = moon
# Facts:

# Search again
curl -s -XGET http://localhost:9292/nodes/jojo.example.com
# Name:   jojo.example.com
# Ilk:    host
# Status: surplus
# Params:
#   site = moon
# Facts:

# Patch
curl -s -XPATCH http://localhost:9292/nodes/jojo.example.com -d @util/patch.json
# Name:   jojo.example.com
# Ilk:    host
# Status: surplus
# Params:
#   site = mars  <--- changed
# Facts:

# Delete
curl -s -XDELETE http://localhost:9292/nodes/jojo.example.com
# Deleted jojo.example.com

# Pry me a river
curl -s -XPUT http://localhost:9292/nodes/jojo.example.com -d @util/realnode-1.json
curl -s -XPUT http://localhost:9292/nodes/jojo.example.com -d @util/realnode-2.json
./prymeariver
# And try some of the examples it spits out

# Magic search #1
curl -q -XGET 'http://localhost:9292/nodes/_/site=moon'
# cheese1.example.com
# jojo.example.com

# Magic search #2
curl -q -XGET 'http://localhost:9292/nodes/_/operatingsystem=ackack'
# greenie.example.com

```

## Create sample nodes
```bash
# Create pre-generated random nodes:
util/create-sample-nodes.sh

# Create your own random nodes
util/makepasta.rb > /tmp/makepasta.out
. /tmp/makepasta.out
```

# Running Noodle on OpenShift
Exercise left to reader: I assume you can hook up a Ruby Application at [OpenShift](https://www.openshift.com/) to a Noodle repository :)  I picked OpenShift because it's free and doesn't require a credit card.

Until I grok it, manually change the rack version in Gemfile.lock to 1.5.2.

```bash

# Install Elasticsearch in OpenShift OS

# SSH to your OpenShfit OS then:
cd app-root/data
# Any version should do
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.5.0.tar.gz
tar xf elasticsearch-1.5.0.tar.gz
cd elasticsearch-1.5.0

# Either copy util/elasticsearch.yml to the config dir OR:

vi config/elasticsearch.yml
# And set the following:
# network.host: ${OPENSHIFT_RUBY_IP}
# transport.tcp.port: 29300
# http.port: 29200

# Start ES
bin/elasticsearch

# On your desktop or some other remote OS:
export NOODLE_SERVER=YOUROPENSHIFTNAME.rhcloud.com

# Then noodlin and noodle away

```

## Thanks and references and notes to self
* [elasticsearch-persistence](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-persistence)
* [elasticsearch-persistence model definition](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-persistence#model-definition)
* [Sinatra](https://github.com/sinatra/sinatra)
* [Heroku HTTP+JSON API design](https://github.com/interagent/http-api-design)
* [REST](http://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_web_services)
* [RESTful CookBook](http://restcookbook.com/)

