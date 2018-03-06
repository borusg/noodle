TODO: Check all statuses :)

# Noodle client library
#
# Talks to the Noodle API
#
# For example:
#
# Noodle.server = 'localhost:9292'
# n = Noodle.new('plakistan.mcplaksin.org')
# n.params['color']='orange'
# r = n.update
#
# Also, Enumerable so update all Noodles you've created like this:
# Noodle.map{|n| n.update}
#
# TODO: Bulk
# TODO: DRY

# NOTE: Don't use rest-client because Puppetserver is still using
# JRuby based on Ruby 1.9. And rest-client requires mime-types-data
# which requires Ruby 2.0+. So use net/http instead. Reasons!
require 'net/http'
require 'json' # TODO: Any need for oj/multi_json?

class NoodleClient
  @server  = 'localhost'
  @port    = '9292'
  @noodles = []
  attr_accessor :params, :facts, :name

  class << self
    attr_accessor :server, :port, :noodles
    include Enumerable

    def each
      NoodleClient.noodles.map{|n| yield n}
    end
  end

  # Create a bare Noodle object, not connected to the server at all
  def initialize(name)
    @name   = name
    @params = Hash.new
    @facts  = Hash.new
    NoodleClient.noodles << self
    self
  end

  # Assume Noodle entry exists on the server and update it with
  # contents of this object.  Raises error if node doesn't exist on
  # the server.
  def self.updateone(name,options)
    http = Net::HTTP.new(NoodleClient.server,NoodleClient.port)
    request = Net::HTTP::Patch.new("/nodes/#{name}")
    request.body = options.to_json
    request.content_type = 'application/json'
    begin
      r = http.request(request)
    rescue => e
      puts e
      puts r
    end
  end

  # Delete node named @name from server
  def delete
    http = Net::HTTP.new(NoodleClient.server,NoodleClient.port)
    request = Net::HTTP.delete "/nodes/#{@name}"
    begin
      r = http.request(request)
    rescue => e
      puts e
      puts r
    end
  end

  # Create node on server
  def create
    http = Net::HTTP.new(NoodleClient.server,NoodleClient.port)
    request = Net::HTTP::Put.new("/nodes/#{@name}")
    request.body = self.to_json
    request.content_type = 'application/json'
    begin
      r = http.request(request)
    rescue => e
      puts e
      puts r
    end
  end

  # Find a node and return it in in JSON
  def self.findone(node)
    NoodleClient.server = server if server
    # TODO: Switch to value-only query when magic supports that
    begin
      uri = URI(URI.encode("http://#{@server}:#{@port}/nodes/#{node} json"))
      r = JSON.load(Net::HTTP.get(uri))
    rescue => e
      # TODO: Fancier :)
      return "#{e}"
    end
    r
  end

  def self.node_names
    NoodleClient.server = server if server
    # TODO: Switch to value-only query when magic supports that
    begin
      uri = URI(URI.encode("http://#{@server}:#{@port}/nodes"))
      r = JSON.load(Net::HTTP.get(uri))
    rescue => e
      # TODO: Fancier :)
      return "#{e}"
    end
    r
  end

  # Does node *look* valid for creation?  Makes assumptions, doesn't
  # talk to server.
  # TODO: Make this talk to the server and/or add API call to validate
  def valid?
  end

  def to_json
    {params: @params, facts: @facts}.to_json
  end

  # Return the value of one PARAM for HOST.  Optional third argument
  # specifies Noodle server:port to query
  def self.paramvalue(host,param,server=false)
    r = self.find(host)
    # TODO: .first is dumb
    r.first['params'][param]
  end

  # Return the result of Noodle magic QUERY as a string.  Optional
  # second argument specifies Noodle server:port to query
  def self.magic(query)
    http = Net::HTTP.new(NoodleClient.server,NoodleClient.port)
    request = Net::HTTP::Get.new("/nodes/_/#{query}")
    begin
      r = http.request(request)
    rescue
      # TODO: Fancier :)
      return ''
    end
    r.to_str
  end
end
