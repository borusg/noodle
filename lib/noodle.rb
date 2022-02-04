# Rubocop says:
# frozen_string_literal: true

# TODO: JSON all responses
#
# TODO: Using name as the key is probably stupid
#
# TODO: Assuming we're perfect and there's only one result for a search
#       by name is probably stupid
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/config_file'
require 'elasticsearch/persistence'
require 'multi_json'
require 'oj'
require 'elastic-apm'
require 'ecs_logging/middleware'

# Super debug logging
# Noodle::Node.gateway.client.transport.logger = Logger.new(STDERR)

# Docs RSN :)
class Noodle < Sinatra::Base
  # Default settings:
  configure do
    set elasticsearch_logging: false
    set apm: true
    set ecs_logging: true
    set ecs_log_correlation: true
    set elasticsearch_username: nil
    set elasticsearch_password_file: nil
    set elasticsearch_ca_file: nil
    set elasticsearch_ssl_verify: false
    set elasticsearch_url: 'http://localhost:9200'
  end

  register Sinatra::ConfigFile
  # You can pass multiple pathnames to config_file, but loading more
  # than one would be confusing. And without a full path, it looks for
  # the file in the directory in which this file lives! So:
  etccfg = '/etc/noodle/config.yml'
  config_file File.exist?(etccfg) ? etccfg : '../config.yml'

  # Hi Elastic APM and ECS and log correlation!
  use ElasticAPM::Middleware if settings.apm
  use EcsLogging::Middleware, $stdout if settings.ecs_logging
  require_relative 'monkeys' if ecs_log_correlation

  require_relative 'noodle/model'
  require_relative 'noodle/controller'
  require_relative 'noodle/repository'
  require_relative 'noodle/search'

  configure :development do
    register Sinatra::Reloader
  end

  index = nil
  index_settings = nil

  # Only force create Elasticsearch index when running tests
  maybe_force_create_index = false
  configure :test do
    index = 'noodle-this-is-for-running-noodle-elasticsearch-tests-only-nodes'
    index_settings = {
      number_of_shards: 1,
      number_of_replicas: 0,
      index: { mapping: { total_fields: { limit: '5000' } } }
    }
    maybe_force_create_index = true
  end
  configure :production do
    index = 'noodle-nodes'
    index_settings = {
      number_of_shards: 1,
      number_of_replicas: 1,
      index: { mapping: { total_fields: { limit: '5000' } } }
    }
  end

  password = nil
  password = File.read(settings.elasticsearch_password_file).chomp if
    File.exist?(settings.elasticsearch_password_file) &&
    !settings.elasticsearch_password_file.nil?

  client = Elasticsearch::Client.new(
    url: settings.elasticsearch_url,
    user: settings.elasticsearch_username,
    password: password,
    transport_options: {
      ssl: {
        ca_file: settings.elasticsearch_ca_file,
        verify: settings.elasticsearch_ssl_verify
      }
    },
    log: settings.elasticsearch_logging
  )

  repository = Noodle::NodeRepository.new(client: client, index_name: index)
  repository.settings index_settings
  # Create the index if it doesn't already exist
  repository.create_index! force: maybe_force_create_index
  repository.client.cluster.health wait_for_status: 'yellow'

  # TODO: Ahem, this is maybe the right way to do it:
  set :repository, repository
  # But I'm cheating for now because passing repository into Node::Controller and such is unweildy
  Noodle::NodeRepository.set_repository(repository)
  # Or maybe *this* is the right way: https://github.com/elastic/rails-app-music/blob/migrate-to-repository-pattern-ref-commits/config/initializers/elasticsearch.rb

  Noodle::Option.refresh

  get '/' do
    body "Noodles are delicious\n"
    status 200
  end

  get '/help' do
    maybe_refresh(params)
    body "Noodle helps!\n"
    status 200
  end

  get '/nodes' do
    maybe_refresh(params)

    # TODO: Support JSON output too
    b, s = Noodle::Controller.all_names
    body   b
    status s
  end

  delete '/nodes' do
    # TODO: perhaps this should require confirmation
    Noodle::Controller.delete_everything
    body ''
    status 200
  end

  put '/nodes/:name' do
    maybe_refresh(params)

    node = find_unique_node(params2hash(params))
    if node.instance_of?(String)
      status 400
      body "#{node}\n"
      return
    end

    body, status = update(node, params, request, replace_all: true)

    body body
    status status
  end

  patch '/nodes/:name' do
    maybe_refresh(params)

    args = request2object(request, params)
    node = find_unique_node(args)
    if node.instance_of?(String)
      status 400
      body "#{node}\n"
      return
    end

    args.delete('name')
    node = Noodle::Controller.update(node, args, params)
    if node.instance_of?(Noodle::Node)
      body "#{node.to_json}\n"
      status 200
    else
      body node[:errors]
      status 400
    end
  end

  post '/nodes/:name' do
    maybe_refresh(params)
    body, status = create(request, params)

    body body
    status status
  end

  # TODO: Maybe make it act like /nodes/_/NAME
  get '/nodes/:name' do
    maybe_refresh(params)

    node = find_unique_node(params2hash(params), full: true)
    if node.instance_of?(String)
      status = 400
      body = "#{node}\n"
    else
      status = 200
      body = "#{node.to_json}\n"
    end
    status status
    body body
  end

  delete '/nodes/:name' do
    if Noodle::Controller.delete_one(params[:name])
      body "Deleted #{params[:name]}\n"
      status 200
    else
      halt(424, "#{params[:name]} does not exist.\n")
    end
  end

  options '/nodes/:name' do
    # TODO: Generate this list
    headers 'Allow' => 'DELETE, GET, OPTIONS, PATCH, POST, PUT'
    status 200
  end

  ## TODO: Maybe magic (aka _) and noodlin should be separate from the "real" API
  #
  # "Magic" search
  get '/nodes/_/:search' do
    maybe_refresh(params)
    b, s = Noodle::Controller.magic(params[:search])
    body   b
    status s
  end

  # "Magic" search via query (so I can use 'curl -G --data-urlencode' :)
  get '/nodes/_/' do
    maybe_refresh(params)

    query = ''
    # TODO: This can't be the way to do this!
    query = String.new(params.keys.first) unless params.empty?
    query << "=#{params.values.first}" unless params.values.first.nil?

    if query.empty?
      body ''
      status 200
    else
      b,s = Noodle::Controller.magic(query)
      body   b
      status s
    end
  end

  # TODO: Really this old-style noodlin should go away in favor of a
  # noodlin command which does a PUT
  #
  # Noodlin via query (so I can use 'curl -G --data-urlencode' :)
  get '/nodes/noodlin/' do
    maybe_refresh(params)

    # TODO: This is ugly but required because the noodlin command is
    # also part of the hash and leaving "now" in there confuses
    # noodlin parsing
    now = params.key?('now')
    params.delete('now')

    # TODO: This can't be the way to do this!
    changes = String.new(params.keys.first)
    changes << "=#{params.values.first}" unless params.values.first.nil?
    b, s = Noodle::Controller.noodlin(changes, { now: now })
    if b == false
      b = 'No nodes matched, no action taken.'
      s = 400
    end
    body   b
    status s
  end

  get '/*' do
    body "Uh, yeah, I dunno what you want with your #{params}\n"
    status 404
  end

  helpers do
    def maybe_refresh(params)
      return if params.nil? || !params.key?('refresh')

      Noodle::Option.refresh
      params.delete('refresh')
    end

    def request2object(request, params)
      s = request.body.read
      hash = MultiJson.load(s)
      hash['name'] = params[:name] unless params[:name].nil?
      hash
    rescue MultiJson::ParseError => e
      puts e.data
      puts e.cause
      halt 500
    end

    def create(request, params)
      x = request2object(request, params)
      node = Noodle::Controller.create_one(x, { now: params.key?('now') })
      check4errors(node, '201')
    end

    # Should use keyword args
    def update(node, params, request, options)
      node = Noodle::Controller.update(node, request2object(request, params), params.merge(options))
      check4errors(node, '200')
    end
  end

  def check4errors(node, good_status)
    if node.instance_of?(Noodle::Node)
      body = "#{node.to_json}\n"
      status = good_status
    else
      body = node[:errors]
      status = 400
    end
    [body, status]
  end

  def find_unique_node(hash, full: false)
    # Make sure all unqiueness params are present.
    #
    # NOTE: This requires that the 'ilk' param is present because
    # uniqueness can vary by ilk!
    return('No ilk supplied so cannot check uniqueness.') if hash['params'].nil? || hash['params']['ilk'].nil?

    #
    # Make sure params in hash exactly match uniqueness params:
    uniqueness_params = Noodle::Option.option(hash['params']['ilk'], 'uniqueness_params')
    unless (uniqueness_params - hash['params'].keys).empty?
      return "Not all uniqueness_params were not supplied. Expected uniqueness_params are: #{uniqueness_params.join(',')}"
    end

    # If so,
    #
    # Set up to search by name,
    search = Noodle::Search.new(Noodle::NodeRepository.repository).match_names_exact(hash['name'])
    # and any uniqueness params,
    uniqueness_params.map { |uniqueness_param| search.equals(uniqueness_param, hash['params'][uniqueness_param]) }
    # and include required params too in case we are going to save the node later on.
    required_params = Noodle::Option.option(hash['params']['ilk'], 'required_params')
    # Unless full, limit fetch to uniqueness and required params so we don't drag the whole node back
    search.limit_fetch(uniqueness_params + required_params) unless full
    # Do the search
    nodes = search.go
    if nodes.size != 1
      "Did not find exactly one match. Matches found: #{nodes.size}"
    else
      nodes.first # and only!
    end
  end

  # Turn request into a hash hash for use with find_unique_node
  def params2hash(params)
    # Delete unused param. TODO: Better!
    params.delete('now')
    name = params.delete('name')
    # If the body is present, it represents params. This allows uniqueness params to be specified.
    hash = params.keys.empty? ? {} : JSON.parse(params.keys.first)
    hash['name'] = name
    hash
  end
end
