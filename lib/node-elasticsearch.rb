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

    def to_puppet
        "TODO"
    end

    # Magic:
    #
    # Make everything return either JSON or pretty text, defaul based on
    # either user-agent or accepts or both or more :)
    #
    # Duplicate existing:
    #
    # All parts of the query are ANDed by default
    #
    # hostname (partial or full)
    #
    # x=y
    # x=~y
    # @x=y AKA -x=y
    # x?
    #
    # x?=
    # x=
    # full
    # json # Implies full
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
        show   = []
        format = :default

        # NOTE: Order below should be preserved in case statement
        term_present                = Regexp.new '\?$'
        term_present_and_show_value = Regexp.new '\?=$'
        term_does_not_equal         = Regexp.new '^[-@][^=]+=.+'
        term_show_value             = Regexp.new '=$'
        term_matches_regexp         = Regexp.new '=~'
        term_equals                 = Regexp.new '='
        query.split(/\s+/).each do |part|
            case part
            when term_present
                 term = part.sub(/\?$/,'')
                 search.exists(term)

            when term_present_and_show_value
                 term = part.sub(/\?$/,'')
                 search.exists(term)
                 show << term

            when term_does_not_equal
                 term,value = part.sub(/^[-@]/,'').split(/=/,2)
                 search.not_equal(term,value)

            when term_show_value
                 show << term

            when term_matches_regexp
                 term,value = part.split(/=~/,2)
                 search.match(term,value)

            when term_equals
                 term,value = part.split(/=/,2)
                 search.equals(term,value)

            when 'full'
                 format = :full

            when 'json'
                 format = :json

            else
                 puts "TODO: Handle unknown magic parts gracefully"
            end
        end

        status = 200
        found = search.go
        case format
        when :json
            body = found.results.to_json"\n"
        when :yaml
            body = found.results.map{|one| one.to_puppet}.join("\n") + "\n"
        when :full
            body = 'TODO'
        else
            body = found.response.hits.hits.collect{|hit| hit._source.name}.sort.join("\n") + "\n"
        end
        [body,status]
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

    def match(term,value)
        @query << "(params.#{term}:*#{value}* OR facts.#{term}:*#{value}*)"
    end

    def exists(term)
        @query << "(_exists_:params.#{term} OR _exists_:facts.#{term})"
    end

    def not_equal(term,value)
        @query << "-(params.#{term}:#{value} AND -facts.#{term}:#{value})"
    end

    def go
        q = query.join(' ')
        Node.search(query: {query_string: { default_operator: 'AND', query: q }})
    end
end

