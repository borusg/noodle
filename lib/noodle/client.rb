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

require 'rest-client'
require 'json' # TODO: Any need for oj/multi_json?

class Noodle
  @server  = 'localhost:9292'
  @noodles = []
  attr_accessor :params, :facts, :name

  class << self
    attr_accessor :server, :noodles
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
      r = RestClient.patch "http://#{Noodle.server}/nodes/#{@name}", self.to_json, :content_type => 'application/json'
    rescue => e
      puts e
      puts r
    end
  end

  # Delete node named @name from server
  def delete
  end

  # Create node on server
  def create
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
end
