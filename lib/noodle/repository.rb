class Noodle::NodeRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  index_name 'noodle'
  klass Noodle::Node

  # https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-persistence#the-dsl-mixin
  #
  # https://rubydoc.info/gems/elasticsearch-model/Elasticsearch/Model/Indexing/ClassMethods
  #
  # https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model#index-configuration
  #
  # https://iridakos.com/tutorials/2017/12/03/elasticsearch-and-rails-tutorial.html

  # Name the analyzer "default" and it's, well, the default!
  # Viddy: https://www.elastic.co/guide/en/elasticsearch/reference/current/analyzer.html
  noodle_settings = {
      analysis: {
          analyzer: {
              default: {
                  tokenizer: 'my_pattern_tokenizer'
              }
          },
          tokenizer: {
              my_pattern_tokenizer: {
                  type: 'pattern'
              }
          }
      }
  }
  noodle_mapping = {
      properties: {
          name: {
              type: 'text',
              fields: {
                  raw: {
                      type: 'keyword'
                  }
              }
          }
      }
  }

  settings noodle_settings do
      mapping noodle_mapping do
        # Specifying these seems like a good idea but somehow doing so means we don't end up with name.keyword?!
        #
        # indexes :name
        # indexes :facts,  { type: 'object'  }
        # indexes :params, { type: 'object'  }
      end
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
