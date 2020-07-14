# Rubocop says:
# frozen_string_literal: true

# Docs later
class Noodle
  # Docs later
  class NodeRepository
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
    settings noodle_settings do
      mapping do
      end
    end

    # Add create_time and last_update_time
    def serialize(document)
      node = super
      t = Time.now.utc.iso8601
      node[:facts]['noodle_create_time'] = t if node[:facts]['create_time'].nil?
      node[:facts]['noodle_update_time'] = t
      node
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
end
