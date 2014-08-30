[![Build Status](https://travis-ci.org/happymcplaksin/noodle.svg?branch=master)](https://travis-ci.org/happymcplaksin/noodle)

# noodle
Clean-room implementation of the [Puppet External Node Classifier](http://docs.puppetlabs.com/guides/external_nodes.html)
and server database that we [use at work](http://bit.ly/noodlerockeagle2013).

## Future dreamland
* Duplicate existing functionality
* Magicaly templated Heira backend
* Relationships, including enough to define network config for an entire stack (from IPs to firewall and load balancer, etc)

## Running it
Step-by-step:
* `git clone`
* `cd noodle`
* `bundle install`
* Run tests: `rake`
* Start app: `rackup`

Perhaps the [travis-ci.org steps](https://travis-ci.org/happymcplaksin/noodle) are helpful and/or a decent alternative :)

## Examples
```bash

# Search
curl -s -XGET http://localhost:9292/nodes/jojo.example.com
# (returns nothing)

# Create
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

## Thanks and references and notes to self
* [elasticsearch-persistence](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-persistence)
* [elasticsearch-persistence model definition](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-persistence#model-definition)
* [Sinatra](https://github.com/sinatra/sinatra)
* [Heroku HTTP+JSON API design](https://github.com/interagent/http-api-design)
* [REST](http://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_web_services)
* [RESTful CookBook](http://restcookbook.com/)

