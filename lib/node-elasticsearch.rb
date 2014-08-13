require 'elasticsearch/persistence/model'
require 'hashie'

class Node
    include Elasticsearch::Persistence::Model

    attribute :name,   String
    # TODO: limit these two to a list of defaults
    attribute :ilk,    String
    attribute :status, String
    attribute :facts,  Hashie::Mash, mapping: { type: 'object' }
    attribute :params, Hashie::Mash, mapping: { type: 'object' }
end

