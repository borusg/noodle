# TODO: Add last_update_time :)

# TODO: use repository.update :)

class Noodle::Controller
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
  def self.magic(query)
    search          = Noodle::Search.new(Noodle::NodeRepository.repository)
    show            = []
    format          = :default
    list            = false
    merge           = false
    hostnames       = []
    thing2unique    = nil

    # NOTE: Order below should be preserved in case statement
    bareword_hash               = Noodle::Option.class_variable_get(:@@bareword_hash)
    # TODO: Perhaps processing ? and ?= should happen in the same
    # block of code. This would/could allow for ?+ to work too. And
    # even permutations like =?
    term_present_and_show_value = Regexp.new '\?=$|=\?$'
    term_present                = Regexp.new '\?$'
    term_does_not_equal         = Regexp.new '^[-@][^=]+=.+'
    term_not_present            = Regexp.new '^[-@]'
    term_show_value             = Regexp.new '=$'
    term_matches_regexp         = Regexp.new '=~'
    term_equals                 = Regexp.new '='
    term_unique_values          = Regexp.new '^:'
    term_sum                    = Regexp.new '[+]$'

    # TODO: The required ordering below is ugly which indicates
    # there's a better way.
    query.split(/\s+/).each do |part|
      case part
      when *bareword_hash.keys
        list  = true
        value = part
        term  = bareword_hash[value]
        search.equals(term,value)

      # Look for this before term_persent since term_present matches both
      when term_present_and_show_value
        list = true
        term = part.sub(term_present_and_show_value,'')
        search.exists(term)
        show << term

      when term_does_not_equal
        list = true
        term,value = part.sub(/^[-@]/,'').split(/=/,2)
        search.not_equal(term,value)

      # Look for this after term_does_not_equal since it this regexp matches. TODO: Ugly!
      when term_not_present
        list = true
        term = part.sub(term_not_present,'')
        search.does_not_exist(term)

      when term_present
        list = true
        term = part.sub(term_present,'')
        search.exists(term)

      when term_show_value
        list = true
        show << part.chop

      when term_matches_regexp
        list = true
        term,value = part.split(term_matches_regexp,2)
        search.match(term,value)

      when term_equals
        list = true
        term,value = part.split(term_equals,2)
        search.equals(term,value)

      when term_unique_values
        thing2unique = part.sub(term_unique_values,'')
        format = :unique

      when term_sum
        format = :sum
        term = part.sub(term_sum,'')
        search.sum(term)

      when 'full'
        format = :full

      when 'json'
        format = :json

      when 'merge'
        merge = true

      when 'justonevalue,json'
        format = :justonevalue

      else
        # Assume everything else is a hostname (or partial hostname)
        # TODO: Maybe this is a bit awkward when bare words are used with
        # other magic operators?
        hostnames.push(part)
        search.match_names(part)
      end
    end

    # TODO: Not pretty
    # If list is true, just list nodes, otherwise output in YAML.
    # Unless, or course, a special format was specified
    if format != :json and format != :full and format != :unique and format != :justonevalue and format != :sum
      format = list ? :default : :yaml
    end

    search.equals('ilk',   Noodle::Option.option('default','default_ilk'))    unless search.search_terms.include?('ilk')
    search.equals('status',Noodle::Option.option('default','default_status')) unless search.search_terms.include?('status')

    search.limit_fetch(show)
    status = 200

    # Unique is a very special case (no surprise?!)
    unless format == :unique
      found = search.go(names_only: format == list, name_and_params_only: format == :yaml)
      found = merge(found,hostnames,show) if merge
    end

    case format
    when :unique
      body = Noodle::Search.new(Noodle::NodeRepository.repository).param_values(term: thing2unique, facts: true).sort.join("\n") + "\n"
    when :json
      body = found.results.to_json + "\n"
    when :yaml
      body = found.results.map{|one| one.to_puppet}.join("\n") + "\n"
    when :full
      body = found.results.map{|one| one.full}.join("\n") + "\n"
    when :justonevalue
      # Super-special case:
      # 1. Errors if there is more than one search result
      # 2. Errors if more than one param to show
      # 3. Returns JSON for the value for easy consumption
      # 4. Should probably be implemented in some other way!
      unless found.results.size == 1 and show.size == 1
        status = 500
        body   = 'More than one result found but you specified just_one_value'
      else
        it = found.results.first
        # TODO There should be a fact_or_param helper or something!
        # Was it a param?
        if !it.params.nil? and it.params[show.first]
          body = it.params[show.first].to_json + "\n"
        elsif !it.facts.nil? and it.facts[show.first]
          body = it.facts[show.first].to_json + "\n"
        else
          status = 500
          body = 'Nothing found'
        end
      end
    when :sum
      body = []
      found.response.aggregations.each do |param,sum|
        body << "#{param}=#{sum.value}"
      end
      body = body.join(' ')
    else
      ['',200] if found.response.hits.empty?
      # Always show name. Show term=value pairs for anything in 'show'
      body = []
      found.results.each do |hit|
        add = hit.name
        show.each do |term|
          if !hit.params.nil? and hit.params[term]
            value = hit.params[term]
            # TODO: Join arrays for facts too?  What about hashes?
            value = value.sort.join(',') if value.class == Hashie::Array
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
  def self.merge(nodes,hostnames,params)
    hash = {}
    params.map{|param| hash[param] = 'defaultUGLY'}
    nodes.sort_by{|node| hostnames.index(node.name)}.each do |node|
      params.each do |param|
        hash[param] = node.params[param] unless node.params[param].nil?
      end
    end
    puts "merge hash is:"
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
    body = ''

    # TODO prettier?
    command,rest = changes.split(/\s+/,2)
    # TODO: TEMPORARY HACK: This is ugly and will only refresh options on a single node in the cluster!
    if command == 'optionrefresh'
      Noodle::Option.refresh
      return ['Your options had a nap and they are nicely refreshed.',200]
    end

    # TODO: Handle the case where rest is nil (how is it I haven't encountered that before?!)
    rest = rest.split(/\s+/)

    p = Optimist::Parser.new do
      opt :remove,    "thing to remove (used with fact, param)", :type => :string
      opt :param,     "Add param paramname=value",               :type => :string, :multi => true, :short => 'a'
      opt :fact,      "Add fact  factname=value",                :type => :string, :multi => true
      opt :ilk,       "Set ilk at create",                       :type => :string
      opt :site,      "Set site at create",                      :type => :string
      opt :status,    "Set status at create",                    :type => :string
      opt :project,   "Set site at create",                      :type => :string
      opt :prodlevel, "Set prodlevel at create",                 :type => :string, :short => 'P'
      opt :who,       "Username of person making the change",    :type => :string, :short => 'w', :required => true
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
    return ["Oops! No nodes specified.\n",400] if nodes.empty?
 
    # Unless creating, must be able to find all nodes
    return false unless command == 'create' or found =
                                               Noodle::Search.new(Noodle::NodeRepository.repository).match_names(nodes).go

    allowed_statuses = Noodle::Option.limit('default','status')
    # TODO: default_ilk = 'host'
    default_status = 'enabled'

    # TODO: Error when "at create" argument given but not
    # creating.  Maybe easiest if switch to gli :)
    case command
    when 'create'
      # TODO: Create more than one at a time?
      nodes.each do |name|
        args = {
          'name'       => name,
        }
        facts  = Hash.new
        params = Hash.new

        # Convert special opts into params:
        params['created_by']      = opts[:who],
        params['ilk']             = opts[:ilk]    #|| default_ilk,    # TODO
        params['project']         = opts[:project]
        params['prodlevel']       = opts[:prodlevel]
        params['site']            = opts[:site]
        params['status']          = opts[:status] || default_status  # TODO
        params['last_updated_by'] = opts[:who]

        # Merge in the rest
        # TODO: Can facts have required type?
        opts[:fact].map {|pair| name,value = pair.split(/=/); facts[name]  = value}
        opts[:param].map{|pair| name,value = pair.split(/=/); params[name] = maybe2array(params['ilk'],name,value)}

        args['facts']  = facts
        args['params'] = params
        node = create_one(args, options)
        if node.class != Noodle::Node
          body = node[:errors]
          status = 444
        end
      end
    when 'fact','param'
      which = "#{command}s"
      if opts[:remove]
        found.each do |node|
          node.params.last_updated_by = opts[:who]
          node.send(which).delete(opts[:remove])
          # TODO: DRY this begin/rescue/end
          begin
            Noodle::NodeRepository.repository.save(node, refresh: true)
          rescue => e
            body << "#{e.to_s}\n"
            status = 400
          end
        end
      else
        [opts[command.to_sym] + pairs].flatten.each do |change|
          name,op,value = change.match(/^([^-+=]+)([-+]*=)(.*)$/)[1..3]

          # TODO: Error check fact names and values
          # TODO: Do something with the error strings below :)
          case op
          when '='
            found.each do |node|
              node.params.last_updated_by = opts[:who]

              # If param must be an array split value on ,
              # Avoid changing original 'value' so this works on the second, etc iterations of the loop:
              new_value = value
              new_value = [value.split(',')].flatten if Noodle::Option.limit(node.params['ilk'],name) == 'array'
              # If param must be a hash, create a hash based on name,value
              first_key_part,rest_key_parts = name.split('.',2)
              new_value = hash_it(rest_key_parts,new_value) if Noodle::Option.limit(node.params['ilk'],first_key_part) == 'hash'
              # If param must be a hash, merge hash created above into existing (or not) value for node
              if Noodle::Option.limit(node.params['ilk'],first_key_part) == 'hash'
                node.send(which)[first_key_part] = Hash.new if node.send(which)[first_key_part].nil?
                node.send(which)[first_key_part].deep_merge!(new_value)
              else
                node.send(which)[name] = new_value
              end

              r = node.errors?
              if r.class == Noodle::Node
                begin
                  Noodle::NodeRepository.repository.save(node, refresh: true)
                rescue => e
                  body << "#{e.to_s}\n"
                  status = 400
                end
              else
                body << node.errors?(silent_if_none: true).to_s
              end
            end
          when '+=','-='
            method = op == '+=' ? :push : :delete
            found.each do |node|
              if node.send(which)[name].kind_of?(Array)
                # Handle the case where they want to add multiple new elements to the array
                # as in: noodlin param role+=app,db,web
                value.split(',').each do |one_value|
                  node.send(which)[name].send(method,one_value)
                end
                r = node.errors?
                if r.class == Noodle::Node
                  begin
                    Noodle::NodeRepository.repository.save(node, refresh: true)
                  rescue => e
                    body << "#{e.to_s}\n"
                    status = 400
                  end
                else
                  body << node.errors?(silent_if_none: true).to_s
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
            body << "#{e.to_s}\n"
            status = 400
          end
        else
          body << node.errors?(silent_if_none: true).to_s
        end
      end
    when 'remove'
      found.map{|node| Noodle::NodeRepository.repository.delete(node, refresh: true)}
    # TODO: Error check
    else
      status = 400
      body = "Unknown noodlin command: #{command}"
    end
    [body,status]
  end

  # Update a node based on options.
  def self.update(node,args,options = {now: false})
    args.each_pair do |key,value|
      node.send("#{key}=", node.send(key).deep_merge(value))
    end
    # TODO: is this order and being outside the loop correct?
    r = node.errors?
    if r.class == Noodle::Node
      begin
        Noodle::NodeRepository.repository.save(node, refresh: options[:now])
      rescue => e
        r = {errors: "#{e.to_s}\n"}
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
    return false unless node =
                        Noodle::Search.new(Noodle::NodeRepository.repository).match_names_exact(name).go(size: 1)
    Noodle::NodeRepository.repository.delete(node, refresh: true)
    return true
  end

  def self.create_one(args,options = {now: false})
    node = Noodle::Node.new(args)

    # TODO: This is probably bogus:
    # Set default FQDN fact in case none provided
    if node.facts[:fqdn].nil?
      node.facts[:fqdn] = node.name
    end

    # TODO: This is both ugly and repeated :(
    r = node.errors?
    if r.class == Noodle::Node
      begin
        Noodle::NodeRepository.repository.save(node, refresh: options[:now])
      rescue => e
        r = {errors: "#{e.to_s}\n"}
      end
    end
    r
  end

  def self.all_names
    body = Noodle::NodeRepository.repository.all.results.collect{|hit| hit.name}.sort.join("\n")
    [body, 200]
  end

  def self.maybe2array(ilk,name,value)
    return [value.split(',')].flatten if Noodle::Option.limit(ilk,name) == 'array'
    return value
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
  def self.hash_it(name,value,hash=Hash.new)
    unless name.match('[.]')
      # Inside hashes, make , in the value mean "split on , and turn this string into an array"
      # TODO: Make this a setting?
      # TODO: Or is there a less-ugly way of doing this?
      hash[name] = value.match(',') ? value.split(',') : value
      return hash
    end

    key,rest = name.split('.',2)
    hash[key] = hash_it(rest,value)
    return hash
  end
end
