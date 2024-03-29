# Rubocop says:
# frozen_string_literal: true

# TODO: use repository.update :)

class Noodle
  # Docs RSN
  class Controller
    # Magic:
    #
    # Make everything return either JSON or pretty text, default based
    # on either user-agent or accepts or both or more :)
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
    #
    # TODO: Complain when there are conflicts. Example:
    #
    # A) sum and prodlevel= conflict. ATM sum "wins" and prodlevel= is
    # ignored. No doubt there are similar cases.
    #
    # B) unique_values only makes sense for one term. ATM it returns
    # the results for the LAST :BLAH in the query.
    def self.magic(query)
      search          = Noodle::Search.new(Noodle::NodeRepository.repository)
      show            = []
      format          = :default
      # merge           = false
      hostnames       = []
      thing2unique    = nil

      # NOTE: Order below must be preserved in case statement.
      bareword_hash               = Noodle::Option.class_variable_get(:@@bareword_hash)
      # TODO: Perhaps processing ? and ?= should happen in the same
      # block of code. This would/could allow for ?+ to work too. And
      # even permutations like =?
      term_present_and_show_value = Regexp.new '\?=$|=\?$'     # Matches when term ends in ?= or =?
      term_present                = Regexp.new '^[^@=]+\?$'    # Matches when term does not contain = and ends in ?
      term_does_not_equal         = Regexp.new '^[-@][^=]+=.+' # Matches when term starts with - or @ and contains X=Y
      term_not_present            = Regexp.new '^[-@][^=]+'
      # Order really matters for the rest of these:
      term_show_value             = Regexp.new '=$'            # Matches when terms ends with =
      term_matches_regexp         = Regexp.new '=~'            # Matches when term contais =~
      term_equals                 = Regexp.new '='             # Matches when term contains =; order matters for this
      term_unique_values          = Regexp.new '^:'            # Matches when term starts with :
      term_sum                    = Regexp.new '[+]$'          # Matches when term ends with +

      # Avoid overriding certain formats
      final_formats = %i[full json json_params_only]

      # TODO: The required ordering below is ugly which indicates
      # there's a better way.
      query = query.split(/\s+/) if query.instance_of?(String)

      query.each do |part|
        case part
        when *bareword_hash.keys
          format = :list unless final_formats.include?(format)
          value = part
          term = bareword_hash[value]
          search.equals(term, value)

        # Look for this before term_persent since term_present matches both
        when term_present_and_show_value
          format = :list unless final_formats.include?(format)
          term = part.sub(term_present_and_show_value, '')
          search.exists(term)
          show << term

        when term_does_not_equal
          format = :list unless final_formats.include?(format)
          term, value = part.sub(/^[-@]/, '').split(/=/, 2)
          search.not_equal(term, value)

        # Look for this after term_does_not_equal since it this regexp matches. TODO: Ugly!
        when term_not_present
          format = :list unless final_formats.include?(format)
          term = part.sub(/^[-@]/, '')
          search.does_not_exist(term)

        when term_present
          format = :list unless final_formats.include?(format)
          term = part.sub(/\?$/, '')
          search.exists(term)

        when term_show_value
          format = :list unless final_formats.include?(format)
          show << part.chop

        when term_matches_regexp
          format = :list unless final_formats.include?(format)
          term, value = part.split(term_matches_regexp, 2)
          search.match_regexp(term, value)

        when term_equals
          format = :list unless final_formats.include?(format)
          term, value = part.split(term_equals, 2)
          search.equals(term, value)

        when term_unique_values
          thing2unique = part.sub(term_unique_values, '')
          format = :unique_values unless final_formats.include?(format)

        when term_sum
          format = :sum unless final_formats.include?(format)
          term = part.sub(term_sum, '')
          search.sum(term)

        when 'full'
          format = :full unless %i[json json_params_only].include?(format)

        when 'json'
          format = :json

        when 'json_params_only'
          format = :json_params_only unless format == :json

        # TODO: What use cas was merge intended for? The search code had this:
        # found = merge(found,hostnames,show) if merge
        #
        # when 'merge'
        #   merge = true

        else
          # Assume everything else is a hostname (or partial hostname)
          # TODO: Maybe this is a bit awkward when bare words are used with
          # other magic operators?
          hostnames.push(part)
          search.match_names(part)
        end
      end

      # Use default ilk and status unless they are specified in the query:
      search.equals('ilk', Noodle::Option.option('default', 'default_ilk')) unless search.search_terms.include?('ilk')
      search.equals('status', Noodle::Option.option('default', 'default_status')) unless search.search_terms.include?('status')

      # Assume the best
      status = 200

      # There are just a few different cases. Listed in order of precedence:
      case format

      # 1. Unique is simply its own thing
      when :unique_values
        body = Noodle::Search.new(Noodle::NodeRepository.repository).param_values(term: thing2unique, facts: true).sort.join("\n") + "\n"

      # 2 Sum is also its own thing; as-is it overrides prodlevel= and similar
      when :sum
        body = []
        found = search.go
        found.response.aggregations.each do |param, sum|
          body << "#{param}=#{sum.value}"
        end
        body = body.join(' ')

      # 3. json and full in which we want *everything* returned with different output formats
      when :json
        search.limit_fetch(show)
        # TODO: TEMP: Exclude listening_procs from JSON output to
        # greatly reduce the to_json processing time. It would be
        # better to use the raw response from Elasticsearch (which is
        # already JSON) or .. something.
        found = search.go(exclude: ['facts.listening_procs'])
        body = "#{found.results.to_json}\n"
      when :full
        found = search.go
        body = "#{found.results.map(&:full).join("\n")}\n"

      # 4. json_params_only and yaml (AKA "puppet") in which we only want params returned (:json_params_only, :yaml)
      when :json_params_only
        found = search.go(name_and_params_only: true)
        # TODO: What's the pretty/correct way to do this?
        found.results.each do |result|
          result.facts = {}
        end
        body = found.results.to_json
      # 5. Everything else except for YAML, in which we only want hostnames *OR* hostnames plus specific fields
      when :list
        # Limit the search results to the fields we are supposed to display (if any)
        search.limit_fetch(show)
        # If no fields to show, limit the search results to node names
        found = search.go(names_only: show.empty?)

        ['', 200] if found.response.hits.empty?
        # Always show name. Show term=value pairs for anything in 'show'
        body = []
        shown = []
        found.results.each do |hit|
          add = hit.name
          show.each do |term|
            # Ahem, this funtimes "send" party lets you extract deep
            # values from hashes; it also works if the TERM value isn't
            # a hash (thanks, Hashie!)
            if !hit.params.nil? && (value = hit.params.send(*[:dig, term.split('.')].flatten))
              # TODO: Join arrays for facts too?
              value = value.sort.join(',') if value.class == Hashie::Array
              add << " #{term}=#{value}"
              shown << term
            elsif !hit.facts.nil? && (value = hit.facts.send(*[:dig, term.split('.')].flatten))
              add << " #{term}=#{value}"
              shown << term
            end
          end
          # To match original noodle if a term-to-show is not shown, add TERM= to the output:
          (show - shown).map { |i| add << " #{i}=" }
          body << add + "\n"
        end
        body = body.sort.join
      # 6. Otherwise, it's YAML
      else
        found = search.go(name_and_params_only: true)
        body = found.results.map(&:to_puppet).join("\n") + "\n"
      end
      [body, status]
    end

    ## merge
    #
    # Merge results into a single synthesized node, precedence
    # determined by the order in hostnames.
    #
    # That is, given a set of NODES, merge them into a single NODE by
    # merging the NODES' PARAMS. And return the NODE. HOSTNAMES
    # determines the order of the merge.
    #
    # We leave it up to the user to specify a sane order of
    # HOSTNAMES. you probably want high-level defaults to apply first,
    # project-level settings to override the defaults, and finally host-level
    # settings have the last laugh.
    #
    # For example, given these 3 nodes nodes:
    #
    # 1) defaults.example.com ilk=defaults dns_servers=8.8.8.8,8.8.4.4
    # (You default to using Google DNS servers)
    #
    # 2) webservers.projects.example.com dns_servers=209.244.0.3,209.244.0.4
    # (But for some reason need web servers to use Level3's public DNS servers)
    #
    # 3) web07.example.com dns_servers=216.146.35.35,216.146.36.36
    # (And for even stranger reasons web07 needs to use Dyn's public DNS servers)
    #
    # Here's how three different merges would work:
    #
    # a) Assume you want to know the value of the dns_servers param
    # after merging. And since you don't know whether the server in
    # question has host-specific settings, you ask to merge the default
    # settings, the settings for the webservers project, and the
    # settings for the web server at hand:
    #
    # noodle magic merge dns_servers= defaults.example.com webservers.projects.example.com web07.example.com
    #
    # Internally Noodle find 3 nodes, one for each FQDN. And then merges
    # the param value you requested to return a single value for the
    # param. Something like this:
    #
    # i)   value = ''
    # ii)  value = value of default.example.com's dns_servers param, if present
    # iii) value = value of webserver.projects.example.com's dns_servers param, if present
    # iv)  value = value of web07.example.com's dns_servers param, if present
    #
    # So the result of the query is:
    # web07.example.com dns_servers=216.146.35.35,216.146.36.36 # The Dyn servers
    #
    # b) Same thing but for a web node without a dns_servers param:
    #
    # noodle magic merge dns_servers= defaults.example.com webservers.projects.example.com web01.example.com
    #
    # Result:
    # web01.example.com dns_servers=209.244.0.3,209.244.0.4  # The Level3 servers
    #
    # c) Same thing but for a node in a different project:
    #
    # noodle magic merge dns_servers= defaults.example.com payments.example.com
    #
    # Result:
    # payments.example.com dns_servers=8.8.8.8,8.8.4.4 # Google's servers
    #
    # The MERGE method assumes NODES contains the nodes to merge,
    # HOSTNAMES contains the order, and PARAMS contains the param(s) to
    # merge. And the caller is responsible for displaying the results.
    def self.merge(nodes, hostnames, params)
      hash = {}
      params.map { |param| hash[param] = 'defaultUGLY' }
      nodes.sort_by { |node| hostnames.index(node.name) }.each do |node|
        params.each do |param|
          hash[param] = node.params[param] unless node.params[param].nil?
        end
      end
      puts 'merge hash is:'
      puts hash
      []
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
    def self.noodlin(changes, options)
      # Default to success
      status = 200
      body = +''

      # TODO: prettier?
      changes = changes.split(/\s+/, 2) if changes.instance_of?(String)
      command = changes.shift
      # TODO: Handle the case where rest is nil (how is it I haven't encountered that before?!)
      rest = changes

      # TODO: TEMPORARY HACK: This is ugly and will only refresh options on a single node in the cluster!
      if command == 'optionrefresh'
        Noodle::Option.refresh
        return ['Your options had a nap and they are nicely refreshed.', 200]
      end

      p = Optimist::Parser.new do
        opt :remove,    'thing to remove (used with fact, param)', type: :string
        opt :param,     'Add param paramname=value',               type: :string, multi: true, short: 'a'
        opt :fact,      'Add fact  factname=value',                type: :string, multi: true
        opt :ilk,       'Set ilk at create',                       type: :string
        opt :site,      'Set site at create',                      type: :string
        opt :status,    'Set status at create',                    type: :string
        opt :project,   'Set site at create',                      type: :string
        opt :prodlevel, 'Set prodlevel at create',                 type: :string, short: 'P'
        opt :who,       'Username of person making the change',    type: :string, short: 'w', required: true
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
      return ["Oops! No nodes specified.\n", 400] if nodes.empty?

      # Unless creating, must be able to find all nodes
      found = Noodle::Search.new(Noodle::NodeRepository.repository).match_names(nodes).go
      return false unless
        command == 'create' || found.any?

      allowed_statuses = Noodle::Option.limit('default', 'status')
      # TODO: default_ilk = 'host'
      default_status = 'enabled'

      # TODO: Error when "at create" argument given but not
      # creating.  Maybe easiest if switch to gli :)
      case command
      when 'create'
        # TODO: Create more than one at a time?
        nodes.each do |name|
          args = {
            'name' => name
          }
          facts = {}
          params = {}

          # Convert special opts into params:
          params['created_by']      = opts[:who]
          params['ilk']             = opts[:ilk] # TODO: || default_ilk,
          params['project']         = opts[:project]
          params['prodlevel']       = opts[:prodlevel]
          params['site']            = opts[:site]
          params['status']          = opts[:status] || default_status # TODO
          params['last_updated_by'] = opts[:who]

          # Merge in the rest
          # TODO: Can facts have required type?
          opts[:fact].map { |pair| name, value = pair.split(/=/); facts[name] = value }
          opts[:param].map { |pair| name, value = pair.split(/=/); params[name] = maybe2array(params['ilk'], name, value) }

          args['facts']  = facts
          args['params'] = params
          node = create_one(args, options)
          if node.class != Noodle::Node
            body = node[:errors]
            status = 444
          end
        end
      when 'fact', 'param'
        which = "#{command}s"
        if opts[:remove]
          found.each do |node|
            node.params.last_updated_by = opts[:who]
            node.send(which).delete(opts[:remove])
            # TODO: DRY this begin/rescue/end
            begin
              Noodle::NodeRepository.repository.save(node, refresh: true)
            rescue => e
              body << "#{e}\n"
              status = 400
            end
          end
        else
          [opts[command.to_sym] + pairs].flatten.each do |change|
            name, op, value = change.match(/^([^-+=]+)([-+]*=)(.*)$/)[1..3]

            # TODO: Error check fact names and values
            # TODO: Do something with the error strings below :)
            case op
            when '='
              found.each do |node|
                node.params.last_updated_by = opts[:who]

                # If param must be an array split value on ,
                # Avoid changing original 'value' so this works on the second, etc iterations of the loop:
                new_value = value
                new_value = [value.split(',')].flatten if Noodle::Option.limit(node.params['ilk'], name) == 'array'
                # If param must be a hash, create a hash based on name,value
                first_key_part, rest_key_parts = name.split('.', 2)
                new_value = hash_it(rest_key_parts, new_value) if Noodle::Option.limit(node.params['ilk'], first_key_part) == 'hash'
                # If param must be a hash, merge hash created above into existing (or not) value for node
                if Noodle::Option.limit(node.params['ilk'], first_key_part) == 'hash'
                  node.send(which)[first_key_part] = {} if node.send(which)[first_key_part].nil?
                  node.send(which)[first_key_part].deep_merge!(new_value)
                else
                  node.send(which)[name] = new_value
                end

                r = node.errors?
                if r.class == Noodle::Node
                  begin
                    Noodle::NodeRepository.repository.save(node, refresh: true)
                  rescue => e
                    body << "#{e}\n"
                    status = 400
                  end
                else
                  body << node.errors?(silent_if_none: true)[:errors].to_s
                end
              end
            when '+=', '-='
              method = op == '+=' ? :push : :delete
              found.each do |node|
                if node.send(which)[name].is_a?(Array)
                  # Handle the case where they want to add multiple new elements to the array
                  # as in: noodlin param role+=app,db,web
                  value.split(',').each do |one_value|
                    node.send(which)[name].send(method, one_value)
                  end
                  r = node.errors?
                  if r.class == Noodle::Node
                    begin
                      Noodle::NodeRepository.repository.save(node, refresh: true)
                    rescue => e
                      body << "#{e}\n"
                      status = 400
                    end
                  else
                    body << node.errors?(silent_if_none: true)[:errors].to_s
                  end
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
          node.params['last_updated_by'] = opts[:who]
          node.params['status'] = command
          r = node.errors?
          if r.class == Noodle::Node
            begin
              Noodle::NodeRepository.repository.save(node, refresh: true)
            rescue => e
              body << "#{e}\n"
              status = 400
            end
          else
            body << node.errors?(silent_if_none: true)[:errors].to_s
          end
        end
      when 'remove'
        found.map { |node| Noodle::NodeRepository.repository.delete(node, refresh: true) }
      # TODO: Error check
      else
        status = 400
        body = "Unknown noodlin command: #{command}"
      end
      [body, status]
    end

    # Update a node based on options.
    def self.update(node, args, options = { now: false, replace_all: true })
      args.each_pair do |key, value|
        value = node.send(key).deep_merge(value) unless options[:replace_all]
        node.send("#{key}=", value)
      end
      node.facts.noodle_update_time = Time.now.utc.iso8601

      # TODO: is this order and being outside the loop correct?
      r = node.errors?
      if r.class == Noodle::Node
        begin
          # TODO: Temporary until elasticsearch-persistence supports
          # query param options in update. No refresh:
          Noodle::NodeRepository.repository.update(node)
          # TODO: Once it's supported, get refresh option back by
          # switching to this:
          # Noodle::NodeRepository.repository.update(node, {}, refresh: options[:now])
          #
          # This patch works in my testing, needs updated spec to match:
          # https://github.com/happymcplaksin/elasticsearch-rails/commit/070006c69d9fd54ab90cbc678ec237b649ba8d05
        rescue => e
          r = { errors: "#{e}\n" }
        end
      end
      r
    end

    # TODO: Catch errors
    def self.delete_everything
      Noodle::NodeRepository.repository.delete_index!
      Noodle::NodeRepository.repository.create_index!
      # TODO: This seems to work around the 503-causing race condition
      sleep 5
      Noodle::NodeRepository.repository.refresh_index!
    end

    def self.delete_one(name)
      return false unless (node = Noodle::Search.new(Noodle::NodeRepository.repository).match_names_exact(name).go(size: 1))

      Noodle::NodeRepository.repository.delete(node, refresh: true)
      true
    end

    def self.create_one(args, options = { now: false })
      node = Noodle::Node.new(args)
      # TODO: This is probably bogus:
      # Set default FQDN fact in case none provided
      node.facts[:fqdn] = node.name if node.facts[:fqdn].nil?
      # Set create time when not provided
      now = Time.now.utc.iso8601
      node.facts.noodle_create_time = now if node.facts.noodle_create_time.nil?
      node.facts.noodle_update_time = now

      # TODO: This is both ugly and repeated :(
      r = node.errors?
      if r.class == Noodle::Node
        begin
          Noodle::NodeRepository.repository.save(node, refresh: options[:now])
        rescue => e
          r = { errors: "#{e}\n" }
        end
      end
      r
    end

    def self.all_names
      body = Noodle::NodeRepository.repository.all.results.collect(&:name).sort.join("\n")
      [body, 200]
    end

    def self.maybe2array(ilk, name, value)
      return [value.split(',')].flatten if Noodle::Option.limit(ilk, name) == 'array'

      value
    end

    # hash_it: Recursively turn key=value into a hash. Each . in key
    # indicates another level of the hash. For example:
    #
    # noodlin param gecos.firstname=mark
    # noodlin param gecos.lastname=plaksin
    # noodlin param gecos.address.street='110 orchard knob ln'
    # noodlin param gecos.address.city='athens'
    # noodlin param gecos.address.state='ga'
    # noodlin param gecos.address.zipcode='30605'
    #
    # OR
    #
    # TODO: noodlin param gecos={JSON}
    def self.hash_it(name, value, hash = {})
      unless name.match('[.]')
        # Inside hashes, make , in the value mean "split on , and turn this string into an array"
        # TODO: Make this a setting?
        # TODO: Or is there a less-ugly way of doing this?
        hash[name] = value.match(',') ? value.split(',') : value
        return hash
      end

      key, rest = name.split('.', 2)
      hash[key] = hash_it(rest, value)
      hash
    end
  end
end
