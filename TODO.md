# TODO

* grep -r TODO and DO

* Make sure everything is either a symbol or a string.  No mixing allowed.

* fix intermittently failing tests.  There is a race condition somewhere.
Plus I am not being careful enough with ES.  Should at least use this to check whether
the index exists after (re-)creating it:
http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-exists.html

* finish lib/option.rb

* Make uniqueness validators for :name in Node and Option.

* Allow magic queries to specify which options set to use.  The default options should work
for everybody,  But everybody can make their own set.  And use a set created by somebody else.

* magic ilk= and status= based on options

* tests for noodle scripts

* noodlin script

* Put text/plain output in column -t format

* Pretty JSON format a la Elasticsearch

* Move from /nodes index to /noodle/nodes.  So we can have noodle/options, etc.

* Options stored in ES noodle/options

* Only show status=enabled by default (actually, make an option
for the list of statuses shown by defaul)

* Set content type and return JSON by default.  Support
returning "pretty" output as text/plain and make it match
what existing Noodle returns

# Maybe
* Put it all under /api/v1?  Or just /v1/?  But have a convenience /_/ alias
for searching.

* make it one giant hashie to avoid quirks like if :ilk, etc?  plus one giant hashie makes it easier to extend?

