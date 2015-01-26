require 'elasticsearch/persistence/model'
require 'hashie'
require 'trollop'

class Noodle::Node
    include Elasticsearch::Persistence::Model

    attribute :name,   String
    attribute :fqdn,   String, default: :name
    attribute :facts,  Hashie::Mash, mapping: { type: 'object' }, default: {}
    attribute :params, Hashie::Mash, mapping: { type: 'object' }, default: {}

    validates_each :params do |record, attr, value|
        # TODO: Don't get options every single time
        # Get default options
        options = Noodle::Option.get

        # Check for required params
        options.required_params.each do |param|
            record.errors.add attr, "#{param} must be provided but is not." if value[param.to_sym].nil?
        end

        # Check per-param liits
        options.limits.each do |param,limit|
            case limit.class.to_s
            when 'Array'
                record.errors.add attr, "#{param} is not one of these: #{limit.join(',')}.  It is #{value[param]}." unless limit.include?(value[param.to_sym])
            # cf TODO in option.rb
            when 'String'
                record.errors.add attr, "#{param} is not a(n) #{limit}" unless value[param.to_sym].nil? or value[param.to_sym].class.to_s == limit
            end
        end
    end

    def to_puppet
        r = {}
        # TODO: Get class list from node/options
        r['classes']    = ['baseclass']
        r['parameters'] = @params
        r.to_yaml.strip
    end

    def full
        r = []
        r << "Name:   " + @name
        r << "Params: " ; r << @params.map {|term,value| "  #{term}=#{value}"}
        r << "Facts:  " ; r << @facts.map  {|term,value| "  #{term}=#{value}"}
        r.join("\n")
    end

    def self.all_names
        body = self.all.results.collect{|hit| hit.name}.sort.join("\n")
        [body, 200]
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
    # Implemented:
    # x=y
    # x=~y
    # @x=y AKA -x=y
    # x?
    # x?=
    # x=
    # full
    # json # Implies full
    # hostname (partial or full)
    #
    # Still TODO:
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
        search = Noodle::Search.new(Noodle::Node)
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
                 term = part.sub(/\?=$/,'')
                 search.exists(term)
                 show << term

            when term_does_not_equal
                 term,value = part.sub(/^[-@]/,'').split(/=/,2)
                 search.not_equal(term,value)

            when term_show_value
                 show << part.chop

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
                 # Assume everything else is a hostname (or partial hostname)
                 # TODO: Maybe this is a bit awkward when bare words are used with
                 # other magic operators?
                 search.match_name(part)
                 format = :yaml
            end
        end

        # TODO: Don't get options every single time
        # Get default options
        options = Noodle::Option.get
        search.equals('ilk',   options.default_ilk)    unless search.search_terms.include?('ilk')
        search.equals('status',options.default_status) unless search.search_terms.include?('status')

        status = 200
        found = search.go
        case format
        when :json
            body = found.results.to_json + "\n"
        when :yaml
            body = found.results.map{|one| one.to_puppet}.join("\n") + "\n"
        when :full
            body = found.results.map{|one| one.full}.join("\n") + "\n"
        else
            ['',200] if found.response.hits.empty?
            # Always show name. Show term=value pairs for anything in 'show'
            body = []
            found.results.each do |hit|
                add = hit.name
                show.each do |term|
                    if !hit.params.nil?   and hit.params[term]
                        add << " #{term}=#{hit.params[term]}"
                    elsif !hit.facts.nil? and hit.facts[term]
                        add << " #{term}=#{hit.facts[term]}"
                    end
                end
                body << add + "\n"
            end
            body = body.sort.join
        end
        [body,status]
    end

    ## noodlin
    #
    # Below HOST can be short name (as long as it's unique) or FQDN
    # noodlin param|fact -r NAME HOST1 [HOST2 ...]    # Remove param or fact named NAME from listed HOSTs
    # noodlin param|fact NAME=VALUE HOST1 [HOST2 ...]  # Set param or fact named NAME to VALUE for listed HOSTs
    # noodlin param|fact NAME+=VALUE HOST1 [HOST2 ...] # Add    VALUE to   NAME (which must be an array) for listed HOSTs
    # noodlin param|fact NAME-=VALUE HOST1 [HOST2 ...] # Remove VALUE from NAME (which must be an array) for listed HOSTs
    #
    # noodlin enabled HOST1 [HOST2 ...] # shorthand for noodlin param status=enabled HOST1 [HOST2 ...]
    # noodlin enable  HOST1 [HOST2 ...] # more natural to type
    # noodlin surplus HOST1 [HOST2 ...] # shorthand for noodlin param status=surplus HOST1 [HOST2 ...]
    # noodlin future  HOST1 [HOST2 ...] # shorthand for noodlin param status=future HOST1 [HOST2 ...]
    # TODO: Maybe extend this to cover every possible status.
    #
    # Remove requires FQDNs for safety:
    # noodlin remove FQDN1 [FQDN2]      # Remove node(s)
    #
    # Don't forget to specify the required params:
    # noodlin create [-a PARAM=VALUE ...] [-f FACT=VALUE ...] FQDN
    #
    # For historical convenience?
    # noodlin create -i ILK -s STATUS -p PROJECT -P PRODLEVEL -s SITE [-a PARAM=VALUE ...] [-f FACT=VALUE ...] FQDN
    #
    # What else?
    def self.noodlin(changes)
        subcommand,rest = changes.split(/\s+/,2)
        opts = Trollop::options(rest) do
            opt :remove, "thing to remove (used with fact, param, and remove)", :type => :string
            opt :param,  "Add param paramname=value to add", :type => :string, :multi => true
            opt :fact,   "Add fact  factname=value",         :type => :string, :multi => true
        end
        case subcommand
        when 'create'
        when 'enabled' #,'enable' # TODO: Why does this fail?
        when 'fact'
        when 'future'
        when 'param'
        when 'surplus'
        end
    end

    # TODO: Catch errors
    def self.delete_everything
        index_name = Noodle::Node.gateway.index
        Noodle::Node.gateway.delete_index!
        Noodle::Node.gateway.index = index_name
        Noodle::Node.gateway.create_index!
        # TODO: This seems to work around the 503-causing race condition
        sleep 5
        Noodle::Node.gateway.refresh_index!
    end
end
