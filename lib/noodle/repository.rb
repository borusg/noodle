class Noodle::NodeRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  index_name 'noodle'
  # TODO: ?
  #document_type 'Noodle::Node'.to_sym
  klass Noodle::Node

  mapping do
      indexes :name
      indexes :params, { type: 'object', dynamic: true }
      indexes :facts,  { type: 'object', dynamic: true }
  end

  def serialize(node)
      node.validate!
  end

  def deserialize(document)
    node = super
    node.id = document['_id']
    node
  end

  def self.set_repository(repository)
      @@repository = repository
  end
  def self.repository
      @@repository
  end

  def all
    search({ query: { match_all: { } } })
  end
end
