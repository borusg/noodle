# TODO: JSON all responses
require 'sinatra/base'
require 'sinatra/reloader'
require 'elasticsearch/persistence'
require 'multi_json'
require 'oj'

# Noodle parts
require_relative 'lib/node'

class Noodle < Sinatra::Base
    # TODO: Production :)
    configure :development do
        register Sinatra::Reloader
    end

    get '/help' do
        body "Noodle helps!\n"
        status 200
    end

    post '/nodes/:name' do
        halt(422, "#{params[:name]} already exists.\n") if Node.find(params[:name])

        options = nil
        begin
            options = MultiJson.load(request.body.read,:symbolize_keys => true)
        rescue MultiJson::ParseError => exception
            puts exception.data
            puts exception.cause
            halt 500
        end
        node = Node.new(params[:name],options)
        body node.to_s
        status 201
    end

    get '/nodes/:name' do
        node = Node.find(params[:name])
        body node.to_s unless node.nil?
        status 200
    end

    delete '/nodes/:name' do
        halt(422, "#{params[:name]} does not exist.\n") unless node = Node.find(params[:name])
        node.delete
        body "Deleted #{params[:name]}\n"
        status 200
    end
end

