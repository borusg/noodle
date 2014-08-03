require 'sinatra/base'
require 'elasticsearch/persistence'
require 'multi_json'
require 'oj'

class Node
    def initialize(name,options)
	@name   = name
	# TODO: limit these two to a list of defaults
        @ilk    = options[:ilk]    || 'host'
	@status = options[:status] || 'enabled'
        @facts  = options[:facts]  || Hash.new
	@params = options[:params] || Hash.new
    end

    def to_s
        s = ''
	s << "Name:   #{@name}\n"
	s << "Ilk:    #{@ilk}\n"
	s << "Status: #{@status}\n"
	s << "Params:\n"
	@params.map{ |name,value| s << "  #{name} = #{value}\n"}
	s << "Facts:\n"
	@facts.map{ |name,value| s << "  #{name} = #{value}\n"}
	s
    end
end

class Noodle < Sinatra::Base
    # TODO: Production :)
    configure :development do
        register Sinatra::Reloader
    end

    get '/help' do
        puts 'Noodle helps!'
    end

    post '/nodes/:name' do
        options = nil
	begin
	    options = MultiJson.load(request.body.read,:symbolize_keys => true)
	rescue MultiJson::ParseError => exception
	    puts exception.data
            puts exception.cause
	    halt 500
	end
        n =  Node.new(params['name'],options)
	n.to_s
    end
end

