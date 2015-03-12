# TODO

* Add test for this:
site= jojo

* Add [.] to node-finding query so that, for example, searching for 'jojo' only matches 'jojo.example.com' and not 'jojomomo.example.com'
* Fix curl examples in README

* bin/noodlin tests

* bin/noodle tests

* Add test which proves Noodle.Search.go :justone DTRT when there's
more than one match

* Finish testing noodlin

* Make Noodle::Search idiom/sugar for finding a single node by name

* docs

* 'noodlin help' and 'noodle _ help'

* Make uniqueness validators for :name in Node and Option.

* Allow magic queries to specify which options set to use.  The default options should work
for everybody,  But everybody can make their own set.  And use a set created by somebody else.

* grep -r TODO and DO

* Make sure everything is either a symbol or a string.  No mixing allowed.

* fix intermittently failing tests.  There is a race condition somewhere.
Plus I am not being careful enough with ES.  Should at least use this to check whether
the index exists after (re-)creating it:
http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-exists.html

* tests for noodle scripts

* Put text/plain output in column -t format

* Pretty JSON format a la Elasticsearch

* Set content type and return JSON by default.  Support
returning "pretty" output as text/plain and make it match
what existing Noodle returns

# Maybe
* Put API under /api/v1, but have a convenience /_/ alias for
searching

