require_relative 'option'
require 'elasticsearch/persistence/model'
require 'hashie'
require 'trollop'

class Noodle::Node
  class NodeUniqueValidator < ActiveModel::Validator
    # Make sure new node is, or existing node remains, unique.
    #
    # NOTE: There is a race condition. Fix later! The race condition
    # can be triggered when simultaneous node creates or param updates
    # are made. This is a rare situation (at least for us) so
    # postponing the fix seems OK.
    #
    # There is a race condition because the uniqueness check does
    # *not* insert anything into the backend store (Elasticsearch). So
    # two simultaneous uniqueness checks can decide it's OK to insert
    # identical nodes. Both uniqueness checks can succeed. After the
    # uniqueness checks, the nodes are added to Elasticsearch.
    def validate(record)
      # TODO: Don't get options every single time
      # Get default options
      record.errors.add :base, 'Nope! Node is not unique' unless unique?(record,Noodle::Option.option(record.params['ilk'],'uniqueness'))
    end

    private
    def unique?(record,uniqueness_params)
      # name is always part of uniqueness
      search = Noodle::Search.new(Noodle::Node).match_names(record['name'])
      # Add uniqueness_params to search
      uniqueness_params.each do |param|
        search.equals(param,record.params[param])
      end
      # Search!
      r = search.go.results

      # Remove record itself from the results to handle cases where
      # record is getting *updated*
      r.delete_if{|node| node.id == record.id}

      # It's unique if no results remain
      r.empty?
    end
  end

  include Elasticsearch::Persistence::Model

  attribute :name,   String,       mapping: { index: 'not_analyzed' }
  attribute :fqdn,   String, default: :name
  attribute :facts,  Hashie::Mash, mapping: { type: 'object', dynamic: true }, default: {}
  attribute :params, Hashie::Mash, mapping: { type: 'object', dynamic: true }, default: {}

  # Validate node uniqueness (by default ilk+name must be unique
  validates_with NodeUniqueValidator

  validates_each :params do |record, attr, value|
    # Check for required params
    Noodle::Option.option(record.params['ilk'],'required_params').each do |param|
      record.errors.add attr, "#{param} must be provided but is not." if value[param].nil?
    end

    # Check per-param liits
    Noodle::Option.option(record.params['ilk'],'limits').each do |param,limit|
      case limit.class.to_s
      when 'Array'
        record.errors.add attr, "#{param} is not one of these: #{limit.join(',')}.  It is #{value[param]}." unless
          limit.include?(value[param])
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
      self.send("#{key}=", self.send(key).deep_merge(value))
      self.save refresh: true
    end
    self.errors?
  end

  # If node has errors, return hash containing errors and node.
  # If no errors and ! args[:silent_if_none], return node
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
    search    = Noodle::Search.new(Noodle::Node)
    show      = []
    format    = :default
    list      = false
    merge     = false
    hostnames = []

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

      when 'merge'
        merge = true

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
    # Unless, or course, json or full was specified
    if format != :json and format != :full
      format = list ? :default : :yaml
    end

    search.equals('ilk',   Noodle::Option.option('default','default_ilk'))    unless search.search_terms.include?('ilk')
    search.equals('status',Noodle::Option.option('default','default_status')) unless search.search_terms.include?('status')

    status = 200
    found = search.go
    found = merge(found,hostnames,show) if merge

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
            value = value.sort.join(',') if value.class == Array
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
    return ["Oops! No nodes specified.\n",400] if nodes.empty?
 
    # Unless creating, must be able to find all nodes
    return false unless command == 'create' or found =
                                               Noodle::Search.new(Noodle::Node).match_names(nodes).go({:minimum => nodes.size})

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
          name:    name,
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
        opts[:param].map{|pair| name,value = pair.split(/=/); params[name] = maybe2array(params['ilk'],name,value)}

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
            found.each do |node|
              # If param must be an array split value on ,
              value = [value.split(',')].flatten if Noodle::Option.limit(node.params['ilk'],name) == 'array'
              # If param must be a hash, create a has based on name,value
              first_key_part,rest_key_parts = name.split('.',2)
              value = hash_it(rest_key_parts,value) if Noodle::Option.limit(node.params['ilk'],first_key_part) == 'hash'
                # If param must be a hash, merge hash created above into existing (or not) value for node
              if Noodle::Option.limit(node.params['ilk'],first_key_part) == 'hash'
                node.send(which)[first_key_part] = Hash.new if node.send(which)[first_key_part].nil?
                node.send(which)[first_key_part].deep_merge!(value)
              else
                node.send(which)[name] = value
              end
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
    node = Noodle::Node.new(args)

    # TODO: This is probably bogus:
    # Set default FQDN fact in case none provided
    if node.facts[:fqdn].nil?
      node.facts[:fqdn] = node.name
    end

    r = node.errors?
    #puts "r is #{r}"
    if r.class == Noodle::Node
      #puts 'saving'
      node.save refresh: true
    end
    r
  end

  def self.maybe2array(ilk,name,value)
    return [value.split(',')].flatten if Noodle::Option.limit(ilk,name) == 'array'
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
    Noodle::Option.option('default','bareword_terms').each do |term|
      Noodle::Search.new(Noodle::Node).paramvalues(term).each do |value|
        h[value] = term
      end
    end
    h
  end

  # hash_it: Recusrively turn key=value into a hash. Each . in key
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
      hash[name] = value
      return hash
    end

    key,rest = name.split('.',2)
    hash[key] = hash_it(rest,value)
    return hash
  end
end
