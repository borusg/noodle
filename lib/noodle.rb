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
#Noodle::Node.gateway.client.transport.logger = Logger.new(STDERR)

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
      index: {mapping: {total_fields: {limit: "20000"}}},
    }
    maybe_force_create_index = true
  end
  configure :production do
    index = 'noodle-nodes'
    index_settings = {
      number_of_shards: 1,
      number_of_replicas: 1,
      index: {mapping: {total_fields: {limit: "20000"}}},
    }
  end

  repository = Noodle::NodeRepository.new(client: client, index_name: index)
  repository.settings index_settings
  # Create the index if it doesn't already exist
  repository.create_index! force: maybe_force_create_index
  repository.client.cluster.health wait_for_status: 'yellow'

  # TODO:
  # Ahem, this is maybe the right way to do it:
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
    b,s = Noodle::Controller.all_names
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
    # TODO: Refuse to stomp an existing node?

    # Delete it if it exists
    Noodle::Controller.delete_one(params[:name])

    # TODO: DRY with patch
    # TODO: Delete this line?
    args = nil
    begin
      args = MultiJson.load(request.body.read)
    rescue MultiJson::ParseError => exception
      puts exception.data
      puts exception.cause
      halt 500
    end

    args['name'] = params[:name]

    node = Noodle::Controller.create_one(args, {now: params.key?('now')})
    if node.class == Noodle::Node
      body node.to_json + "\n"
      status 201
    else
      body node[:errors]
      status 400
    end
  end

  patch '/nodes/:name' do
    maybe_refresh(params)
    halt(422, "#{params[:name]} does not exist.\n") unless
      node = Noodle::Search.new(Noodle::NodeRepository.repository).match_names(params[:name]).go(size: 1)

    begin
      args = MultiJson.load(request.body.read)
    rescue MultiJson::ParseError => exception
      puts exception.data
      puts exception.cause
      halt 500
    end

    node = Noodle::Controller.update(node,args,params)
    if node.class == Noodle::Node
      body node.to_json + "\n"
      status 200
    else
      body node[:errors]
      status 400
    end
  end

  post '/nodes/:name' do
    maybe_refresh(params)
    halt(422, "#{params[:name]} already exists.\n") if
      Noodle::Search.new(Noodle::NodeRepository.repository).match_names(params[:name]).any?
    call! env.merge("REQUEST_METHOD" => 'PUT')
  end

  # TODO: This is flawed since we now allow the same name to exist
  # twice in different ilks.  Either this should require ilk (and any
  # other uniqueness params) or it should return all matches for name
  # and let the caller sort it out
  #
  # TODO: This same problem applies to various searched above too.
  get '/nodes/:name' do
    maybe_refresh(params)
    nodes = Noodle::Search.new(Noodle::NodeRepository.repository).match_names(params[:name]).go
    body nodes.first.to_json + "\n" unless nodes.empty?
    status 200
  end

  delete '/nodes/:name' do
    if Noodle::Controller.delete_one(params[:name])
      body "Deleted #{params[:name]}\n"
      status 200
    else
      halt(422, "#{params[:name]} does not exist.\n")
    end
  end

  options '/nodes/:name' do
    maybe_refresh(params)
    # TODO: Generate this list
    headers 'Allow' => 'DELETE, GET, OPTIONS, PATCH, POST, PUT'
    status 200
  end

  ## TODO: Maybe magic (aka _) and noodlin should be separate from the "real" API
  #
  # "Magic" search
  get '/nodes/_/:search' do
    maybe_refresh(params)
    b,s = Noodle::Controller.magic(params[:search])
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
    # TODO: This is ugly but required because the noodlin command is
    # also part of the hash and leaving "now" in there confuses
    # noodlin parsing
    now = params.key?('now')
    params.delete('now')

    maybe_refresh(params)
    # TODO: This can't be the way to do this!
    changes = String.new(params.keys.first)
    changes << "=#{params.values.first}" unless params.values.first.nil?
    b,s = Noodle::Controller.noodlin(changes, {now: now})
    body   b
    status s
  end

  get '/*' do
    body "Uh, yeah, I dunno what you want with your #{params}\n"
    status 404
  end

  helpers do
    def maybe_refresh(params)
      Noodle::Option.refresh if params.key?('refresh')
    end
  end
end
