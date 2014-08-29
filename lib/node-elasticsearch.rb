require 'elasticsearch/persistence/model'
require 'hashie'

class Node
    include Elasticsearch::Persistence::Model

    attribute :name,   String
    attribute :fqdn,   String, default: :name
    # TODO: limit these two to a list of defaults
    attribute :ilk,    String
    attribute :status, String
    attribute :facts,  Hashie::Mash, mapping: { type: 'object' }, default: {}
    attribute :params, Hashie::Mash, mapping: { type: 'object' }, default: {}

    # Magic:
    #
    # Make everything return either JSON or pretty text, defaul based on
    # either user-agent or accepts or both or more :)
    #
    # Duplicate existing:
    #
    # All parts of the query are ANDed
    #
    # hostname (partial or full)
    # x?=
    # x=
    # x=~y
    # x=y
    #
    # @x=y
    # x?
    # full
    # json
    # jmm :)  Maybe by some extensible plugin thing?
    #
    # New ideas:
    # - A way to say OR or switch the whole query to be ORed instead of ANDed
    # - Make precedence explicit:
    #   - if both fact and param, param wins.
    #   - And bare words are highest (or tunable?)
    # - Make order explicit?  Needed?
    # - ~x=y  That is, regexp on the fact/param name
    # - barewords=paramname1[,paramname2,factname1,...] (needs better name)
    #   Allow a list of fact/param names the values of which can be used 
    #   as bare words in queries.
    #
    #   For example, if 'prodlevel' were in the list then 'prod'
    #   could be used in a search to mean prodlevel=prod
    def self.magic(query)
        search = Node::Search.new

        # NOTE: Order below should be preserved in case statement
        term_present_and_show_value = Regexp.new '\?=$'
        term_show_value             = Regexp.new '=$'
        term_matches_regexp         = Regexp.new '=~'
        term_equals                 = Regexp.new '='
        query.split(/\s+/).each do |part|
            case part
                when term_present_and_show_value
                when term_show_value
                when term_matches_regexp
                when term_equals
                     # TODO: Limit split to 2
                     term,value = part.split(/=/)
                     search.equals(term,value)
                else
                     puts "TODO: Handle unknown magic parts gracefully"
            end
        end
        r = search.go
        # TODO: This is ugly
        [r.response.hits.hits.collect{|hit| hit._source.name}, 200]
    end
end

# TODO: each method should add to the query.
class Node::Search
    attr_accessor :query

    def initialize
        @query = []
    end

    def equals(term,value)
        @query << "(params.#{term}:#{value} OR facts.#{term}:#{value})"
    end

    def go
        # TODO: Maybe change default operator to AND
        q = @query.join(' AND ')
        Node.search(query: {query_string: { query: q }})
    end
end
