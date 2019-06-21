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

  # If OPENSHIFT_RUBY_IP is set, change ES port because can't use
  # default ES port at OpenShift
  Noodle::Node.gateway.client   = Elasticsearch::Client.new host: "#{ENV['OPENSHIFT_RUBY_IP']}:29200" if ENV['OPENSHIFT_RUBY_IP']

  # TODO: Production :)
  force_or_not = {}
  configure :development do
    register Sinatra::Reloader
  end
  configure :test do
    Noodle::Node.gateway.index   = 'this-is-for-running-noodle-elasticsearch-tests-only-nodes'
    Noodle::Node.settings(
      {
        number_of_shards: 1,
        number_of_replicas: 0,
      })
    force_or_not = {force: true}
  end
  configure :production do
    Noodle::Node.settings(
      {
        number_of_shards: 1,
        number_of_replicas: 1,
        index: {mapping: {total_fields: {limit: "20000"}}},
      })
  end

  # Create the indexes if they don't already exist
  Noodle::Node.gateway.create_index! force_or_not
  Noodle::Node.gateway.refresh_index!

  get '/help' do
    body "Noodle helps!\n"
    status 200
  end

  get '/nodes' do
    # TODO: Support JSON output too
    b,s = Noodle::Node.all_names
    body   b
    status s
  end

  delete '/nodes' do
    # TODO: perhaps this should require confirmation
    Noodle::Node.delete_everything
    body ''
    status 200
  end

  put '/nodes/:name' do
    # TODO: Refuse to stomp an existing node?

    # Delete it if it exists
    Noodle::Node.delete_one(params[:name])

    # TODO: DRY with patch
    # TODO: Delete this line?
    options = nil
    begin
      options = MultiJson.load(request.body.read)
    rescue MultiJson::ParseError => exception
      puts exception.data
      puts exception.cause
      halt 500
    end

    args = {
      'name' => params[:name]
    }
    args['facts']  = options['facts'] unless options['facts'].nil?
    args['params'] = options['params'] unless options['params'].nil?

    node = Noodle::Node.create_one(args)
    if node.class == Noodle::Node
      body node.to_json + "\n"
      status 201
    else
      body node[:errors]
      status 400
    end
  end

  patch '/nodes/:name' do
    halt(422, "#{params[:name]} does not exist.\n") unless
      node = Noodle::Search.new(Noodle::Node).match_names(params[:name]).go({:justone => true})

    begin
      options = MultiJson.load(request.body.read)
    rescue MultiJson::ParseError => exception
      puts exception.data
      puts exception.cause
      halt 500
    end

    node.update(options)
    body node.to_json
    status 200
  end

  post '/nodes/:name' do
    halt(422, "#{params[:name]} already exists.\n") if
      Noodle::Search.new(Noodle::Node).match_names(params[:name]).go({:justone => true})
    call! env.merge("REQUEST_METHOD" => 'PUT')
  end

  get '/nodes/:name' do
    nodes = Noodle::Node.search(query: { match: { name: params[:name] } })
    body nodes.first.to_json + "\n" unless nodes.empty?
    status 200
  end

  delete '/nodes/:name' do
    if Noodle::Node.delete_one(params[:name])
      body "Deleted #{params[:name]}\n"
      status 200
    else
      halt(422, "#{params[:name]} does not exist.\n")
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
    b,s = Noodle::Node.magic(params[:search])
    body   b
    status s
  end

  # "Magic" search via query (so I can use 'curl -G --data-urlencode' :)
  get '/nodes/_/' do
    # TODO: This can't be the way to do this!
    query = String.new(params.keys.first)
    query << "=#{params.values.first}" unless params.values.first.nil?
    b,s = Noodle::Node.magic(query)
    body   b
    status s
  end

  # Noodlin via query (so I can use 'curl -G --data-urlencode' :)
  get '/nodes/noodlin/' do
    # TODO: This can't be the way to do this!
    changes = String.new(params.keys.first)
    changes << "=#{params.values.first}" unless params.values.first.nil?
    b,s = Noodle::Node.noodlin(changes)
    body   b
    status s
  end
end
