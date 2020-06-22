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
require 'elasticsearch/persistence'
require 'multi_json'
require 'oj'

# Super debug logging
# Noodle::Node.gateway.client.transport.logger = Logger.new(STDERR)

# Docs RSN :)
class Noodle < Sinatra::Base
  enable :logging

  require_relative 'noodle/model'
  require_relative 'noodle/controller'
  require_relative 'noodle/repository'
  require_relative 'noodle/search'

  client = Elasticsearch::Client.new(url: ENV['ELASTICSEARCH_URL'], log: true)
  configure :development do
    register Sinatra::Reloader
  end

  index = nil
  index_settings = nil

  # Only force create Elasticsearch index when running tests
  maybe_force_create_index = false
  configure :test do
    index = 'this-is-for-running-noodle-elasticsearch-tests-only-nodes'
    index_settings = {
      number_of_shards: 1,
      number_of_replicas: 0,
      index: { mapping: { total_fields: { limit: "20000" } } }
    }
    maybe_force_create_index = true
  end
  configure :production do
    index = 'noodle-nodes'
    index_settings = {
      number_of_shards: 1,
      number_of_replicas: 1,
      index: { mapping: { total_fields: { limit: '20000' } } }
    }
  end

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
    maybe_refresh(params.delete('refresh'))
    body "Noodle helps!\n"
    status 200
  end

  get '/nodes' do
    maybe_refresh(params.delete('refresh'))

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
    maybe_refresh(params.delete('refresh'))

    node = find_unique_node(params2hash(params))
    if node.class == String
      status 400
      body "#{node}\n"
      return
    end

    body, status = update(node, params, request, replace_all: true)

    body body
    status status
  end

  patch '/nodes/:name' do
    maybe_refresh(params.delete('refresh'))

    node = find_unique_node(params2hash(params))
    if node.class == String
      status 400
      body "#{node}\n"
      return
    end

    begin
      args = MultiJson.load(request.body.read)
    rescue MultiJson::ParseError => e
      puts e.data
      puts e.cause
      halt 500
    end

    node = Noodle::Controller.update(node, args, params)
    if node.class == Noodle::Node
      body node.to_json + "\n"
      status 200
    else
      body node[:errors]
      status 400
    end
  end

  post '/nodes/:name' do
    maybe_refresh(params.delete('refresh'))
    body, status = create(request, params)

    body body
    status status
  end

  get '/nodes/:name' do
    maybe_refresh(params.delete('refresh'))

    node = find_unique_node(params2hash(params))
    if node.class == String
      status = 400
      body = "#{node}\n"
    else
      status = 200
      body = node.to_json + "\n"
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
    maybe_refresh(params.delete('refresh'))
    # TODO: Generate this list
    headers 'Allow' => 'DELETE, GET, OPTIONS, PATCH, POST, PUT'
    status 200
  end

  ## TODO: Maybe magic (aka _) and noodlin should be separate from the "real" API
  #
  # "Magic" search
  get '/nodes/_/:search' do
    maybe_refresh(params.delete('refresh'))
    b, s = Noodle::Controller.magic(params[:search])
    body   b
    status s
  end

  # "Magic" search via query (so I can use 'curl -G --data-urlencode' :)
  get '/nodes/_/' do
    maybe_refresh(params.delete('refresh'))
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
    maybe_refresh(params.delete('refresh'))

    # TODO: This is ugly but required because the noodlin command is
    # also part of the hash and leaving "now" in there confuses
    # noodlin parsing
    now = params.key?('now')
    params.delete('now')

    # TODO: This can't be the way to do this!
    changes = String.new(params.keys.first)
    changes << "=#{params.values.first}" unless params.values.first.nil?
    b, s = Noodle::Controller.noodlin(changes, { now: now })
    body   b
    status s
  end

  get '/*' do
    body "Uh, yeah, I dunno what you want with your #{params}\n"
    status 404
  end

  helpers do
    def maybe_refresh(refresh)
      Noodle::Option.refresh if refresh
    end

    def request2object(request, params)
      s = request.body.read
      hash = MultiJson.load(s)
      hash['name'] = params[:name]
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
    if node.class == Noodle::Node
      body = node.to_json + "\n"
      status = good_status
    else
      body = node[:errors]
      status = 400
    end
    [body, status]
  end

  def find_unique_node(hash)
    # Make sure all unqiueness params are present.
    #
    # NOTE: This requires that the 'ilk' param is present because
    # uniqueness can vary by ilk!

    # Return right away if no ilk supplied:
    if hash['params'].nil? || hash['params']['ilk'].nil?
      return('No ilk supplied so cannot check uniqueness.')
    end

    # Otherwise, check uniqueness
    #
    # Get the intersection of uniqueness params and the params
    # specified in the hash, make sure the resulting array has the
    # same number of elements as uniqueness_params has :)
    uniqueness_params = Noodle::Option.option(hash['params']['ilk'], 'uniqueness_params')
    if uniqueness_params.size == [uniqueness_params & hash['params'].keys].size
      # nodes = Noodle::Search.new(Noodle::NodeRepository.repository).match_names(hash['name']).go
      # Search by name,
      search = Noodle::Search.new(Noodle::NodeRepository.repository).match_names(hash['name'])
      # and any uniqueness params,
      uniqueness_params.map { |uniqueness_param| search.equals(uniqueness_param, hash['params'][uniqueness_param]) }
      # and search
      nodes = search.go
      if nodes.size != 1
        "Did not find exactly one match. Matches found: #{nodes.size}"
      else
        nodes.first # and only!
      end
    else
      "Not all uniqueness_params were not supplied. Expected uniqueness_params are: #{uniqueness_params.join(',')}"
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
