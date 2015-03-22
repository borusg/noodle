require 'elasticsearch/persistence/model'
require 'hashie'
require 'trollop'

class Noodle::Node
    include Elasticsearch::Persistence::Model

    attribute :name,   String,       mapping: { index: 'not_analyzed' }
    attribute :fqdn,   String, default: :name
    attribute :facts,  Hashie::Mash, mapping: { type: 'object' }, default: {}
    attribute :params, Hashie::Mash, mapping: { type: 'object' }, default: {}

    validates_each :params do |record, attr, value|
        # TODO: Don't get options every single time
        # Get default options
        options = Noodle::Option.get

        # Check for required params
        options.required_params.each do |param|
            record.errors.add attr, "#{param} must be provided but is not." if value[param].nil?
        end

        # Check per-param liits
        options.limits.each do |param,limit|
            case limit.class.to_s
            when 'Array'
                record.errors.add attr, "#{param} is not one of these: #{limit.join(',')}.  It is #{value[param]}." unless
                    limit.include?(value[param])
            # cf TODO in option.rb
            when 'String'
                record.errors.add attr, "#{param} is not a(n) #{limit}" unless
                    value[param].nil? or value[param].class.to_s.downcase == limit
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

    # Update a node based on options.
    # TODO: Catch errors
    # TODO: Referring to myself must be wrong?
    def update(options)
        options.each_pair do |key,value|
            # TODO: Yuck?
            # TODO: Elsewhere isn't status a param?
            if [:status, :ilk].include?(key)
                # ilk and status are just strings,
                self.send("#{key}=", value)
            else
                # facts and params are Hashie::Mash
                self.send("#{key}=", self.send(key).deep_merge(value))
            end 
            self.save refresh: true
        end
        self.errors?
    end

    # If node has errors, return hash containing errors and node.
    # If no errors and ! args[:silent_if_none], return node
    # Otherwise return node
    # Otherwise return node
    def errors?(args={:silent_if_none => false})
        unless self.valid?
            errors = self.errors.messages.values.flatten.join("\n") + "\n"
            return {errors: errors, node: self}
        else
            return args[:silent_if_none] ? '' : self
        end
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
    # hostnames (partial or full)
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
        list   = false

        # NOTE: Order below should be preserved in case statement
        bareword_hash               = get_bareword_hash
        term_present                = Regexp.new '\?$'
        term_present_and_show_value = Regexp.new '\?=$'
        term_does_not_equal         = Regexp.new '^[-@][^=]+=.+'
        term_show_value             = Regexp.new '=$'
        term_matches_regexp         = Regexp.new '=~'
        term_equals                 = Regexp.new '='

        query.split(/\s+/).each do |part|
            case part
            when *bareword_hash.keys
                list  = true
                value = part
                term  = bareword_hash[value]
                search.equals(term,value)

            when term_present
                list = true
                term = part.sub(/\?$/,'')
                search.exists(term)

            when term_present_and_show_value
                list = true
                term = part.sub(/\?=$/,'')
                search.exists(term)
                show << term

            when term_does_not_equal
                list = true
                term,value = part.sub(/^[-@]/,'').split(/=/,2)
                search.not_equal(term,value)

            when term_show_value
                list = true
                show << part.chop

            when term_matches_regexp
                list = true
                term,value = part.split(/=~/,2)
                search.match(term,value)

            when term_equals
                list = true
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
                search.match_names(part)
            end
        end

        # TODO: Not pretty
        # If list is true, just list nodes, otherwise output in YAML.
        # Unless, or course, json or full was specified
        if format != :json and format != :full
            format = list ? :default : :yaml
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
                        value = hit.params[term]
                        # TODO: Join arrays for facts too?  What about hashes?
                        value = value.sort.join(',') if Noodle::Option.get.limits[term] == 'array'
                        add << " #{term}=#{value}"
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
    # noodlin param|fact -r NAME HOST1 [HOST2 ...]     # Remove param or fact named NAME from listed HOSTs
    # noodlin param|fact NAME=VALUE HOST1 [HOST2 ...]  # Set param or fact named NAME to VALUE for listed HOSTs
    # noodlin param|fact NAME+=VALUE HOST1 [HOST2 ...] # Add    VALUE to   NAME (which must be an array) for listed HOSTs
    # noodlin param|fact NAME-=VALUE HOST1 [HOST2 ...] # Remove VALUE from NAME (which must be an array) for listed HOSTs
    #
    # TODO: Maybe extend this to cover every possible status.
    # noodlin enable  HOST1 [HOST2 ...] # shorthand for noodlin param status=enabled HOST1 [HOST2 ...]
    # noodlin surplus HOST1 [HOST2 ...] # shorthand for noodlin param status=surplus HOST1 [HOST2 ...]
    # noodlin future  HOST1 [HOST2 ...] # shorthand for noodlin param status=future HOST1 [HOST2 ...]
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
        # Default to success
        status = 200
        body = ''

        # TODO prettier?
        command,rest = changes.split(/\s+/,2)
        rest = rest.split(/\s+/)

        p = Trollop::Parser.new do
            opt :remove,   "thing to remove (used with fact, param)", :type => :string
            opt :param,    "Add param paramname=value",               :type => :string, :multi => true, :short => 'a'
            opt :fact,     "Add fact  factname=value",                :type => :string, :multi => true
            opt :ilk,      "Set ilk at create",                       :type => :string
            opt :site,     "Set site at create",                      :type => :string
            opt :status,   "Set status at create",                    :type => :string
            opt :project,  "Set site at create",                      :type => :string
            opt :prodlevel,"Set prodlevel at create",                 :type => :string, :short => 'P'
        end
        opts = p.parse(rest)
        # At this point rest contains node(s) and possibly key=value
        # pairs for the fact or param sub-commands

        # Now split into nodes and pairs
        # TODO: Prettier
        pairs = []
        rest.each do |elem|
            pairs << rest.delete(elem) if elem.match('=')
        end
        nodes = rest

        # Unless creating, must be able to find all nodes
        return false unless command == 'create' or found =
            Noodle::Search.new(Noodle::Node).match_names(nodes).go({:minimum => nodes.size})

        # TODO: Cache options
        allowed_statuses = Noodle::Option.get.allowed_statuses
        # TODO:
        default_ilk = 'host'
        default_status = 'enabled'

        # TODO: Error when "at create" argument given but not
        # creating.  Maybe easiest if switch to gli :)
        case command
        when 'create'
            # TODO: Create more than one at a time?
            nodes.each do |name|
                args = {
                    name:    name,
                    id:      name,
                }
                facts  = Hash.new
                params = Hash.new

                # Convert special opts into params:
                params['ilk']       = opts[:ilk]    #|| default_ilk,    # TODO
                params['project']   = opts[:project]
                params['prodlevel'] = opts[:prodlevel]
                params['site']      = opts[:site]
                params['status']    = opts[:status] || default_status  # TODO

                # Merge in the rest
                # TODO: Can facts have required type?
                opts[:fact].map {|pair| name,value = pair.split(/=/); facts[name]  = value}
                opts[:param].map{|pair| name,value = pair.split(/=/); params[name] = maybe2array(name,value)}

                args[:facts]  = facts
                args[:params] = params
                node = Noodle::Node.create_one(args)

                if defined?(node.keys) and node.keys.member?(:errors)
                    body = node[:errors]
                    status = 444
                end
            end
        when 'fact','param'
            which = "#{command}s"
            if opts[:remove]
                found.each do |node|
                    node.send(which).delete(opts[:remove])
                    node.save refresh: true
                end
            else
                [opts[command.to_sym] + pairs].flatten.each do |change|
                    name,op,value = change.match(/^([^-+=]+)([-+]*=)(.*)$/)[1..3]
    
                    # TODO: Error check fact names and values
                    # TODO: Do something with the error strings below :)
                    case op
                    when '='
                        # If param must be an array split value on ,
                        value = [value.split(',')].flatten if Noodle::Option.get.limits[name] == 'array'
                        found.each do |node|
                            node.send(which)[name] = value
                            node.save refresh: true
                            body << node.errors?(silent_if_none: true).to_s
                        end
                    when '+=','-='
                        method = op == '+=' ? :push : :delete
                        found.each do |node|
                            if node.send(which)[name].kind_of?(Array)
                                node.send(which)[name].send(method,value)
                                node.save refresh: true
                                body << node.errors?(silent_if_none: true)
                            else
                                body << "#{name} is not an array for #{node.name}"
                            end
                        end
                    else
                        body << "unknown op: #{op}"
                    end
                end
            end
        when *allowed_statuses
            found.each do |node|
                node.params['status'] = command
                node.save refresh: true
                body << node.errors?(silent_if_none: true).to_s
            end
        when 'remove'
            found.map{|node| node.destroy refresh: true}
            # TODO: Error check
        else
            status = 400
            body = "Unknown noodlin command: #{command}"
        end
        [body,status]
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

    def self.delete_one(name)
        return false unless node =
            Noodle::Search.new(Noodle::Node).match_names(name).go({:justone => true})
        node.destroy
        return true
    end

    def self.create_one(args)
        node = Noodle::Node.create(args,refresh: true)

        # Set default FQDN fact in case none provided
        if node.facts[:fqdn].nil?
            node.facts[:fqdn] = node.name
            node.save refresh: true
        end

        node.errors?
    end

    def self.maybe2array(name,value)
        return [value.split(',')].flatten if Noodle::Option.get.limits[name] == 'array'
        return value
    end

    # Return a hash of barewordvalue => paramname for use in magic
    # For example:
    # {
    #   'mars'       => 'site'
    #   'jupiter     => 'site'
    #   'hr'         => 'project'
    #   'financials' => 'project'
    # }
    # Convoluted?  Maybe but makes magic easier
    def self.get_bareword_hash
        h = {}
        Noodle::Option.get.bareword_terms.each do |term|
            Noodle::Search.new(Noodle::Node).paramvalues(term).each do |value|
                h[value] = term
            end
        end
        h
    end
end
