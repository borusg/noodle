# noodle
Clean-room implementation of the [Puppet External Node Classifier](http://docs.puppetlabs.com/guides/external_nodes.html)
and server database that we [use at work](bit.ly/noodlerockeagle2013).

## Future dreamland
* Duplicate existing functionality
* Magicaly templated Heira backend
* Relationships, including enough to define network config for an entire stack (from IPs to firewall and load balancer, etc)

## Examples
```bash
# Search
curl -s -XGET http://localhost:9292/nodes/jojo.example.com
# (returns nothing)

# Create
curl -s -XPOST http://localhost:9292/nodes/jojo.example.com -d @node.json
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

```

