# Build up a Node.search query and execute with .go
#
# The default is AND.  .node is the only exception.  .node adds to a
# list of nodes.  .go searches for (QUERY) OR (NODES)
class Noodle::Search
    attr_accessor :query, :search_terms

    def initialize(theclass)
        @theclass     = theclass
        @query        = []
        # TODO: unused
        @search_terms = []
        @node_names   = []
        self
    end

    def equals(term,value)
        @search_terms << term
        @query << "(params.#{term}:#{value} OR facts.#{term}:#{value})"
        self
    end

    def match(term,value)
        @search_terms << term
        @query << "(params.#{term}:*#{value}* OR facts.#{term}:*#{value}*)"
        self
    end

    def exists(term)
        @query << "(_exists_:params.#{term} OR _exists_:facts.#{term})"
        self
    end

    def match_names(names)
        [names].flatten.map{|name| @node_names << "name:#{name}*"}
        self
    end

    def not_equal(term,value)
        @search_terms << term
        @query << "-(params.#{term}:#{value} AND -facts.#{term}:#{value})"
        self
    end

    def all
        @query << '*'
        self
    end

    # Execute the search.  If minimum is specified, must find
    # at least that many (TODO: error if more than one found?)
    def go(options = {minimum: false, justone: false})
        # Query starts empty or based on @query
        q = @query.empty? ? '' : "(#{query.join(' ')})"

        # If both @query and @node_names are non-empty, AND
        q += " AND " unless @query.empty? or @node_names.empty?

        # If @node_names isn't empty, use it
        q += "(#{@node_names.join(' OR ')})" unless @node_names.empty?

        # Finish contructing ES query
        query = {query: {query_string: { default_operator: 'AND', query: q }}}
        query[:query][:query_string][:minimum_should_match] = options[:minimum] if options[:minimum]
        # TODO: Add debug puts query

        # Execute search, return results
        results = @theclass.search(query)
        # TODO: Add debug puts results

        return results.first if options[:justone]
        return results
    end
end

