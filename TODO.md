# TODO
add noodlin hash via json

add noodlin hash tests

* Order:
- ilk/status should be params everywhere
- finish /options/
- docs

* API: Everything should support bulk operations (GET,POST,PUT,PATCH,DELETE)

* Add /magic/ as an alias for /_/

* Oops!  This should give an error: noodlin param jojo=poop # no hostnames supplied

* Add tests:
** Add test which proves Noodle.Search.go :justone DTRT when there's more than one match

* Fix curl examples in README

* Rubocop

* Think about ES mappings and DTRT.
** Handle node (etc) names containing dashes and other separators that the ES indexer keys off of.

* finish /options/
** Allow magic queries to specify which options set to use.  The default options should work
for everybody,  But everybody can make their own set.  And use a set created by somebody else.

* noo-alike

* does 'noodlin future blah' and similar work?

* content-type

* openshift ES cartridge:
https://hub.openshift.com/quickstarts/125-elasticsearch

* noodle display arguments to support:
- values only
- csv
- sort
- column -t

* Add [.] to node-finding query so that, for example, searching for 'jojo' only matches 'jojo.example.com' and not 'jojomomo.example.com'?

* Make Noodle::Search idiom/sugar for finding a single node by name

* fail more gracefully when ES isn't running

* docs

* 'noodlin help' and 'noodle _ help'

* Add versioning

* Make uniqueness validators for :name in Node and Option.

* grep -r TODO and DO

* Make sure everything is either a symbol or a string.  No mixing.

* Put text/plain output in column -t format

* Pretty JSON format a la Elasticsearch

* Set content type and return JSON by default.  Support returning "pretty" output as text/plain and make it match what existing Noodle returns

# Maybe
* Put API under /api/v1, but have a convenience /_/ alias for searching

