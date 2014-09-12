class Noodle::Search
    attr_accessor :query, :search_terms

    def initialize(theclass)
        @theclass = theclass
        @query = []
        @search_terms = []
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

    def match_name(name)
        @query << "name:#{name}*"
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

    def go
        q = query.join(' ')
        @theclass.search(query: {query_string: { default_operator: 'AND', query: q }})
    end
end

