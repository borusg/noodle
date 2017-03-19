# TODO
doc noodlin hash. Samples:

    # noodlin param gum.firstname=mark
    # noodlin param gum.lastname=plaksin
    # noodlin param gum.address.street='110 orchard knob ln'
    # noodlin param gum.address.city='athens'
    # noodlin param gum.address.state='ga'
    # noodlin param gum.address.zipcode='30605'

Um, better hash sample in options. (gum?!)

* Add /magic/ as an alias for /_/

* Fix curl examples in README

* Rubocop

------------------------------------------------------------------------------
* Think about ES mappings and DTRT.
** Handle node (etc) names containing dashes and other separators that the ES indexer keys off of.

* noo-alike

* content-type

* noodle display arguments to support:
- values only
- csv
- sort
- column -t

* Make Noodle::Search idiom/sugar for finding a single node by name

* fail more gracefully when ES isn't running

* 'noodlin help' and 'noodle _ help'

* Add versioning

* Make uniqueness validators for :name in Node and Option.

* Put text/plain output in column -t format

* Pretty JSON format a la Elasticsearch

* Set content type and return JSON by default.  Support returning "pretty" output as text/plain and make it match what existing Noodle returns

* Looks like ES limits simple search to 10000

# Perf notes
1. On a random machine It takes about 3 minutes to make 1000 nodes each with a basic set of facts. Slow!
2. On the same random machine it takes about 10 seconds to dump 2000
   nodes to json (noodle fqdn=~. json). Somewhat faster than
   "dirty-room" Noodle which takes close to a minute to dump 1500
   nodes to json.
3. And about 50 seconds to dump 10000 nodes to json.
4. No doubt it can be faster!

# Maybe
* Put API under /api/v1, but have a convenience /_/ alias for searching

