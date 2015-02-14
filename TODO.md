# TODO

* yak shave:
-- Ahem. Use Noodle::Search instead of Node.find?  Or make Node.find use Noodle::Search

* Finish noodlin

* noodlin script

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
* Put it all under /api/v1?  Or just /v1/?  But have a convenience /_/ alias
for searching.

