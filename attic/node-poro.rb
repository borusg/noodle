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

    def update(name,options)
        # TODO: Switch to hashie + deep merge
        # For now, assume we're only merging params
        @params.merge!(options[:params])
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

    def delete
        @@nodes.delete(self)
    end

    def self.find(name)
        @@nodes.find{|n| n.name == name}
    end
end

