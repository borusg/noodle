require 'elasticsearch/persistence/model'
require 'hashie'

class Noodle::Option
  # option_cache holds option sets so we don't have to query ES every time.
  # option_cache[name] = options
  @@option_cache = Hash.new

  include Elasticsearch::Persistence::Model

  attribute :name,             String, default: 'defaults'
  attribute :allowed_statuses, Array,  default: %w{enabled disabled future surplus}
  attribute :required_params,  Array,  default: %w{ilk prodlevel project site status}
  attribute :default_ilk,      String, default: 'host'    # ilk returned by queries that don't specify an ilk
  attribute :default_status,   String, default: 'enabled' # status returned by queries that don't specify one

  # TODO: Better explanation and maybe something better than "voodoo"
  #
  # bareword_terms specifies a List of terms (fact or param names)
  # for which Voodoo Expansion works.
  #
  # Voodoo Expansion lets you specify a *value* as a bareword and have it
  # mean the same thing as term=value.  The value must be one of the possible
  # values for one of the terms in the bareword_terms array.
  #
  # For example, let's say you have nodes with various values for
  # the site param:
  #
  # site=moon
  # site=jupiter
  # site=pluto
  # site=saturn
  #
  # AND, 'site' is in the bareword_terms array.
  #
  # Then this noodle query:
  #
  # noodle moon
  #
  # acts as if you had typed this:
  #
  # noodle site=moon
  #
  # Yes it's perilous but I bet it works for me most of the time.  And I'm very lazy.
  attribute :bareword_terms,   Array, default: %w{prodlevel project site}

  # limits specifies per-param limits on the values or type of
  # the param's possible values.  This does not affect facts.
  #
  # For example:
  #
  # limits = {site: %w{moon mars jupiter}}
  #
  # says the site params can only be 'moon', 'mars' or 'jupiter'
  #
  # And this:
  #
  # limits = {role: Array}
  #
  # says that the role param must be an array.
  attribute :limits,
            Hashie::Mash,
            mapping: { type: 'object' },
            default: {
              'project'   => %w{hr financials lms registration warehouse},
              'prodlevel' => %w{dev preprod prod test},
              # TODO: Shirley, these could be classes instead of strings.
              'role'       => 'array',
              'stack'      => 'array',
              'gum'        => 'hash',
              'site'       => %w{jupiter mars moon neptune pluto uranus},
              'ilk'        => %w{host esx ucschassis ucsfi},
              'status'     => %w{disabled enabled future surplus},
            }

  # Get option set named options[:name]
  def self.get(options={})
    name = options['name'] ? options['name'] : 'defaults'
    if @@option_cache[name].nil? or options[:refresh]
      @@option_cache[name] = self.all.results.find{|r| r.name == name}
    end
    @@option_cache[name]
  end
end

