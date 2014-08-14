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

require_relative 'lib/node-elasticsearch'
# TODO: This seems like a stupid spot for this:
Node.gateway.create_index!

class Noodle < Sinatra::Base
    # TODO: Production :)
    configure :development do
        register Sinatra::Reloader
    end

    get '/help' do
        body "Noodle helps!\n"
        status 200
    end

    put '/nodes/:name' do
        # TODO: Surely order matters, like when creating the new one fails
        nodes.first.delete unless (nodes = Node.search(query: { match: { name: params[:name] } })).size == 0

        # TODO: DRY with patch
        # TODO: Delete this line?
        options = nil
        begin
            options = MultiJson.load(request.body.read,:symbolize_keys => true)
        rescue MultiJson::ParseError => exception
            puts exception.data
            puts exception.cause
            halt 500
        end
        node = Node.create(name:    params[:name],
                           ilk:     options[:ilk],
                           status:  options[:status],
                           facts:   options[:facts],
                           params:  options[:params])
        # TODO: It's not really instantly created!  So by returning right away we're sort of lying.
        body node.to_json + "\n"
        status 201
    end

    patch '/nodes/:name' do
        halt(422, "#{params[:name]} does not exist.\n") if (nodes = Node.search(query: { match: { name: params[:name] } })).size == 0

        begin
            options = MultiJson.load(request.body.read,:symbolize_keys => true)
        rescue MultiJson::ParseError => exception
            puts exception.data
            puts exception.cause
            halt 500
        end
        node = nodes.first

        options.each_pair do |key,value|
            # TODO: Yuck?
            if [:status, :ilk].include?(key)
                # ilk and status are just strings,
                node.send("#{key}=", value)
            else
                # facts and params are Hashie::Mash
                node.send("#{key}=", node.send(key).deep_merge(value))
            end 
            node.save
        end
        body node.to_json
        status 200
    end

    post '/nodes/:name' do
        halt(422, "#{params[:name]} already exists.\n") unless Node.count(query: { match: { name: params[:name] } }) == 0
        call! env.merge("REQUEST_METHOD" => 'PUT')
    end

    get '/nodes/:name' do
        nodes = Node.search(query: { match: { name: params[:name] } })
        body nodes.first.to_json + "\n" unless nodes.empty?
        status 200
    end

    delete '/nodes/:name' do
        halt(422, "#{params[:name]} does not exist.\n") if (nodes = Node.search(query: { match: { name: params[:name] } })).size == 0
        nodes.first.destroy
        body "Deleted #{params[:name]}\n"
        status 200
    end

    options '/nodes/:name' do
        # TODO: Generate this list
        headers 'Allow' => 'DELETE, GET, OPTIONS, PATCH, POST, PUT'
        status 200
    end
end

