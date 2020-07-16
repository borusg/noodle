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

    # TODO: The list of flattened fields should be configurable :)
    structured_facts = %w[
      advanced_config
      augeas
      bound_certs
      cmdline
      cpuinfo
      credential
      crontab
      dhcp_servers
      disks
      dmi
      elasticsearch
      guest_info
      host_switch_spec
      hypervisors
      identity
      listening_procs
      load_averages
      login_defs
      mco_client_settings
      memory
      mountpoints
      networking
      node_deployment_info
      os
      partitions
      prelink
      processors
      puppet_settings
      puppet_sslpaths
      ruby
      simplib__networkmanager
      simplib__sshd_config
      sites
      source
      ssh
      system_uptime
      trusted
    ]
    settings noodle_settings do
      mapping do
        structured_facts.each do |fact|
          indexes :"facts.#{fact}", {
            type: 'flattened'
          }
        end

        # NOTE because I had trouble getting the details right: This
        # works but seems to be the default now so it is not needed:
        #
        # indexes :name, {
        #   type: 'text',
        #   fields: {
        #     keyword: {
        #       type: 'keyword',
        #       ignore_above: 256
        #     }
        #   }
        # }
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
