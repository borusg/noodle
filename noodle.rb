# TODO: JSON all responses

class Node
    attr_accessor :name, :ilk, :status, :facts, :params
    include Enumerable
    @@nodes = []

    def initialize(name,options)
        @name   = name
    # TODO: limit these two to a list of defaults
        @ilk    = options[:ilk]    || 'host'
    @status = options[:status] || 'enabled'
        @facts  = options[:facts]  || Hash.new
    @params = options[:params] || Hash.new
    @@nodes.push self
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

    def self.find(name)
        @@nodes.find{|n| n.name == name}
    end
end

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
end

