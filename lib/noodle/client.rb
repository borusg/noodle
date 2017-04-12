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

# Don't use rest-client because Puppetserver is still using JRuby
# based on Ruby 1.9. And rest-client requires mime-types-data which
# requires Ruby 2.0+. So use net/http instead. Reasons!
require 'net/http'
require 'json' # TODO: Any need for oj/multi_json?

class Noodle
  @server  = 'localhost'
  @port    = '9292'
  @noodles = []
  attr_accessor :params, :facts, :name

  class << self
    attr_accessor :server, :port, :noodles
    include Enumerable

    def each
      Noodle.noodles.map{|n| yield n}
    end
  end

  # Create a bare Noodle object, not connected to the server at all
  def initialize(name)
    @name   = name
    @params = Hash.new
    @facts  = Hash.new
    Noodle.noodles << self
    self
  end

  # Assume Noodle entry exists on the server and update it with
  # contents of this object.  Raises error if node doesn't exist on
  # the server.
  def update
    begin
      r = Net.HTTP.patch "http://#{Noodle.server}/nodes/#{@name}", self.to_json, :content_type => 'application/json'
    rescue => e
      puts e
      puts r
    end
  end

  # Delete node named @name from server
  def delete
    begin
      r = Net.HTTP.delete "http://#{Noodle.server}/nodes/#{@name}"
    rescue => e
      puts e
      puts r
    end
  end

  # Create node on server
  def create
    begin
      r = Net.HTTP.put "http://#{Noodle.server}/nodes/#{@name}", self.to_json, :content_type => 'application/json'
    rescue => e
      puts e
      puts r
    end
  end

  # Find a node and return it in in JSON
  def find
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
    Noodle.server = server if server
    # TODO: Switch to value-only query when magic supports that
    begin
      uri = URI(URI.encode("http://#{@server}:#{@port}/nodes/_/#{host} json"))
      r = JSON.load(Net::HTTP.get(uri))
    rescue => e
      # TODO: Fancier :)
      return "#{e}"
    end
    # TODO: .first is dumb
    r.first['params'][param]
  end

  # Return the result of Noodle magic QUERY as a string.  Optional
  # second argument specifies Noodle server:port to query
  def self.magic(query,server=false)
    Noodle.server = server if server
    begin
      r = Net.HTTP.get(URI.encode("http://#{Noodle.server}/nodes/_/#{query}"))
    rescue
      # TODO: Fancier :)
      return ''
    end
    r.to_str
  end
end
