# Build up a search query and execute with .go
#
# The default is AND.  .node is the only exception.  .node adds to a
# list of nodes.  .go searches for (QUERY) OR (NODES)
class Noodle::Search
  attr_accessor :query, :search_terms

  def initialize(repository)
    @repository        = repository
    @query             = []
    # TODO: unused
    @search_terms      = []
    @node_names        = []
    @only_these_fields = []
    @aggs              = {}
    @override_size     = nil
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

  def does_not_exist(term)
    @query << "(NOT _exists_:params.#{term} AND NOT _exists_:facts.#{term})"
    self
  end

  def match_names(names)
    [names].flatten.map{|name| @node_names << "(name:#{name} OR name:#{name}.*)"}
    self
  end

  def match_names_exact(names)
    [names].flatten.map{|name| @node_names << "(name.keyword:\"#{name}\")"}
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

  def unique_values(term:, where: 'params')
    @query = {size: 0}
    @query[:aggs] = {}
    @query[:aggs][term] = {terms: {field: "#{where}.#{term}.keyword"}}
    return @repository.search(@query).response.aggregations.send(term).buckets.collect{|x| x['key']}.uniq
  end

  # Return unique list of values for param named TERM. If facts_too, look at both facts and params
  def param_values(term:, facts: false)
    results =           unique_values(term: term)
    results = results + unique_values(term: term, where: 'facts') if facts
    return results.compact.uniq
  end

  # Return true if any results found, false if none.
  # (Set size=0 so nodes are not returned which hopefully saves some processing)
  def any?
    return(self.go(size: 0).total > 0)
  end

  # TODO: This assumes that it's always a fact being summed.
  def sum(fact)
    # TODO: This is clunky
    @override_size = 0
    @aggs[fact] = {sum: {field: "facts.#{fact}"} }
  end

  # This, combined with the _source bit in the 'go' method below limit
  # the fields returned by Elasticsearch to just the ones we
  # need. This should help with performance.
  def limit_fetch(fields)
    fields.each do |field|
      @only_these_fields << "params.#{field}"
      @only_these_fields << "facts.#{field}"
    end
  end

  # Execute the search.  If minimum is specified, must find
  # at least that many (TODO: error if more than one found?)
  def go(minimum: false, name_and_params_only: false, names_only: false, size: 10000)
    size = @override_size unless @override_size.nil?

    # Query starts empty or based on @query
    q = @query.empty? ? '' : "(#{query.join(' ')})"

    # If both @query and @node_names are non-empty, AND
    q += " AND " unless @query.empty? or @node_names.empty?

    # If @node_names isn't empty, use it
    q += "(#{@node_names.join(' OR ')})" unless @node_names.empty?

    # Finish contructing ES query
    # TODO: Allow option to limit size
    query = {size: size, query: {query_string: { default_operator: 'AND', query: q }}}
    query[:query][:query_string][:minimum_should_match] = minimum unless minimum == false
    if name_and_params_only
      query[:_source] = ['name', 'params']
    elsif names_only
      query[:_source] = ['name']
    else
      query[:_source] = ['name'] + @only_these_fields unless @only_these_fields.empty?
    end
    query[:aggs] = @aggs unless @aggs.empty?

    # TODO: Add debug that shows query
    # puts "The query is:\n#{query}\n"

    # Execute search, return results
    results = @repository.search(query)

    # TODO:
    #puts "Results: #{results}"

    # TODO: Add debug that shows results
    return results.first if size == 1 # TODO: Hmm, this seems fishy/ugly
    return results
  end
end

